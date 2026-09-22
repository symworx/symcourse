// Copyright (c) 2026, PalEm Dynamics LLC
// Licensed under the Apache License, Version 2.0.

use std::{
    collections::BTreeMap,
    fs,
    path::Path,
};

use serde::Deserialize;

use crate::error::{
    Error,
    Result,
};

#[derive(Debug, Deserialize)]
struct CatalogFile {
    kit: Kit,
    defaults: Defaults,
    #[serde(default)]
    presets: BTreeMap<String, Preset>,
    #[serde(default)]
    shapes: BTreeMap<String, Layer>,
    #[serde(default)]
    runtimes: BTreeMap<String, Layer>,
    #[serde(default)]
    orgs: BTreeMap<String, Layer>,
    #[serde(default)]
    extras: BTreeMap<String, Layer>,
}

#[derive(Debug, Deserialize)]
struct Kit {
    name: String,
}

#[derive(Debug, Deserialize)]
struct Defaults {
    shape: String,
    runtime: String,
    org: String,
    lms: String,
}

#[derive(Debug, Deserialize, Default)]
struct Preset {
    #[serde(default)]
    description: String,
    #[serde(default)]
    shape: String,
    #[serde(default)]
    runtime: String,
    #[serde(default)]
    org: String,
}

#[derive(Debug, Deserialize, Default)]
struct Layer {
    #[serde(default)]
    description: String,
    #[serde(default)]
    dirs: Vec<String>,
    #[serde(default)]
    keep: Vec<String>,
    #[serde(default)]
    files: Vec<FileSpec>,
    #[serde(default)]
    copies: Vec<CopySpec>,
    #[serde(default)]
    gitignore_append: Option<String>,
    #[serde(default)]
    vars: BTreeMap<String, Option<String>>,
}

#[derive(Debug, Deserialize)]
struct FileSpec {
    src: String,
    dest: String,
}

#[derive(Debug, Deserialize)]
struct CopySpec {
    src: String,
    dest: String,
    #[serde(default)]
    mode: String,
}

#[derive(Debug, Clone)]
pub struct Item {
    pub kind: ItemKind,
    pub src: String,
    pub dest: String,
    pub mode: String,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ItemKind {
    File,
    Copy,
    Append,
    Keep,
}

impl Item {
    fn key(&self) -> String {
        match self.kind {
            ItemKind::Append => format!("__append__:{}", self.src),
            _ => self.dest.clone(),
        }
    }
}

#[derive(Debug)]
pub struct Resolve<'a> {
    pub shape: &'a str,
    pub runtime: &'a str,
    pub org: &'a str,
    pub pages: bool,
    pub lms: Option<&'a str>,
    pub github_org: Option<&'a str>,
    pub course_name: &'a str,
}

#[derive(Debug)]
pub struct Resolved {
    pub shape: String,
    pub runtime: String,
    pub org: String,
    pub dirs: Vec<String>,
    pub items: Vec<Item>,
    pub vars: BTreeMap<String, String>,
}

#[derive(Debug)]
pub struct Catalog {
    file: CatalogFile,
}

impl Catalog {
    pub fn load(path: &Path) -> Result<Self> {
        let text = fs::read_to_string(path).map_err(|err| {
            if err.kind() == std::io::ErrorKind::NotFound {
                Error::CatalogMissing(path.to_path_buf())
            } else {
                Error::Io(err)
            }
        })?;
        Self::parse(&text)
    }

    pub fn parse(text: &str) -> Result<Self> {
        let file: CatalogFile = serde_yaml::from_str(text)?;
        Ok(Self { file })
    }

    pub fn format_list(&self) -> String {
        let c = &self.file;
        let mut lines = vec![
            format!("{} catalog", c.kit.name),
            String::new(),
            "Defaults:".to_string(),
            format!("  shape    {}", c.defaults.shape),
            format!("  runtime  {}", c.defaults.runtime),
            format!("  org      {}", c.defaults.org),
            String::new(),
            "Shapes:".to_string(),
        ];
        for (name, spec) in &c.shapes {
            lines.push(format!("  {name:<12} {}", spec.description));
        }
        lines.push(String::new());
        lines.push("Runtimes:".to_string());
        for (name, spec) in &c.runtimes {
            lines.push(format!("  {name:<12} {}", spec.description));
        }
        lines.push(String::new());
        lines.push("Orgs:".to_string());
        for (name, spec) in &c.orgs {
            lines.push(format!("  {name:<12} {}", spec.description));
        }
        lines.push(String::new());
        lines.push("Presets:".to_string());
        for (name, spec) in &c.presets {
            lines.push(format!(
                "  {name:<12} shape={} runtime={} org={}  {}",
                spec.shape, spec.runtime, spec.org, spec.description
            ));
        }
        lines.push(String::new());
        lines.join("\n")
    }

