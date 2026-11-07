// Copyright (c) 2026, Nathaniel T. Berry
// Licensed under the Apache License, Version 2.0.

//! Department identity (`templates/department.yml`).

use std::{
    collections::BTreeMap,
    fs,
    path::Path,
};

use serde::Deserialize;

use crate::{
    catalog::fill_repo_urls,
    error::{
        Error,
        Result,
    },
};

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct DepartmentFile {
    pub slug: String,
    pub name: String,
    pub org: Option<String>,
    pub runtime: Option<String>,
    pub lms: Option<String>,
    pub github_org: Option<String>,
    pub github_pages_host: Option<String>,
    pub faculty_docs: Option<String>,
    pub course_numbers: Vec<String>,
}

#[derive(Debug, Deserialize)]
struct DepartmentRaw {
    version: u32,
    slug: String,
    name: String,
    #[serde(default)]
    org: Option<String>,
    #[serde(default)]
    runtime: Option<String>,
    #[serde(default)]
    lms: Option<String>,
    #[serde(default)]
    github_org: Option<String>,
    #[serde(default)]
    github_pages_host: Option<String>,
    #[serde(default)]
    faculty_docs: Option<String>,
    course_numbers: Vec<String>,
}

pub fn load(path: &Path) -> Result<DepartmentFile> {
    let text = fs::read_to_string(path).map_err(|err| {
        if err.kind() == std::io::ErrorKind::NotFound {
            Error::DepartmentMissing(path.to_path_buf())
        } else {
            Error::Io(err)
        }
    })?;
    parse(path, &text)
}

pub fn parse(path: &Path, text: &str) -> Result<DepartmentFile> {
    let raw: DepartmentRaw = serde_yaml::from_str(text).map_err(|err| Error::DepartmentInvalid {
        path: path.to_path_buf(),
        message: err.to_string(),
    })?;
    if raw.version != 1 {
        return Err(Error::DepartmentInvalid {
            path: path.to_path_buf(),
            message: format!("unsupported version {} (expected 1)", raw.version),
        });
    }
    let slug = require_line(path, "slug", &raw.slug)?;
    if !valid_slug(&slug) {
        return Err(Error::DepartmentInvalid {
            path: path.to_path_buf(),
            message: "slug must be letters, digits, '-' or '_'".to_string(),
        });
    }
    let name = require_line(path, "name", &raw.name)?;
    let org = optional_id(path, "org", raw.org)?;
    let runtime = optional_id(path, "runtime", raw.runtime)?;
    let lms = match raw.lms {
        Some(value) => Some(require_line(path, "lms", &value)?),
        None => None,
    };
    let github_org = match raw.github_org {
        Some(value) => {
            let value = require_line(path, "github_org", &value)?;
            if !valid_slug(&value) {
                return Err(Error::DepartmentInvalid {
                    path: path.to_path_buf(),
                    message: "github_org must be letters, digits, '-' or '_'".to_string(),
                });
            }
            Some(value)
        }
        None => None,
    };
    let github_pages_host = match raw.github_pages_host {
        Some(value) => {
            let value = require_line(path, "github_pages_host", &value)?;
            if !valid_host(&value) {
                return Err(Error::DepartmentInvalid {
                    path: path.to_path_buf(),
                    message: "github_pages_host must be a hostname".to_string(),
                });
            }
            Some(value)
        }
        None => None,
    };
    let faculty_docs = match raw.faculty_docs {
        Some(value) => {
            let value = require_line(path, "faculty_docs", &value)?;
            if !valid_http_url(&value) {
                return Err(Error::DepartmentInvalid {
                    path: path.to_path_buf(),
                    message: "faculty_docs must be an http(s) URL".to_string(),
                });
            }
            Some(value)
        }
        None => None,
    };
    if raw.course_numbers.is_empty() {
        return Err(Error::DepartmentInvalid {
            path: path.to_path_buf(),
            message: "course_numbers needs at least one prefix".to_string(),
        });
    }
    let mut course_numbers = Vec::new();
    for number in raw.course_numbers {
        let number = number.trim().to_ascii_lowercase();
        if !valid_prefix(&number) {
            return Err(Error::DepartmentInvalid {
                path: path.to_path_buf(),
                message: format!("course number prefix '{number}' must be letters or digits"),
            });
        }
        if !course_numbers.contains(&number) {
            course_numbers.push(number);
        }
    }
    Ok(DepartmentFile {
        slug,
        name,
        org,
        runtime,
        lms,
        github_org,
        github_pages_host,
        faculty_docs,
        course_numbers,
    })
}

