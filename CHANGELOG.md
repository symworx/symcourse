# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