    /// Empty strings count as unset, matching the shell scaffolder.
    pub fn apply_preset(
        &self,
        preset: Option<&str>,
        mut shape: Option<&str>,
        mut runtime: Option<&str>,
        mut org: Option<&str>,
    ) -> Result<(String, String, String)> {
        let preset = blank_to_none(preset);
        shape = blank_to_none(shape);
        runtime = blank_to_none(runtime);
        org = blank_to_none(org);

        let mut shape = shape.unwrap_or("").to_string();
        let mut runtime = runtime.unwrap_or("").to_string();
        let mut org = org.unwrap_or("").to_string();

        if let Some(preset) = preset {
            let spec = self.file.presets.get(preset).ok_or_else(|| Error::UnknownId {
                kind: "preset",
                ident: preset.to_string(),
                known: known_keys(&self.file.presets),
            })?;
            if shape.is_empty() {
                shape = spec.shape.clone();
            }
            if runtime.is_empty() {
                runtime = spec.runtime.clone();
            }
            if org.is_empty() {
                org = spec.org.clone();
            }
        }

        if shape.is_empty() {
            shape = self.file.defaults.shape.clone();
        }
        if runtime.is_empty() {
            runtime = self.file.defaults.runtime.clone();
        }
        if org.is_empty() {
            org = self.file.defaults.org.clone();
        }
        Ok((shape, runtime, org))
    }

    pub fn resolve(&self, req: Resolve<'_>) -> Result<Resolved> {
        let shape_spec = require(&self.file.shapes, "shape", req.shape)?;
        let runtime_spec = require(&self.file.runtimes, "runtime", req.runtime)?;
        let org_spec = require(&self.file.orgs, "org", req.org)?;

        let mut layers = vec![shape_spec, runtime_spec, org_spec];
        if req.pages {
            layers.push(require(&self.file.extras, "extra", "pages")?);
        }

        let (dirs, items) = merge_files(&layers);

        let mut vars: BTreeMap<String, String> = BTreeMap::new();
        let default_lms = &self.file.defaults.lms;
        let org_vars = &org_spec.vars;
        let org_lms = var_str(org_vars, "LMS");
        let lms = blank_to_none(req.lms).unwrap_or("");
        vars.insert(
            "LMS".to_string(),
            if lms.is_empty() {
                if org_lms.is_empty() {
                    default_lms.clone()
                } else {
                    org_lms
                }
            } else {
                lms.to_string()
            },
        );
        let org_github = var_str(org_vars, "GITHUB_ORG");
        let github_org = blank_to_none(req.github_org).unwrap_or("");
        let ghorg = if github_org.is_empty() {
            org_github
        } else {
            github_org.to_string()
        };
        vars.insert("GITHUB_ORG".to_string(), ghorg.clone());
        for (key, value) in org_vars {
            if key == "LMS" || key == "GITHUB_ORG" {
                continue;
            }
            vars.insert(key.clone(), value.clone().unwrap_or_default());
        }

        if !ghorg.is_empty() {
            vars.insert(
                "CLONE_SNIPPET".to_string(),
                format!("git clone https://github.com/{ghorg}/{}.git", req.course_name),
            );
            vars.insert(
                "REPO_WEB".to_string(),
                format!("https://github.com/{ghorg}/{}", req.course_name),
            );
            let host = vars
                .get("GITHUB_PAGES_HOST")
                .filter(|h| !h.is_empty())
                .cloned()
                .unwrap_or_else(|| format!("{ghorg}.github.io"));
            vars.insert("PAGES_URL".to_string(), format!("https://{host}/{}/", req.course_name));
            vars.insert(
                "GITHUB_REPOSITORY_DEFAULT".to_string(),
                format!("{ghorg}/{}", req.course_name),
            );
        } else {
            vars.insert("CLONE_SNIPPET".to_string(), "git clone <repository-url>".to_string());
            vars.insert("REPO_WEB".to_string(), "the course repository".to_string());
            vars.insert("PAGES_URL".to_string(), "(GitHub Pages URL once enabled)".to_string());
            vars.insert(
                "GITHUB_REPOSITORY_DEFAULT".to_string(),
                format!("YOUR_ORG/{}", req.course_name),
            );
            vars.entry("GITHUB_PAGES_HOST".to_string()).or_default();
        }
        vars.entry("FACULTY_DOCS".to_string()).or_default();
        vars.entry("GITHUB_PAGES_HOST".to_string()).or_default();

        Ok(Resolved {
            shape: req.shape.to_string(),
            runtime: req.runtime.to_string(),
            org: req.org.to_string(),
            dirs,
            items,
            vars,
        })
    }
}

fn blank_to_none(value: Option<&str>) -> Option<&str> {
    value.filter(|s| !s.is_empty())
}

fn var_str(vars: &BTreeMap<String, Option<String>>, key: &str) -> String {
    vars.get(key).and_then(|v| v.clone()).unwrap_or_default()
}

fn known_keys<T>(map: &BTreeMap<String, T>) -> String {
    if map.is_empty() {
        "(none)".to_string()
    } else {
        map.keys().cloned().collect::<Vec<_>>().join(", ")
    }
}

