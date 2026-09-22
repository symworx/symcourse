// Copyright (c) 2026, PalEm Dynamics LLC
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
                },
            )
        }
    }
}