impl DepartmentFile {
    pub fn check_course(&self, course_name: &str, course_number: &str) -> Result<()> {
        let matched = self
            .course_numbers
            .iter()
            .any(|prefix| matches_prefix(course_name, prefix) && matches_prefix(course_number, prefix));
        if matched {
            return Ok(());
        }
        Err(Error::CourseNumberRejected {
            name: course_name.to_string(),
            number: course_number.to_string(),
            slug: self.slug.clone(),
            allowed: self.course_numbers.join(", "),
        })
    }
}

/// Fill identity vars the caller left empty, then rebuild clone and Pages URLs.
pub fn overlay(
    vars: &mut BTreeMap<String, String>,
    dept: &DepartmentFile,
    course_name: &str,
    lms_set: bool,
    github_set: bool,
) {
    if !lms_set {
        if let Some(lms) = &dept.lms {
            vars.insert("LMS".to_string(), lms.clone());
        }
    }
    if let Some(host) = &dept.github_pages_host {
        vars.insert("GITHUB_PAGES_HOST".to_string(), host.clone());
    }
    if let Some(docs) = &dept.faculty_docs {
        vars.insert("FACULTY_DOCS".to_string(), docs.clone());
    }
    if !github_set {
        if let Some(org) = &dept.github_org {
            vars.insert("GITHUB_ORG".to_string(), org.clone());
        }
    }
    fill_repo_urls(vars, course_name);
}

fn matches_prefix(value: &str, prefix: &str) -> bool {
    let value = value.to_ascii_lowercase();
    let Some(rest) = value.strip_prefix(prefix) else {
        return false;
    };
    rest.is_empty() || rest.starts_with(['-', '_', ' ', '.'])
}

fn optional_id(path: &Path, field: &str, value: Option<String>) -> Result<Option<String>> {
    match value {
        Some(value) => {
            let value = require_line(path, field, &value)?;
            if !valid_slug(&value) {
                return Err(Error::DepartmentInvalid {
                    path: path.to_path_buf(),
                    message: format!("{field} must be letters, digits, '-' or '_'"),
                });
            }
            Ok(Some(value))
        }
        None => Ok(None),
    }
}

fn require_line(path: &Path, field: &str, value: &str) -> Result<String> {
    let value = value.trim();
    if value.is_empty() || value.contains(['\n', '\r']) {
        return Err(Error::DepartmentInvalid {
            path: path.to_path_buf(),
            message: format!("{field} must be a single non-empty line"),
        });
    }
    Ok(value.to_string())
}

fn valid_slug(value: &str) -> bool {
    let mut chars = value.chars();
    match chars.next() {
        Some(ch) if ch.is_ascii_alphanumeric() => chars.all(|ch| ch.is_ascii_alphanumeric() || ch == '-' || ch == '_'),
        _ => false,
    }
}

fn valid_prefix(value: &str) -> bool {
    !value.is_empty() && value.chars().all(|ch| ch.is_ascii_alphanumeric())
}

fn valid_host(value: &str) -> bool {
    let mut chars = value.chars();
    match chars.next() {
        Some(ch) if ch.is_ascii_alphanumeric() => {
            chars.all(|ch| ch.is_ascii_alphanumeric() || ch == '-' || ch == '.') && !value.ends_with('.')
        }
        _ => false,
    }
}

fn valid_http_url(value: &str) -> bool {
    let rest = value.strip_prefix("https://").or_else(|| value.strip_prefix("http://"));
    match rest {
        Some(rest) => !rest.is_empty() && !rest.chars().any(|ch| ch.is_whitespace()),
        None => false,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn stock_template_is_msia_and_accepts_ian() {
        let path = Path::new(env!("CARGO_MANIFEST_DIR")).join("templates/department.yml");
        let dept = load(&path).unwrap();
        assert_eq!(dept.slug, "msia");
        assert_eq!(dept.org.as_deref(), Some("msia"));
        assert_eq!(dept.runtime.as_deref(), Some("uv"));
        assert_eq!(dept.course_numbers, vec!["ian".to_string()]);
        dept.check_course("ian-6xx", "IAN 6xx").unwrap();
        dept.check_course("ian", "ian").unwrap();
        let err = dept.check_course("bio-101", "BIO 101").unwrap_err();
        assert!(err.to_string().contains("ian"), "{err}");
        let err = dept.check_course("ian-6xx", "BIO 101").unwrap_err();
        assert!(err.to_string().contains("not a msia course number"), "{err}");
    }

    #[test]
    fn empty_course_numbers_are_rejected() {
        let err = parse(
            Path::new("department.yml"),
            "version: 1\nslug: msia\nname: MSIA\ncourse_numbers: []\n",
        )
        .unwrap_err();
        assert!(err.to_string().contains("course_numbers"), "{err}");
    }
}
