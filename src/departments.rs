// Copyright (c) 2026, Nathaniel T. Berry
// Licensed under the Apache License, Version 2.0.

//! Menu for one `department.yml`. Arrow keys on a terminal; a line prompt otherwise.

use std::{
    io::{
        self,
        BufRead,
        IsTerminal,
        Write,
    },
    path::Path,
};

use crate::{
    error::{
        Error,
        Result,
    },
    scaffold,
    term_menu::{
        self,
        Choice,
        MenuFail,
    },
};

const ACTIONS: [&str; 4] = ["new", "edit", "delete", "quit"];

pub fn run(root: &Path, dest: &Path) -> Result<()> {
    let stdin_tty = io::stdin().is_terminal();
    let stdout_tty = io::stdout().is_terminal();
    if stdin_tty && stdout_tty && term_menu::raw_mode_works() {
        return run_arrows(root, dest);
    }
    run_lines(root, dest, stdin_tty, &mut io::stdin().lock(), &mut io::stdout())
}

fn run_lines(
    root: &Path,
    dest: &Path,
    interactive: bool,
    reader: &mut impl BufRead,
    out: &mut impl Write,
) -> Result<()> {
    if interactive {
        writeln!(
            out,
            "Shortcuts: symcourse create department, symcourse edit department, symcourse delete department"
        )?;
        writeln!(out)?;
    }
    loop {
        if !interactive {
            writeln!(out, "new:    symcourse create department")?;
            writeln!(out, "edit:   symcourse edit department")?;
            writeln!(out, "delete: symcourse delete department")?;
            return Ok(());
        }
        for action in ACTIONS {
            writeln!(out, "{action}")?;
        }
        let choice = prompt(out, reader, "> ")?.to_ascii_lowercase();
        match choice.as_str() {
            "new" => report(out, scaffold::create_department(root, dest).map(|_| ()))?,
            "edit" => report(out, scaffold::edit_department(root, dest))?,
            "delete" => line_delete(root, dest, reader, out)?,
            "quit" | "q" | "" => return Ok(()),
            other => writeln!(out, "choose new, edit, delete, or quit (got '{other}')")?,
        }
    }
}

fn run_arrows(root: &Path, dest: &Path) -> Result<()> {
    {
        let mut out = io::stdout();
        writeln!(
            out,
            "Shortcuts: symcourse create department, symcourse edit department, symcourse delete department"
        )?;
        writeln!(out)?;
        writeln!(out, "Arrow keys move. Enter selects. q or Ctrl-C quits.")?;
        writeln!(out)?;
    }
    loop {
        let choice = {
            let mut out = io::stdout();
            match term_menu::select_index(&mut out, &ACTIONS).map_err(menu_error)? {
                Choice::Chosen(index) => ACTIONS[index],
                Choice::Back | Choice::Quit => return Ok(()),
            }
        };
        match choice {
            "new" => report_stdout(scaffold::create_department(root, dest).map(|_| ())),
            "edit" => report_stdout(scaffold::edit_department(root, dest)),
            "delete" => arrow_delete(root, dest)?,
            "quit" => return Ok(()),
            _ => {}
        }
    }
}

fn line_delete(root: &Path, dest: &Path, reader: &mut impl BufRead, out: &mut impl Write) -> Result<()> {
    if !confirm_delete(dest, reader, out)? {
        writeln!(out, ">>> delete cancelled")?;
        return Ok(());
    }
    report(out, scaffold::delete_department(root, dest))
}

fn arrow_delete(root: &Path, dest: &Path) -> Result<()> {
    let confirmed = {
        let mut reader = io::stdin().lock();
        let mut out = io::stdout();
        confirm_delete(dest, &mut reader, &mut out)?
    };
    if confirmed {
        report_stdout(scaffold::delete_department(root, dest));
    } else {
        println!(">>> delete cancelled");
    }
    Ok(())
}

fn confirm_delete(dest: &Path, reader: &mut impl BufRead, out: &mut impl Write) -> Result<bool> {
    write!(out, "Delete {}? [y/N] ", dest.display())?;
    out.flush()?;
    let mut answer = String::new();
    reader.read_line(&mut answer)?;
    Ok(matches!(answer.trim(), "y" | "Y" | "yes" | "YES"))
}

fn prompt(out: &mut impl Write, reader: &mut impl BufRead, label: &str) -> Result<String> {
    write!(out, "{label}")?;
    out.flush()?;
    let mut line = String::new();
    reader.read_line(&mut line)?;
    Ok(line.trim().to_string())
}

fn report(out: &mut impl Write, result: Result<()>) -> Result<()> {
    if let Err(err) = result {
        writeln!(out, "error: {err}")?;
    }
    Ok(())
}

fn report_stdout(result: Result<()>) {
    if let Err(err) = result {
        println!("error: {err}");
    }
}

fn menu_error(err: MenuFail) -> Error {
    match err {
        MenuFail::NotATerminal => Error::Msg("terminal raw mode unavailable".into()),
        MenuFail::Io(err) => Error::Io(err),
    }
}

#[cfg(test)]
mod tests {
    use std::io::Cursor;

    use super::*;

    #[test]
    fn plain_departments_prints_shortcuts_and_exits() {
        let mut input = Cursor::new("");
        let mut out = Vec::new();
        run_lines(Path::new("."), Path::new("department.yml"), false, &mut input, &mut out).unwrap();
        let text = String::from_utf8(out).unwrap();
        assert!(text.contains("new:    symcourse create department\n"), "{text}");
        assert!(text.contains("edit:   symcourse edit department\n"), "{text}");
        assert!(text.contains("delete: symcourse delete department\n"), "{text}");
        assert!(!text.contains("> "), "{text}");
    }

    #[test]
    fn line_menu_rejects_unknown_then_quits() {
        let mut input = Cursor::new("create\nquit\n");
        let mut out = Vec::new();
        run_lines(Path::new("."), Path::new("department.yml"), true, &mut input, &mut out).unwrap();
        let text = String::from_utf8(out).unwrap();
        assert!(
            text.contains("choose new, edit, delete, or quit (got 'create')"),
            "{text}"
        );
        assert!(text.contains("Shortcuts: symcourse create department"), "{text}");
    }

    #[test]
    fn line_menu_new_reports_a_missing_template_and_quit_stops() {
        let mut input = Cursor::new("new\nquit\n");
        let mut out = Vec::new();
        run_lines(
            Path::new("/no/such/kit"),
            Path::new("department.yml"),
            true,
            &mut input,
            &mut out,
        )
        .unwrap();
        let text = String::from_utf8(out).unwrap();
        assert!(text.contains("error: missing template:"), "{text}");
    }
}
