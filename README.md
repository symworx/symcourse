# symcourse

Scaffold a **course repository**: layout, runtime, and identity. Agent
packs come from [symworx/symkit](https://github.com/symworx/symkit).

The default is **course- and university-agnostic**. UNCG MSIA / IAN is an
optional overlay (`--preset msia`), not the product.

## Install

From a clone, `./cli/symcourse` builds the debug binary and runs it. In this checkout the binary reads `catalog.yaml` and `templates/` from the tree.

From this directory, install the binary locally:

```bash
cargo install --locked --path .
```

A published tag installs the same binary. The catalog and templates are embedded at compile time:

```bash
cargo install --locked symcourse
```

`cargo install --locked symcourse` installs the published crate (`v0.1.0` is on crates.io). Later versions publish when a `v*` tag is pushed. Pull requests go to `worx`. See [CONTRIBUTING.md](CONTRIBUTING.md) and [DEVELOPMENT.md](DEVELOPMENT.md#releasing).

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

# same MSIA pack, and only course numbers listed in the department file
./cli/symcourse departments
./cli/symcourse create department
./cli/symcourse edit department
./cli/symcourse new ian-6xx . \
  --course-number "IAN 6xx" \
  --course-title "Course title" \
  --department department.yml

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

`new` writes `migration-docs/README.md` and `migration-docs/.gitkeep`.
Files dropped there stay on this machine. Back them up elsewhere. To track
one file, add its path on its own line in `.gitkeep` and run `new` again.
`--no-migration-docs` skips creating the directory and skips refreshing
those exceptions. It does not delete an existing `migration-docs/`.
The nested `symkit` install is not passed this flag.

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
| `--no-migration-docs` | off | Skip `migration-docs/`. Do not refresh `.gitkeep` exceptions |
| `--department` | (none) | Department file. Checks course numbers. Fills empty org, runtime, LMS, and GitHub org |

Later layers override the same destination: shape → runtime → org → pages.

`symcourse departments` is the menu for `./department.yml`. In a terminal, the
arrow keys move between `new`, `edit`, `delete`, and `quit`. Enter selects.
`q` or Ctrl-C quits. `new` writes the file, and delete asks again before
removing it. Without a terminal it prints the shortcuts, then exits:

```bash
symcourse create department [file]
symcourse edit department [file]
symcourse delete department [file]
```

`create department` is the shortcut for `new`. It writes `department.yml` in
the current directory, or at `file`. It does not replace a file that is
already there. `edit department` opens the file in `$VISUAL` or `$EDITOR`.
`delete department` removes that file. None of them change the stock template
in this checkout. `symcourse new` scaffolds the course and reads this file
through `--department`.

The stock file is MSIA: `org: msia`, `runtime: uv`, and the course-number
prefix `ian` (`ian-6xx`, `IAN 6xx`). Edit `slug`, `name`, and
`course_numbers` for another department. Clear `org` and `runtime` when that
department should keep the generic templates. `--org`, `--runtime`,
`--preset`, `--lms`, and `--github-org` win when you pass them. The course
name and `--course-number` must share one prefix from the file.

## What it writes (default)

- `README.md`, `QUICKSTART.md`, `CONTRIBUTING.md`, `AGENTS.md`
- `docs/` stubs (modules, projects, admin README/PLANNING, AI expectations)
- `assignments/`, `lectures/` (empty `_quarto.yml`), `data/public/`
- `migration-docs/` (local legacy files; dumps stay gitignored)
- `.gitignore` (agent trees, restricted data, `migration-docs/`)

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

Copyright (c) 2026, Nathaniel T. Berry.
