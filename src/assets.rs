// Copyright (c) 2026, PalEm Dynamics LLC
// Licensed under the Apache License, Version 2.0.

use std::{
    env,
    fs,
    path::{
        Path,
        PathBuf,
    },
};

use include_dir::{
    Dir,
    include_dir,
};

use crate::error::{
    Error,
    Result,
};

static EMBEDDED_CATALOG: &str = include_str!(concat!(env!("CARGO_MANIFEST_DIR"), "/catalog.yaml"));
static EMBEDDED_TEMPLATES: Dir<'_> = include_dir!("$CARGO_MANIFEST_DIR/templates");

/// A course kit root has `catalog.yaml` and `templates/`.
pub fn is_root(dir: &Path) -> bool {
    dir.join("catalog.yaml").is_file() && dir.join("templates").is_dir()
}

/// Prefer `SYMCOURSE_ROOT`, then a checkout next to the executable or the
/// working directory, then the versioned cache filled from the binary.
pub fn find_root() -> Result<PathBuf> {
    if let Ok(raw) = env::var("SYMCOURSE_ROOT") {
        let p = PathBuf::from(raw);
        if is_root(&p) {
            return Ok(fs::canonicalize(&p).unwrap_or(p));
        }
        return Err(Error::CatalogMissing(p.join("catalog.yaml")));
    }

    let mut candidates: Vec<PathBuf> = Vec::new();
    if let Ok(exe) = env::current_exe() {
        if let Some(dir) = exe.parent() {
            candidates.push(dir.to_path_buf());
        }
    }
    if let Ok(cwd) = env::current_dir() {
        candidates.push(cwd);
    }

    for start in candidates {
        let mut cur = Some(start.as_path());
        while let Some(dir) = cur {
            if is_root(dir) {
                return Ok(fs::canonicalize(dir).unwrap_or_else(|_| dir.to_path_buf()));
            }
            cur = dir.parent();
        }
    }

    ensure_embedded()
}

/// `$XDG_DATA_HOME/symcourse/<crate version>/` (or `~/.local/share/symcourse/<version>/`).
pub fn embedded_dir() -> PathBuf {
    data_dir().join(env!("CARGO_PKG_VERSION"))
}

fn data_dir() -> PathBuf {
    if let Some(p) = env::var_os("SYMCOURSE_DATA") {
        return PathBuf::from(p);
    }
    if let Some(p) = env::var_os("XDG_DATA_HOME") {
        return PathBuf::from(p).join("symcourse");
    }
    #[cfg(windows)]
    {
        if let Some(p) = env::var_os("LOCALAPPDATA") {
            return PathBuf::from(p).join("symcourse");
        }
    }
    if let Some(p) = env::var_os("HOME") {
        return PathBuf::from(p).join(".local/share/symcourse");
    }
    env::temp_dir().join("symcourse")
}

fn ensure_embedded() -> Result<PathBuf> {
    let dest = embedded_dir();
    if is_root(&dest) {
        return Ok(dest);
    }
    extract_embedded(&dest)?;
    if is_root(&dest) {
        Ok(dest)
    } else {
        Err(Error::RootNotFound)
    }
}

fn extract_embedded(dest: &Path) -> Result<()> {
    fs::create_dir_all(dest)?;
    EMBEDDED_TEMPLATES.extract(dest.join("templates"))?;
    fs::write(dest.join("catalog.yaml"), EMBEDDED_CATALOG)?;
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn embedded_extract_is_root_and_keeps_dot_github() {
        let dir = tempfile::tempdir().unwrap();
        extract_embedded(dir.path()).unwrap();
        assert!(is_root(dir.path()));
        let release = dir.path().join("templates/orgs/msia/release.yml");
        let pages = dir
            .path()
            .join("templates/extras/pages/.github/workflows/pages.yml.tpl");
        assert!(release.is_file(), "missing {}", release.display());
        assert!(pages.is_file(), "missing {}", pages.display());
    }
}
