// Copyright (c) 2026, PalEm Dynamics LLC
// Licensed under the Apache License, Version 2.0.

use std::{
    collections::BTreeMap,
    fs,
    io::Write,
    path::{
        Path,
        PathBuf,
    },
    process::{
        Command,
        Stdio,
    },
};

use crate::{
    catalog::{
        Catalog,
        ItemKind,
        Resolve,
    },
    error::{
        Error,
        Result,
    },
};

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
    let (shape, runtime, org) = catalog.apply_preset(
        req.preset.as_deref(),
        req.shape.as_deref(),
        req.runtime.as_deref(),
        req.org.as_deref(),
    )?;
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
