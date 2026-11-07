// Copyright (c) 2026, Nathaniel T. Berry
// Licensed under the Apache License, Version 2.0.

use std::{
    collections::BTreeMap,
    fs,
    io::Write,
    path::{
        Component,
        Path,
        PathBuf,
    },
    process::{
        Command,
        Stdio,
    },
};

use crate::{
    assets::is_root,
    catalog::{
        Catalog,
        ItemKind,
        Resolve,
    },
    department,
    error::{
        Error,
        Result,
    },
};

const MIG_BEGIN: &str = "# BEGIN symcourse migration-docs";
const MIG_END: &str = "# END symcourse migration-docs";

pub struct NewCourse {
    pub course_name: String,
    pub outdir: PathBuf,
    pub course_number: String,
    pub course_title: String,
    pub shape: Option<String>,
    pub runtime: Option<String>,
    pub org: Option<String>,
    pub preset: Option<String>,
    pub lms: Option<String>,
    pub github_org: Option<String>,
    pub with_pages: bool,
    pub with_agents: bool,
    pub adapters: Option<String>,
    pub migration_docs: bool,
    pub department: Option<PathBuf>,
}

pub fn scaffold(root: &Path, req: &NewCourse) -> Result<()> {
    if !valid_course_name(&req.course_name) {
        return Err(Error::InvalidCourseName(req.course_name.clone()));
    }
    if req.course_number.is_empty() {
        return Err(Error::MissingCourseNumber);
    }
    if req.course_title.is_empty() {
        return Err(Error::MissingCourseTitle);
    }

    let catalog_path = root.join("catalog.yaml");
    let template_dir = root.join("templates");
    if !template_dir.is_dir() {
        return Err(Error::TemplatesMissing(template_dir));
    }
    let catalog = Catalog::load(&catalog_path)?;
    let department = req.department.as_deref().map(department::load).transpose()?;
    if let Some(dept) = &department {
        dept.check_course(&req.course_name, &req.course_number)?;
    }
    let (shape, mut runtime, mut org) = catalog.apply_preset(
        req.preset.as_deref(),
        req.shape.as_deref(),
        req.runtime.as_deref(),
        req.org.as_deref(),
    )?;
    if let Some(dept) = &department {
        if !flag_set(&req.org) && req.preset.is_none() {
            if let Some(value) = &dept.org {
                org = value.clone();
            }
        }
        if !flag_set(&req.runtime) && req.preset.is_none() {
            if let Some(value) = &dept.runtime {
                runtime = value.clone();
            }
        }
    }
    let resolved = catalog.resolve(Resolve {
        shape: &shape,
        runtime: &runtime,
        org: &org,
        pages: req.with_pages,
        lms: req.lms.as_deref(),
        github_org: req.github_org.as_deref(),
        course_name: &req.course_name,
    })?;

    let mut vars = BTreeMap::new();
    vars.insert("COURSE_NAME".to_string(), req.course_name.clone());
    vars.insert("COURSE_TITLE".to_string(), req.course_title.clone());
    vars.insert("COURSE_CODE".to_string(), req.course_number.clone());
    vars.insert("COURSE_PY".to_string(), req.course_name.replace('-', "_"));
    vars.insert("VENV_NAME".to_string(), format!("{}-venv", req.course_name));
    for (key, value) in &resolved.vars {
        vars.insert(key.clone(), value.clone());
    }
    if let Some(dept) = &department {
        department::overlay(
            &mut vars,
            dept,
            &req.course_name,
            flag_set(&req.lms),
            flag_set(&req.github_org),
        );
    }

    log(&format!("Scaffolding {} — {}", req.course_number, req.course_title));
    log(&format!("Destination: {}", req.outdir.display()));
    log(&format!(
        "Catalog: shape={} runtime={} org={}",
        resolved.shape, resolved.runtime, resolved.org
    ));
    if req.with_pages {
        log("Pages hub: yes");
    } else {
        log("Pages hub: no (pass --with-pages to include)");
    }
    if req.with_agents {
        log("Agents: nested symkit install (pass --no-agents to skip)");
    } else {
        log("Agents: no");
    }
    if let (Some(dept), Some(path)) = (&department, req.department.as_deref()) {
        log(&format!(
            "Department: {} ({}) from {}",
            dept.slug,
            dept.course_numbers.join(", "),
            path.display()
        ));
    }

    let mut created = 0u32;
    let mut skipped = 0u32;

    for dir in &resolved.dirs {
        fs::create_dir_all(req.outdir.join(dir))?;
    }

    for item in &resolved.items {
        match item.kind {
            ItemKind::File => install_file(
                &template_dir,
                &req.outdir,
                &item.src,
                &item.dest,
                &vars,
                &mut created,
                &mut skipped,
            )?,
            ItemKind::Copy => install_copy(
                &template_dir,
                &req.outdir,
                &item.src,
                &item.dest,
                &item.mode,
                &mut created,
                &mut skipped,
            )?,
            ItemKind::Append => append_fragment(
                &template_dir,
                &req.outdir,
                &item.src,
                &item.dest,
                &mut created,
                &mut skipped,
            )?,
            ItemKind::Keep => keep_file(&req.outdir, &item.dest, &mut created, &mut skipped)?,
        }
    }

    if req.migration_docs {
        write_migration(&template_dir, &req.outdir, &mut created, &mut skipped)?;
    } else {
        log("migration-docs: skipped (--no-migration-docs)");
    }

    let pages_script = req.outdir.join("scripts/build-pages.sh");
    if pages_script.is_file() {
        make_exec(&pages_script)?;
    }

    if resolved.runtime == "uv" {
        maybe_uv_lock(&req.outdir, &mut created, &mut skipped)?;
    }

    if !req.outdir.join(".git").is_dir() {
        let status = Command::new("git")
            .arg("-C")
            .arg(&req.outdir)
            .arg("init")
            .arg("-b")
            .arg("worx")
            .stdout(Stdio::null())
            .status()?;
        if !status.success() {
            return Err(Error::Msg(format!("git init failed ({status})")));
        }
        log("git init (default branch worx)");
    }

    install_agents(req)?;

    log(&format!("Done. created={created} skipped={skipped}"));
    log("Next: edit README, add a handbook when the spine is stable.");
    log("Do not commit .agents/ / .grok/ / .claude/ / .codex/.");
    log("Published SLOs: docs/slos.md (from nested symkit --docs slos).");
    Ok(())
}

