// Copyright (c) 2026, Nathaniel T. Berry
// Licensed under the Apache License, Version 2.0.

use std::{
    env,
    path::PathBuf,
    process::ExitCode,
};

use clap::{
    Args,
    CommandFactory,
    Parser,
    Subcommand,
};
use symcourse::{
    assets::find_root,
    error::Result,
    scaffold::{
        self,
        NewCourse,
    },
};

#[derive(Parser)]
#[command(
    name = "symcourse",
    about = "Scaffold a course repository from catalog.yaml (shape + runtime + org).",
    after_help = "\
Departments:
  ~/.local/symcourse/department.yml: slug, name, org, runtime, LMS, GitHub org, and course-number prefixes.

  departments         Menu for that file. Arrow keys choose new, edit, delete, or quit
  create department   Write department.yml. Shortcut for new
  edit department     Open department.yml. Shortcut for edit
  delete department   Remove department.yml. Shortcut for delete
",
    disable_help_subcommand = true
)]
struct Cli {
    #[command(subcommand)]
    command: Option<Command>,
}

#[derive(Subcommand)]
enum Command {
    /// Shapes, runtimes, orgs, and presets
    List,
    /// Show usage
    Help,
    /// Scaffold a course repository
    New(Box<NewArgs>),
    /// Write a department file. Shortcut for the new choice in `departments`
    #[command(hide = true)]
    Create(CreateArgs),
    /// Menu for a department file. Arrow keys choose new, edit, or delete
    #[command(hide = true)]
    Departments,
    /// Open a department file. Shortcut for the edit choice in `departments`
    #[command(hide = true)]
    Edit(EditArgs),
    /// Remove a department file. Shortcut for the delete choice in `departments`
    #[command(hide = true)]
    Delete(DeleteArgs),
}

#[derive(Args)]
#[command(subcommand_required = true, arg_required_else_help = true)]
struct CreateArgs {
    #[command(subcommand)]
    command: CreateCommand,
}

#[derive(Subcommand)]
enum CreateCommand {
    /// Write department.yml from the stock template
    Department(DepartmentPathArgs),
}

#[derive(Args)]
#[command(subcommand_required = true, arg_required_else_help = true)]
struct EditArgs {
    #[command(subcommand)]
    command: EditCommand,
}

#[derive(Subcommand)]
enum EditCommand {
    /// Open department.yml in $VISUAL or $EDITOR
    Department(DepartmentPathArgs),
}

#[derive(Args)]
#[command(subcommand_required = true, arg_required_else_help = true)]
struct DeleteArgs {
    #[command(subcommand)]
    command: DeleteCommand,
}

#[derive(Subcommand)]
enum DeleteCommand {
    /// Remove department.yml
    Department(DepartmentPathArgs),
}

#[derive(Args)]
struct DepartmentPathArgs {
    /// File or directory (default: ~/.local/symcourse/department.yml)
    path: Option<PathBuf>,
}

#[derive(Args)]
struct NewArgs {
    /// Repo / directory name, e.g. bio-101
    course_name: String,
    /// Destination (default: ./<course-name> under the working directory)
    outdir: Option<PathBuf>,
    /// Catalog / display code (alias: --code)
    #[arg(long = "course-number", visible_alias = "code")]
    course_number: Option<String>,
    /// Human title (alias: --title)
    #[arg(long = "course-title", visible_alias = "title")]
    course_title: Option<String>,
    /// Folder spine (default from catalog)
    #[arg(long)]
    shape: Option<String>,
    /// Language runtime stubs: none or uv
    #[arg(long)]
    runtime: Option<String>,
    /// Identity overlay (default from catalog)
    #[arg(long)]
    org: Option<String>,
    /// Named combo; msia = course + uv + msia. Other flags override
    #[arg(long)]
    preset: Option<String>,
    /// Substituted as __LMS__
    #[arg(long)]
    lms: Option<String>,
    /// GitHub org for clone URLs
    #[arg(long = "github-org")]
    github_org: Option<String>,
    /// HTML study hub and Pages workflow
    #[arg(long = "with-pages")]
    with_pages: bool,
    /// Skip nested `symkit install`
    #[arg(long = "no-agents")]
    no_agents: bool,
    /// Passed to nested symkit (grok, claude, codex, all, none)
    #[arg(long)]
    adapters: Option<String>,
    /// Do not create migration-docs/ and do not refresh its .gitkeep exceptions
    #[arg(long = "no-migration-docs")]
    no_migration_docs: bool,
    /// Department file. Checks course numbers. Fills empty org, runtime, LMS, and GitHub org
    #[arg(long)]
    department: Option<PathBuf>,
}

