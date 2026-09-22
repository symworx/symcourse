# symcourse

Scaffold a **course repository**: layout, runtime, and identity. Agent
packs come from [symworx/symkit](https://github.com/symworx/symkit).

The default is **course- and university-agnostic**. UNCG MSIA / IAN is an
optional overlay (`--preset msia`), not the product.

## Install

From a clone, `./cli/symcourse` builds the debug binary and runs it. In this checkout the binary reads `catalog.yaml` and `templates/` from the tree.

```bash
cargo install --locked --path .
```

A published tag installs the same binary. The catalog and templates are embedded at compile time:

```bash
cargo install --locked symcourse
```

`v0.1.0` is the package version. It is on crates.io only after that tag is published. Pull requests go to `worx`. See [CONTRIBUTING.md](CONTRIBUTING.md) and [DEVELOPMENT.md](DEVELOPMENT.md#releasing).

## Quick start

```bash
./cli/symcourse list

# any course (no container, LMS-neutral)
./cli/symcourse new bio-101 \
  --course-number "BIO 101" \
  --course-title "Intro Biology"

# Python runtime (uv + Containerfile + devcontainer)
./cli/symcourse new stat-200 \
  --course-number "STAT 200" \
  --course-title "Applied stats" \
  --runtime uv

# UNCG MSIA / IAN master (course + uv + Canvas / org remotes)
./cli/symcourse new ian-6xx \
  --preset msia \
  --course-number "IAN 6xx" \
  --course-title "Course title"

# existing directory (fills missing files only):
./cli/symcourse new bio-101 /path/to/bio-101 \
  --course-number "BIO 101" \
  --course-title "Intro Biology"
```

`--course-number` and `--course-title` are required (`--code` and `--title`
are aliases). Existing files are skipped.

If `symkit` is on `PATH`, `new` then runs:

```bash
symkit install <outdir> --harness teaching --role instructor --docs slos --yes
```

No `--scaffold`. Layout is this tool’s job. If `symkit` is missing, the
course tree is still written and the install command is printed.
`--no-agents` skips the nested install.

## Catalog

`catalog.yaml` is the source of truth. Do not hardcode shape, runtime, or
org ids in the scaffolder.

| Flag | Default | Meaning |
|:--|:--|:--|
| `--shape` | `course` | Folder spine: assignments, lectures, docs, data |
| `--runtime` | `none` | `none` or `uv` (Containerfile, pyproject, devcontainer) |
| `--org` | `none` | Identity overlay. `msia` = Canvas, uncg-msia remotes, org release |
| `--preset` | (none) | Named combo; `msia` = course + uv + msia. Other flags override |
| `--lms` | `the course LMS` | Substituted as `__LMS__` (org `msia` sets Canvas unless overridden) |
| `--github-org` | empty | Clone URLs; `msia` defaults to `uncg-msia` |
| `--with-pages` | off | HTML study hub + Pages workflow |

Later layers override the same destination: shape → runtime → org → pages.

## What it writes (default)

- `README.md`, `QUICKSTART.md`, `CONTRIBUTING.md`, `AGENTS.md`
- `docs/` stubs (modules, projects, admin README/PLANNING, AI expectations)
- `assignments/`, `lectures/` (empty `_quarto.yml`), `data/public/`
- `.gitignore` (agent trees, restricted data)

Not written unless you opt in: `Containerfile`, `pyproject.toml`, org
`release.yml`, GitHub Pages. Do not pass `symkit --scaffold` on a tree
this tool created.

When nested `symkit` runs: `AGENTS-SYMKIT.md`, pointer on `AGENTS.md`,
`.agents/` (gitignored), grok adapter by default, `docs/slos.md`.

## Path ownership

| Path | Owner |
|:--|:--|
| Course identity and layout | this repo (shape / runtime / org) |
| `docs/slos.md` | `symkit --docs slos` |
| `docs/ai-what-to-expect.md` | this repo (committed student handout; org overlay may replace) |
| `docs/ai/*` | symkit learner pack (copy-if-missing) |
| `.agents/`, adapters, `AGENTS-SYMKIT.md` | symkit |

Do not install `--role instructor` and then `--role learner` on the same
tree. Learner prune strips instructor agents.

## Tests

```bash
cargo +nightly fmt -- --check
cargo test
cargo clippy --all-targets -- -D warnings
./tests/smoke.sh
```

Command notes: [DEVELOPMENT.md](DEVELOPMENT.md).

## License

Apache License 2.0. See [LICENSE](LICENSE) and [NOTICE.md](NOTICE.md).

Copyright (c) 2026, PalEm Dynamics LLC.