pub fn create_department(root: &Path, dest: &Path) -> Result<PathBuf> {
    let src = root.join("templates/department.yml");
    if !src.is_file() {
        return Err(Error::MissingTemplate(src.display().to_string()));
    }
    let dest = department_file(dest);
    if let Some(parent) = dest.parent() {
        if !parent.as_os_str().is_empty() && parent.exists() && is_root(parent) {
            let shown = fs::canonicalize(parent).unwrap_or_else(|_| parent.to_path_buf());
            return Err(Error::KitRoot(shown));
        }
        if !parent.as_os_str().is_empty() {
            fs::create_dir_all(parent)?;
        }
    }
    refuse_stock_department(root, &dest)?;
    if dest.exists() {
        log(&format!("skip (exists): {}", dest.display()));
        log("department.yml was not replaced. Edit it with `symcourse edit department`, then pass --department.");
        return Ok(dest);
    }
    fs::copy(&src, &dest)?;
    log(&format!("created: {}", dest.display()));
    log("Edit slug, name, org, runtime, and course_numbers.");
    log(&format!(
        "Then: symcourse new <name> . --course-number \"...\" --course-title \"...\" --department {}",
        dest.display()
    ));
    Ok(dest)
}

pub fn edit_department(root: &Path, dest: &Path) -> Result<()> {
    let editor = std::env::var("VISUAL")
        .ok()
        .filter(|value| !value.is_empty())
        .or_else(|| std::env::var("EDITOR").ok().filter(|value| !value.is_empty()));
    edit_department_with(root, dest, editor.as_deref())
}