fn require<'a>(section: &'a BTreeMap<String, Layer>, kind: &'static str, ident: &str) -> Result<&'a Layer> {
    section.get(ident).ok_or_else(|| Error::UnknownId {
        kind,
        ident: ident.to_string(),
        known: known_keys(section),
    })
}

fn merge_files(layers: &[&Layer]) -> (Vec<String>, Vec<Item>) {
    let mut dirs = Vec::new();
    let mut items: Vec<Item> = Vec::new();
    for layer in layers {
        for dir in &layer.dirs {
            if !dirs.iter().any(|d| d == dir) {
                dirs.push(dir.clone());
            }
        }
        for file in &layer.files {
            upsert(
                &mut items,
                Item {
                    kind: ItemKind::File,
                    src: file.src.clone(),
                    dest: file.dest.clone(),
                    mode: String::new(),
                },
            );
        }
        for copy in &layer.copies {
            upsert(
                &mut items,
                Item {
                    kind: ItemKind::Copy,
                    src: copy.src.clone(),
                    dest: copy.dest.clone(),
                    mode: copy.mode.clone(),
                },
            );
        }
        if let Some(frag) = &layer.gitignore_append {
            upsert(
                &mut items,
                Item {
                    kind: ItemKind::Append,
                    src: frag.clone(),
                    dest: ".gitignore".to_string(),
                    mode: String::new(),
                },
            );
        }
        for keep in &layer.keep {
            upsert(
                &mut items,
                Item {
                    kind: ItemKind::Keep,
                    src: String::new(),
                    dest: keep.clone(),
                    mode: String::new(),
                },
            );
        }
    }
    (dirs, items)
}

fn upsert(items: &mut Vec<Item>, item: Item) {
    let key = item.key();
    if let Some(existing) = items.iter_mut().find(|i| i.key() == key) {
        *existing = item;
    } else {
        items.push(item);
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn repo_catalog() -> Catalog {
        Catalog::load(&Path::new(env!("CARGO_MANIFEST_DIR")).join("catalog.yaml")).unwrap()
    }

    #[test]
    fn list_names_defaults_and_msia() {
        let text = repo_catalog().format_list();
        assert!(text.contains("shape    course"));
        assert!(text.contains("msia"));
        assert!(text.contains("preset") || text.contains("Presets:"));
    }

    #[test]
    fn preset_msia_fills_empty_flags_and_org_vars() {
        let cat = repo_catalog();
        let (shape, runtime, org) = cat.apply_preset(Some("msia"), None, None, None).unwrap();
        assert_eq!(shape, "course");
        assert_eq!(runtime, "uv");
        assert_eq!(org, "msia");
        let resolved = cat
            .resolve(Resolve {
                shape: &shape,
                runtime: &runtime,
                org: &org,
                pages: false,
                lms: None,
                github_org: None,
                course_name: "ian-6xx",
            })
            .unwrap();
        assert_eq!(resolved.vars["LMS"], "Canvas");
        assert_eq!(resolved.vars["GITHUB_ORG"], "uncg-msia");
        assert!(resolved.vars["CLONE_SNIPPET"].contains("uncg-msia/ian-6xx"));
        assert!(resolved.items.iter().any(|i| i.dest == "Containerfile"));
        assert!(resolved.items.iter().any(|i| i.dest == ".github/workflows/release.yml"));
    }

    #[test]
    fn explicit_flag_overrides_preset() {
        let cat = repo_catalog();
        let (shape, runtime, org) = cat.apply_preset(Some("msia"), None, Some("none"), None).unwrap();
        assert_eq!(runtime, "none");
        assert_eq!(shape, "course");
        assert_eq!(org, "msia");
    }

    #[test]
    fn github_org_override_and_pages() {
        let cat = repo_catalog();
        let resolved = cat
            .resolve(Resolve {
                shape: "course",
                runtime: "none",
                org: "none",
                pages: true,
                lms: Some("Moodle"),
                github_org: Some("example-edu"),
                course_name: "bio-lms",
            })
            .unwrap();
        assert_eq!(resolved.vars["LMS"], "Moodle");
        assert_eq!(
            resolved.vars["CLONE_SNIPPET"],
            "git clone https://github.com/example-edu/bio-lms.git"
        );
        assert_eq!(resolved.vars["PAGES_URL"], "https://example-edu.github.io/bio-lms/");
        assert!(resolved.items.iter().any(|i| i.dest == "site/index.html"));
    }

    #[test]
    fn unknown_shape_names_known_ids() {
        let err = repo_catalog()
            .resolve(Resolve {
                shape: "nope",
                runtime: "none",
                org: "none",
                pages: false,
                lms: None,
                github_org: None,
                course_name: "x",
            })
            .unwrap_err();
        let msg = err.to_string();
        assert!(msg.contains("unknown --shape 'nope'"), "{msg}");
        assert!(msg.contains("course"), "{msg}");
    }
}
