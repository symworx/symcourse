# Development

How to build, test, and release this repository.

## Prerequisites

Use [rustup](https://rustup.rs/) so stable (build, clippy, tests) and nightly (`rustfmt`) stay available.

```bash
rustup toolchain install stable
rustup toolchain install nightly
rustup component add rustfmt clippy --toolchain stable
rustup component add rustfmt --toolchain nightly
rustup default stable
```

`./cli/symcourse` builds `target/debug/symcourse` when that binary is missing, then runs it. Inside this checkout the binary reads `catalog.yaml` and `templates/` from the tree. A binary installed elsewhere uses the copies embedded at compile time.

`git init` needs `git`. `--runtime uv` writes `uv.lock` when `uv` is on `PATH`. Nested agent install runs `symkit` when it is on `PATH`.

## Commands

From the repository root:

```bash
cargo +nightly fmt -- --check
cargo test
cargo clippy --all-targets -- -D warnings
./tests/smoke.sh
```

`cargo +nightly fmt` is the formatter (`rustfmt.toml`). Extend `./tests/smoke.sh` when scaffold behavior that a course tree can see changes.

## Branch model

GitHub Flow. The default branch is **`worx`**.

```text
feature/*  ──PR──►  worx  ──tag──►  vX.Y.Z
                 day-to-day CI         publish on tag
```

| Branch | Role |
|:-------|:-----|
| `worx` | Default. Open pull requests here. Keep it releasable. |
| `release/vX.Y.Z` | Optional freeze. The name matches `[package] version`. |

Suggested names: `feat/…`, `fix/…`, `docs/…`, `chore/…`.

Do not force-push `worx`.

## Releasing

A release is a version bump and a changelog entry on `worx`, then a manual tag `vX.Y.Z` on that commit. Tags are not created automatically. Publish runs from the tag. A merge to `worx` does not publish.

1. Merge feature work to `worx` with checks green.
2. On `worx`, or on an optional `release/vX.Y.Z` branch:

   ```bash
   ./scripts/bump-version.sh patch --dry-run
   ./scripts/bump-version.sh patch --changelog
   ```

   `patch`, `minor`, `major`, and `set X.Y.Z` are the other bumps. `./scripts/bump-version.sh` with no arguments prints the current version and checks `Cargo.toml` against `Cargo.lock`.
3. Fill the `## [X.Y.Z]` bullets in `CHANGELOG.md`. Keep the heading. The tag and `[package] version` must be the same number.
4. Open a pull request into `worx` if the bump is not already on the default branch. Merge when checks are green.
5. Tag that commit and push the tag:

   ```bash
   git tag -a vX.Y.Z -m "vX.Y.Z"
   git push origin vX.Y.Z
   ```

6. From that tagged commit, publish the crate:

   ```bash
   cargo publish
   ```

Create a crates.io API token before the first tag you want on the registry. Yank a bad version if you must. Do not reuse a burned version.

`v0.1.0` is the version in `Cargo.toml`. It is not on crates.io until that tag is published.