fn main() -> ExitCode {
    match run() {
        Ok(()) => ExitCode::SUCCESS,
        Err(err) => {
            eprintln!("error: {err}");
            ExitCode::from(1)
        }
    }
}

fn run() -> Result<()> {
    let cli = Cli::parse();
    match cli.command {
        None | Some(Command::Help) => {
            Cli::command().print_long_help()?;
            println!();
            Ok(())
        }
        Some(Command::List) => {
            let root = find_root()?;
            let catalog = symcourse::catalog::Catalog::load(&root.join("catalog.yaml"))?;
            print!("{}", catalog.format_list());
            println!("Departments: symcourse departments");
            println!();
            Ok(())
        }
        Some(Command::New(args)) => {
            let root = find_root()?;
            let outdir = match args.outdir {
                Some(path) => path,
                None => env::current_dir()?.join(&args.course_name),
            };
            scaffold::scaffold(
                &root,
                &NewCourse {
                    course_name: args.course_name,
                    outdir,
                    course_number: args.course_number.unwrap_or_default(),
                    course_title: args.course_title.unwrap_or_default(),
                    shape: args.shape,
                    runtime: args.runtime,
                    org: args.org,
                    preset: args.preset,
                    lms: args.lms,
                    github_org: args.github_org,
                    with_pages: args.with_pages,
                    with_agents: !args.no_agents,
                    adapters: args.adapters,
                    migration_docs: !args.no_migration_docs,
                    department: args.department,
                },
            )
        }
        Some(Command::Create(args)) => {
            let CreateCommand::Department(department) = args.command;
            let root = find_root()?;
            let dest = department_dest(department.path)?;
            scaffold::create_department(&root, &dest)?;
            Ok(())
        }
        Some(Command::Edit(args)) => {
            let EditCommand::Department(department) = args.command;
            let root = find_root()?;
            let dest = department_dest(department.path)?;
            scaffold::edit_department(&root, &dest)
        }
        Some(Command::Delete(args)) => {
            let DeleteCommand::Department(department) = args.command;
            let root = find_root()?;
            let dest = department_dest(department.path)?;
            scaffold::delete_department(&root, &dest)
        }
        Some(Command::Departments) => {
            let root = find_root()?;
            let dest = department_dest(None)?;
            symcourse::departments::run(&root, &dest)
        }
    }
}

fn department_dest(path: Option<PathBuf>) -> Result<PathBuf> {
    match path {
        Some(path) => Ok(path),
        None => symcourse::departments::default_department_file(),
    }
}

#[cfg(test)]
mod tests {
    use clap::CommandFactory;

    use super::Cli;

    #[test]
    fn help_puts_department_commands_in_their_own_section() {
        let mut cmd = Cli::command().term_width(120);
        let mut buf = Vec::new();
        cmd.write_long_help(&mut buf).unwrap();
        let text = String::from_utf8(buf).unwrap();
        let (commands, departments) = text.split_once("Departments:").expect("departments heading");
        assert!(commands.contains("Commands:"), "{text}");
        assert!(commands.contains("\n  new "), "{commands}");
        assert!(!commands.contains("\n  departments"), "{commands}");
        assert!(!commands.contains("\n  create"), "{commands}");
        assert!(!commands.contains("\n  edit"), "{commands}");
        assert!(!commands.contains("\n  delete"), "{commands}");
        assert!(
            departments.contains("~/.local/symcourse/department.yml:"),
            "{departments}"
        );
        assert!(
            departments.contains("\n  departments         Menu for that file."),
            "{departments}"
        );
        assert!(
            departments.contains("\n  create department   Write department.yml."),
            "{departments}"
        );
        assert!(
            departments.contains("\n  edit department     Open department.yml."),
            "{departments}"
        );
        assert!(
            departments.contains("\n  delete department   Remove department.yml."),
            "{departments}"
        );
    }
}