fn edit_department_with(root: &Path, dest: &Path, editor: Option<&str>) -> Result<()> {
    let dest = department_file(dest);
    if !dest.is_file() {
        return Err(Error::DepartmentMissing(dest));
    }
    refuse_stock_department(root, &dest)?;
    let Some(editor) = editor.filter(|value| !value.is_empty()) else {
        log(&format!(
            "No VISUAL or EDITOR. Edit {} then pass --department.",
            dest.display()
        ));
        return Ok(());
    };
    let status = Command::new(editor).arg(&dest).status()?;
    if !status.success() {
        return Err(Error::Msg(format!("editor failed ({status})")));
    }
    log(&format!("edited: {}", dest.display()));
    Ok(())
}

pub fn delete_department(root: &Path, dest: &Path) -> Result<()> {
    let dest = department_file(dest);
    if !dest.is_file() {
        return Err(Error::DepartmentMissing(dest));
    }
    refuse_stock_department(root, &dest)?;
    fs::remove_file(&dest)?;
    log(&format!("deleted: {}", dest.display()));
    Ok(())
}

fn department_file(dest: &Path) -> PathBuf {
    if dest.is_dir() {
        dest.join("department.yml")
    } else {
        dest.to_path_buf()
    }
}

fn refuse_stock_department(root: &Path, dest: &Path) -> Result<()> {
    let stock = root.join("templates/department.yml");
    let dest_canon = fs::canonicalize(dest).unwrap_or_else(|_| dest.to_path_buf());
    let stock_canon = fs::canonicalize(&stock).unwrap_or(stock);
    if dest_canon == stock_canon {
        return Err(Error::Msg(
            "refusing to change the stock department template; `symcourse create department` writes a copy".into(),
        ));
    }
    Ok(())
}

fn flag_set(value: &Option<String>) -> bool {
    value.as_deref().is_some_and(|text| !text.is_empty())
}

fn valid_course_name(name: &str) -> bool {
    !name.is_empty()
        && name
            .chars()
            .all(|c| c.is_ascii_alphanumeric() || matches!(c, '.' | '_' | '-'))
}

fn log(msg: &str) {
    println!(">>> {msg}");
}

fn warn(msg: &str) {
    eprintln!("warning: {msg}");
}

fn render(text: &str, vars: &BTreeMap<String, String>) -> String {
    let mut keys: Vec<&String> = vars.keys().collect();
    keys.sort_by_key(|key| std::cmp::Reverse(key.len()));
    let mut text = text.to_string();
    for key in keys {
        let needle = format!("__{key}__");
        if let Some(value) = vars.get(key) {
            text = text.replace(&needle, value);
        }
    }
    text
}

fn install_file(
    template_dir: &Path,
    outdir: &Path,
    src_rel: &str,
    dest_rel: &str,
    vars: &BTreeMap<String, String>,
    created: &mut u32,
    skipped: &mut u32,
) -> Result<()> {
    let src = template_dir.join(src_rel);
    let dest = outdir.join(dest_rel);
    if !src.is_file() {
        return Err(Error::MissingTemplate(src_rel.to_string()));
    }
    if dest.exists() {
        log(&format!("skip (exists): {dest_rel}"));
        *skipped += 1;
        return Ok(());
    }
    let text = fs::read_to_string(&src)?;
    if let Some(parent) = dest.parent() {
        fs::create_dir_all(parent)?;
    }
    fs::write(&dest, render(&text, vars))?;
    log(&format!("created: {dest_rel}"));
    *created += 1;
    Ok(())
}

fn install_copy(
    template_dir: &Path,
    outdir: &Path,
    src_rel: &str,
    dest_rel: &str,
    mode: &str,
    created: &mut u32,
    skipped: &mut u32,
) -> Result<()> {
    let src = template_dir.join(src_rel);
    let dest = outdir.join(dest_rel);
    if !src.is_file() {
        return Err(Error::MissingTemplate(src_rel.to_string()));
    }
    if dest.exists() {
        log(&format!("skip (exists): {dest_rel}"));
        *skipped += 1;
        return Ok(());
    }
    if let Some(parent) = dest.parent() {
        fs::create_dir_all(parent)?;
    }
    fs::copy(&src, &dest)?;
    if mode == "exec" {
        make_exec(&dest)?;
    }
    log(&format!("created: {dest_rel}"));
    *created += 1;
    Ok(())
}

