// Copyright (c) 2026, PalEm Dynamics LLC
// Licensed under the Apache License, Version 2.0.

use std::path::PathBuf;

use thiserror::Error;

pub type Result<T> = std::result::Result<T, Error>;

#[derive(Debug, Error)]
pub enum Error {
    #[error("catalog not found: {0}")]
    CatalogMissing(PathBuf),
    #[error("templates not found: {0}")]
    TemplatesMissing(PathBuf),
    #[error(
        "cannot find catalog.yaml and templates/ (set SYMCOURSE_ROOT, or run from a checkout; cargo-install uses an embedded copy)"
    )]
    RootNotFound,
    #[error("unknown --{kind} '{ident}' (known: {known})")]
    UnknownId {
        kind: &'static str,
        ident: String,
        known: String,
    },
    #[error("invalid course-name: {0}")]
    InvalidCourseName(String),
    #[error("--course-number (or --code) is required")]
    MissingCourseNumber,
    #[error("--course-title (or --title) is required")]
    MissingCourseTitle,
    #[error("missing template: {0}")]
    MissingTemplate(String),
    #[error("{0}")]
    Io(#[from] std::io::Error),
    #[error("catalog.yaml: {0}")]
    Yaml(#[from] serde_yaml::Error),
    #[error("{0}")]
    Msg(String),
}
