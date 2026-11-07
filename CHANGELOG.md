# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

## [0.2.1] - 2026-11-07

### Added

- `symcourse new` writes `migration-docs/` for local legacy files. `--no-migration-docs` skips the directory and does not refresh `.gitkeep` exceptions. Dumps stay gitignored unless a path is listed in `migration-docs/.gitkeep`.
- `symcourse help` groups `departments`, `create department`, `edit department`, and `delete department` in one section. `symcourse departments` uses the arrow keys for `new`, `edit`, `delete`, and `quit`. Enter selects. `q` or Ctrl-C quits. Without a terminal it prints the shortcuts and exits. `create department` writes `~/.local/symcourse/department.yml` unless a path or `SYMCOURSE_DEPARTMENT` is set. `edit department` opens it in `$VISUAL` or `$EDITOR`, and `delete department` removes it. The stock file is MSIA (`org: msia`, `runtime: uv`) and accepts the course-number prefix `ian`. `new --department <file>` checks the course name and course number, and fills org, runtime, LMS, and GitHub org when those flags are omitted.

## [0.2.0] - 2026-10-01

### Added

- GitHub Actions CI on `worx`: fmt, clippy, tests, and `./tests/smoke.sh`.
- Release workflow that publishes to crates.io when a `v*` tag is pushed, after the tag matches `Cargo.toml` and `CHANGELOG.md` has `## [X.Y.Z]`.

### Changed

- Copyright holder is Nathaniel T. Berry. The license stays Apache-2.0.
- `v0.1.0` stays the published 0.1.0 crate and is not republished.

## [0.1.0] - 2026-09-21

### Added

- Rust binary `symcourse`. `./cli/symcourse` builds it; `cargo install --locked --path .` installs this checkout. The binary scaffolds a course repository from `catalog.yaml` and `templates/`.

## Version Links

[0.2.0]: https://github.com/symworx/symcourse/releases/tag/v0.2.0

[0.1.0]: https://github.com/symworx/symcourse/releases/tag/v0.1.0