fn append_fragment(
    template_dir: &Path,
    outdir: &Path,
    src_rel: &str,
    dest_rel: &str,
    created: &mut u32,
    skipped: &mut u32,
) -> Result<()> {
    let src = template_dir.join(src_rel);
    let dest = outdir.join(dest_rel);
    if !src.is_file() {
        return Err(Error::MissingTemplate(src_rel.to_string()));
    }
    if let Some(parent) = dest.parent() {
        fs::create_dir_all(parent)?;
    }
    if dest.is_file() {
        let existing = fs::read(&dest)?;
        if existing
            .windows(b"BEGIN symcourse runtime uv".len())
            .any(|w| w == b"BEGIN symcourse runtime uv")
        {
            log(&format!("skip (exists): {dest_rel} runtime fragment"));
            *skipped += 1;
            return Ok(());
        }
    }
    let mut file = fs::OpenOptions::new().create(true).append(true).open(&dest)?;
    file.write_all(b"\n")?;
    file.write_all(&fs::read(src)?)?;
    log(&format!("appended: {dest_rel} ← {src_rel}"));
    *created += 1;
    Ok(())
}

fn write_migration(template_dir: &Path, outdir: &Path, created: &mut u32, skipped: &mut u32) -> Result<()> {
    log("migration-docs: local only; back the directory up elsewhere");
    install_copy(
        template_dir,
        outdir,
        "shapes/course/migration-docs/README.md.tpl",
        "migration-docs/README.md",
        "",
        created,
        skipped,
    )?;
    install_copy(
        template_dir,
        outdir,
        "shapes/course/migration-docs/gitkeep.tpl",
        "migration-docs/.gitkeep",
        "",
        created,
        skipped,
    )?;
    sync_migration_gitignore(outdir, created, skipped)
}

fn sync_migration_gitignore(outdir: &Path, created: &mut u32, skipped: &mut u32) -> Result<()> {
    let gitkeep = fs::read_to_string(outdir.join("migration-docs/.gitkeep"))?;
    let extras = parse_gitkeep(&gitkeep)?;
    let block = migration_block(&extras);
    let path = outdir.join(".gitignore");
    let existing = if path.is_file() {
        fs::read_to_string(&path)?
    } else {
        String::new()
    };
    let next = upsert_marked_block(&existing, MIG_BEGIN, MIG_END, &block)?;
    if next == existing {
        log("skip (exists): .gitignore migration-docs");
        *skipped += 1;
        return Ok(());
    }
    fs::write(&path, next)?;
    log("updated: .gitignore migration-docs");
    *created += 1;
    Ok(())
}

/// Paths listed in `.gitkeep`, relative to `migration-docs/`.
fn parse_gitkeep(text: &str) -> Result<Vec<String>> {
    let mut paths = Vec::new();
    for raw in text.lines() {
        let line = raw.trim().trim_start_matches('!').trim();
        if line.is_empty() || line.starts_with('#') {
            continue;
        }
        let line = line.strip_prefix("migration-docs/").unwrap_or(line);
        let rel = check_migration_rel(line)?;
        if rel == "README.md" || rel == ".gitkeep" || paths.iter().any(|p| p == &rel) {
            continue;
        }
        paths.push(rel);
    }
    Ok(paths)
}

