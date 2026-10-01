# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- Tag pushes run the release workflow, which publishes the crate. `v0.1.0` is already on crates.io.

## [0.1.0] - 2026-09-21

### Added

- Rust binary `symcourse`. `./cli/symcourse` builds it; `cargo install --locked --path .` installs this checkout. The binary scaffolds a course repository from `catalog.yaml` and `templates/`.

## Version Links

[0.1.0]: https://github.com/symworx/symcourse/releases/tag/v0.1.0