fn check_migration_rel(line: &str) -> Result<String> {
    if line.contains('\\') || line.starts_with('/') {
        return Err(Error::Msg(format!("migration-docs/.gitkeep: unsafe path '{line}'")));
    }
    let mut parts = Vec::new();
    for part in Path::new(line).components() {
        match part {
            Component::Normal(name) => {
                let name = name.to_string_lossy();
                if name.contains('*') || name.contains('?') || name.contains('[') {
                    return Err(Error::Msg(format!("migration-docs/.gitkeep: unsafe path '{line}'")));
                }
                parts.push(name.to_string());
            }
            _ => return Err(Error::Msg(format!("migration-docs/.gitkeep: unsafe path '{line}'"))),
        }
    }
    if parts.is_empty() {
        return Err(Error::Msg(format!("migration-docs/.gitkeep: unsafe path '{line}'")));
    }
    Ok(parts.join("/"))
}

fn migration_block(extras: &[String]) -> String {
    let mut lines = vec![
        MIG_BEGIN.to_string(),
        "# Local only. Back this directory up elsewhere.".to_string(),
        "# Track another file by listing it in migration-docs/.gitkeep, then re-run new.".to_string(),
        "migration-docs/**".to_string(),
        "!migration-docs/README.md".to_string(),
        "!migration-docs/.gitkeep".to_string(),
    ];
    let mut seen = Vec::new();
    for rel in extras {
        let path = Path::new(rel);
        let ancestors: Vec<_> = path
            .parent()
            .into_iter()
            .flat_map(|parent| parent.ancestors())
            .collect();
        for dir in ancestors.into_iter().rev() {
            if dir.as_os_str().is_empty() {
                continue;
            }
            let pattern = format!("!migration-docs/{}/", dir.display());
            if !seen.contains(&pattern) {
                seen.push(pattern.clone());
                lines.push(pattern);
            }
        }
        lines.push(format!("!migration-docs/{rel}"));
    }
    lines.push(MIG_END.to_string());
    let mut block = lines.join("\n");
    block.push('\n');
    block
}

fn upsert_marked_block(text: &str, begin: &str, end: &str, block: &str) -> Result<String> {
    let Some(start) = text.find(begin) else {
        let mut out = text.to_string();
        if !out.is_empty() && !out.ends_with('\n') {
            out.push('\n');
        }
        if !out.is_empty() && !out.ends_with("\n\n") {
            out.push('\n');
        }
        out.push_str(block);
        if !block.ends_with('\n') {
            out.push('\n');
        }
        return Ok(out);
    };
    let Some(rel_end) = text[start..].find(end) else {
        return Err(Error::Msg(".gitignore migration-docs marker is incomplete".into()));
    };
    let mut end_pos = start + rel_end + end.len();
    if text[end_pos..].starts_with('\n') {
        end_pos += 1;
    }
    let mut out = String::new();
    out.push_str(&text[..start]);
    out.push_str(block);
    if !block.ends_with('\n') {
        out.push('\n');
    }
    out.push_str(&text[end_pos..]);
    Ok(out)
}

fn keep_file(outdir: &Path, dest_rel: &str, created: &mut u32, skipped: &mut u32) -> Result<()> {
    let dest = outdir.join(dest_rel);
    if dest.exists() {
        log(&format!("skip (exists): {dest_rel}"));
        *skipped += 1;
        return Ok(());
    }
    if let Some(parent) = dest.parent() {
        fs::create_dir_all(parent)?;
    }
    fs::write(&dest, "")?;
    log(&format!("created: {dest_rel}"));
    *created += 1;
    Ok(())
}

fn maybe_uv_lock(outdir: &Path, created: &mut u32, skipped: &mut u32) -> Result<()> {
    let pyproject = outdir.join("pyproject.toml");
    let lock = outdir.join("uv.lock");
    if pyproject.is_file() && on_path("uv") {
        if lock.is_file() {
            log("skip (exists): uv.lock");
            *skipped += 1;
            return Ok(());
        }
        log("writing uv.lock");
        let status = Command::new("uv").arg("lock").current_dir(outdir).status()?;
        if !status.success() {
            return Err(Error::Msg(format!("uv lock failed ({status})")));
        }
        *created += 1;
        Ok(())
    } else if !lock.is_file() {
        warn(&format!(
            "uv not on PATH; skip uv.lock. Run: cd {} && uv lock",
            outdir.display()
        ));
        Ok(())
    } else {
        Ok(())
    }
}

fn install_agents(req: &NewCourse) -> Result<()> {
    if !req.with_agents {
        log("agents: skipped (--no-agents)");
        return Ok(());
    }
    let mut argv = vec![
        "symkit".to_string(),
        "install".to_string(),
        req.outdir.display().to_string(),
        "--harness".to_string(),
        "teaching".to_string(),
        "--role".to_string(),
        "instructor".to_string(),
        "--docs".to_string(),
        "slos".to_string(),
        "--yes".to_string(),
    ];
    if let Some(adapters) = req.adapters.as_deref().filter(|s| !s.is_empty()) {
        argv.push("--adapters".to_string());
        argv.push(adapters.to_string());
    }
    if !on_path("symkit") {
        warn("symkit not on PATH; skip agent install.");
        warn(&format!("Next: {}", argv.join(" ")));
        return Ok(());
    }
    log("Installing teaching harness (instructor + --docs slos; no --scaffold)");
    let mut cmd = Command::new("symkit");
    cmd.args(&argv[1..]);
    let status = cmd.status()?;
    if !status.success() {
        return Err(Error::Msg(format!("symkit install failed ({status})")));
    }
    Ok(())
}

fn on_path(bin: &str) -> bool {
    match Command::new(bin)
        .arg("--help")
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .status()
    {
        Ok(_) => true,
        Err(err) if err.kind() == std::io::ErrorKind::NotFound => false,
        Err(_) => false,
    }
}

#[cfg(unix)]
fn make_exec(path: &Path) -> Result<()> {
    use std::os::unix::fs::PermissionsExt;
    let mut perms = fs::metadata(path)?.permissions();
    perms.set_mode(perms.mode() | 0o111);
    fs::set_permissions(path, perms)?;
    Ok(())
}

#[cfg(not(unix))]
fn make_exec(_path: &Path) -> Result<()> {
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    fn kit() -> PathBuf {
        PathBuf::from(env!("CARGO_MANIFEST_DIR"))
    }

    fn new_req(outdir: PathBuf, name: &str) -> NewCourse {
        NewCourse {
            course_name: name.to_string(),
            outdir,
            course_number: "BIO 101".to_string(),
            course_title: "Intro Biology".to_string(),
            shape: None,
            runtime: Some("none".to_string()),
            org: None,
            preset: None,
            lms: None,
            github_org: None,
            with_pages: false,
            with_agents: false,
            adapters: None,
            migration_docs: true,
            department: None,
        }
    }

    #[test]
    fn department_file_selects_msia_and_rejects_other_numbers() {
        let tmp = tempfile::tempdir().unwrap();
        let out = tmp.path().join("ian-6xx");
        let mut req = new_req(out.clone(), "ian-6xx");
        req.course_number = "IAN 6xx".to_string();
        req.course_title = "Course title".to_string();
        req.runtime = None;
        req.department = Some(kit().join("templates/department.yml"));
        req.migration_docs = false;
        scaffold(&kit(), &req).unwrap();
        let readme = fs::read_to_string(out.join("README.md")).unwrap();
        assert!(readme.contains("uncg-msia/ian-6xx"), "{readme}");
        assert!(out.join("Containerfile").is_file());
        assert!(out.join(".github/workflows/release.yml").is_file());

        let bad = tmp.path().join("bio-101");
        let mut rejected = new_req(bad, "bio-101");
        rejected.runtime = None;
        rejected.department = Some(kit().join("templates/department.yml"));
        let err = scaffold(&kit(), &rejected).unwrap_err();
        assert!(err.to_string().contains("ian"), "{err}");
    }

    #[test]
    fn department_without_org_overlays_generic_templates() {
        let tmp = tempfile::tempdir().unwrap();
        let file = tmp.path().join("department.yml");
        fs::write(
            &file,
            "version: 1\nslug: bio\nname: Biology\nlms: Moodle\ngithub_org: example-edu\ncourse_numbers:\n  - bio\n",
        )
        .unwrap();
        let out = tmp.path().join("bio-101");
        let mut req = new_req(out.clone(), "bio-101");
        req.runtime = None;
        req.department = Some(file);
        req.migration_docs = false;
        scaffold(&kit(), &req).unwrap();
        let readme = fs::read_to_string(out.join("README.md")).unwrap();
        assert!(readme.contains("Moodle"), "{readme}");
        assert!(readme.contains("github.com/example-edu/bio-101"), "{readme}");
        assert!(!out.join("Containerfile").exists());
        assert!(!out.join(".github/workflows/release.yml").exists());
    }

    #[test]
    fn explicit_runtime_overrides_department_and_create_does_not_replace() {
        let tmp = tempfile::tempdir().unwrap();
        let created = create_department(&kit(), tmp.path()).unwrap();
        assert_eq!(created, tmp.path().join("department.yml"));
        let first = fs::read_to_string(&created).unwrap();
        assert!(first.contains("slug: msia"), "{first}");
        fs::write(&created, first.replace("slug: msia", "slug: edited")).unwrap();
        create_department(&kit(), &created).unwrap();
        let second = fs::read_to_string(&created).unwrap();
        assert!(second.contains("slug: edited"), "{second}");
        let err = create_department(&kit(), &kit().join("department.yml")).unwrap_err();
        assert!(err.to_string().contains("symcourse checkout"), "{err}");

        let out = tmp.path().join("ian-6xx");
        let mut req = new_req(out.clone(), "ian-6xx");
        req.course_number = "IAN 6xx".to_string();
        req.course_title = "Course title".to_string();
        req.runtime = Some("none".to_string());
        req.department = Some(kit().join("templates/department.yml"));
        req.migration_docs = false;
        scaffold(&kit(), &req).unwrap();
        assert!(!out.join("Containerfile").exists());
        assert!(out.join(".github/workflows/release.yml").is_file());
    }

    #[test]
    fn edit_and_delete_a_department_copy() {
        let tmp = tempfile::tempdir().unwrap();
        let created = create_department(&kit(), tmp.path()).unwrap();
        let editor = tmp.path().join("editor.sh");
        fs::write(&editor, "#!/bin/sh\nprintf '\\n# edited\\n' >> \"$1\"\n").unwrap();
        #[cfg(unix)]
        {
            use std::os::unix::fs::PermissionsExt;
            let mut perms = fs::metadata(&editor).unwrap().permissions();
            perms.set_mode(0o755);
            fs::set_permissions(&editor, perms).unwrap();
        }
        edit_department_with(&kit(), &created, Some(editor.to_str().unwrap())).unwrap();
        let text = fs::read_to_string(&created).unwrap();
        assert!(text.contains("# edited"), "{text}");

        delete_department(&kit(), &created).unwrap();
        assert!(!created.exists());
        let err = delete_department(&kit(), &created).unwrap_err();
        assert!(err.to_string().contains("not found"), "{err}");

        let err = edit_department_with(&kit(), &kit().join("templates/department.yml"), Some("/bin/true")).unwrap_err();
        assert!(err.to_string().contains("stock department template"), "{err}");
        let err = delete_department(&kit(), &kit().join("templates/department.yml")).unwrap_err();
        assert!(err.to_string().contains("stock department template"), "{err}");
    }

    #[test]
    fn default_new_writes_migration_docs() {
        let tmp = tempfile::tempdir().unwrap();
        let out = tmp.path().join("bio-101");
        scaffold(&kit(), &new_req(out.clone(), "bio-101")).unwrap();
        assert!(out.join("migration-docs/README.md").is_file());
        assert!(out.join("migration-docs/.gitkeep").is_file());
        let gitignore = fs::read_to_string(out.join(".gitignore")).unwrap();
        assert_eq!(gitignore.matches(MIG_BEGIN).count(), 1, "{gitignore}");
        assert!(gitignore.contains("migration-docs/**"), "{gitignore}");
    }

    #[test]
    fn no_migration_docs_skips_create_and_refresh() {
        let tmp = tempfile::tempdir().unwrap();
        let out = tmp.path().join("bio-101");
        let mut req = new_req(out.clone(), "bio-101");
        req.migration_docs = false;
        scaffold(&kit(), &req).unwrap();
        assert!(!out.join("migration-docs").exists());
        let gitignore = fs::read_to_string(out.join(".gitignore")).unwrap();
        assert_eq!(gitignore.matches(MIG_BEGIN).count(), 1, "{gitignore}");
        assert!(gitignore.contains("migration-docs/**"), "{gitignore}");

        req.migration_docs = true;
        scaffold(&kit(), &req).unwrap();
        assert!(out.join("migration-docs/README.md").is_file());
        let mut keep = fs::read_to_string(out.join("migration-docs/.gitkeep")).unwrap();
        keep.push_str("syllabus.pdf\n");
        fs::write(out.join("migration-docs/.gitkeep"), keep).unwrap();
        req.migration_docs = false;
        scaffold(&kit(), &req).unwrap();
        let gitignore = fs::read_to_string(out.join(".gitignore")).unwrap();
        assert!(!gitignore.contains("!migration-docs/syllabus.pdf"), "{gitignore}");
        assert!(out.join("migration-docs/README.md").is_file());

        req.migration_docs = true;
        scaffold(&kit(), &req).unwrap();
        let gitignore = fs::read_to_string(out.join(".gitignore")).unwrap();
        assert!(gitignore.contains("!migration-docs/syllabus.pdf"), "{gitignore}");
    }

    #[test]
    fn migration_tracks_a_path_listed_in_gitkeep() {
        let tmp = tempfile::tempdir().unwrap();
        let out = tmp.path().join("bio-101");
        let req = new_req(out.clone(), "bio-101");
        scaffold(&kit(), &req).unwrap();
        assert!(out.join("migration-docs/README.md").is_file());
        let readme = fs::read_to_string(out.join("migration-docs/README.md")).unwrap();
        assert!(readme.contains("Back it up somewhere else"), "{readme}");
        assert!(readme.contains("`lectures/`"), "{readme}");
        let gitignore = fs::read_to_string(out.join(".gitignore")).unwrap();
        assert_eq!(gitignore.matches(MIG_BEGIN).count(), 1, "{gitignore}");
        assert!(gitignore.contains("migration-docs/**"), "{gitignore}");
        assert!(!gitignore.contains("!migration-docs/syllabus.pdf"), "{gitignore}");

        let mut keep = fs::read_to_string(out.join("migration-docs/.gitkeep")).unwrap();
        keep.push_str("syllabus.pdf\nscans/week-01.pdf\n../secret\n");
        fs::write(out.join("migration-docs/.gitkeep"), &keep).unwrap();
        let err = scaffold(&kit(), &req).unwrap_err();
        assert!(err.to_string().contains("unsafe path"), "{err}");

        keep = fs::read_to_string(out.join("migration-docs/.gitkeep")).unwrap();
        let keep = keep.replace("../secret\n", "");
        fs::write(out.join("migration-docs/.gitkeep"), keep).unwrap();
        let before = fs::read_to_string(out.join("migration-docs/README.md")).unwrap();
        scaffold(&kit(), &req).unwrap();
        let gitignore = fs::read_to_string(out.join(".gitignore")).unwrap();
        assert_eq!(gitignore.matches(MIG_BEGIN).count(), 1, "{gitignore}");
        assert!(gitignore.contains("!migration-docs/syllabus.pdf"), "{gitignore}");
        assert!(gitignore.contains("!migration-docs/scans/"), "{gitignore}");
        assert!(gitignore.contains("!migration-docs/scans/week-01.pdf"), "{gitignore}");
        assert_eq!(
            fs::read_to_string(out.join("migration-docs/README.md")).unwrap(),
            before
        );
        scaffold(&kit(), &req).unwrap();
        assert_eq!(
            fs::read_to_string(out.join(".gitignore"))
                .unwrap()
                .matches(MIG_BEGIN)
                .count(),
            1
        );
    }
}
