# symcourse

Scaffold a **course repository**: layout, runtime, and identity.

Agent packs (instructor/TA/learner trees, `docs/slos.md`, adapters) come from
[csymd/symkit](https://github.com/csymd/symkit). The usual path is **one
command**: `symcourse new` writes the course tree, then runs `symkit install`
(no `--scaffold`). Kit-only teaching stubs (`symkit init --scaffold`) are the
smaller case.

The default is **course- and university-agnostic**. UNCG MSIA / IAN is an
optional overlay (`--preset msia`), not the product.

## How this relates to symkit

| Tool | Job |
|:--|:--|
| **symcourse** | Course shape: folders, identity, optional uv/Containerfile |
| **symkit** | Agent harness: packs, skills, adapters, `docs/slos.md` |

```bash
# Usual: layout + instructor packs + slos blank
./cli/symcourse new bio-101 \
  --course-number "BIO 101" \
  --course-title "Intro Biology" \
  --symkit /path/to/symkit          # binary, or a checkout (uses cli/symkit)

# Same if `symkit` is on PATH, $SYMKIT is set, or ../symkit is a sibling clone
./cli/symcourse new bio-101 \
  --course-number "BIO 101" \
  --course-title "Intro Biology"
```

That nested install is:

```bash
symkit install <outdir> --harness teaching --role instructor --docs slos --yes
```

Do not pass `--scaffold` on a tree this tool created. `--no-agents` skips the
nested install (layout only). If symkit is missing and you did not pass
`--no-agents`, the course tree is still written and the install command is
printed.

## Quick start

```bash
./cli/symcourse list

# any course (no container, LMS-neutral) + nested symkit
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

# layout only
./cli/symcourse new bio-101 \
  --course-number "BIO 101" \
  --course-title "Intro Biology" \
  --no-agents
```

`--course-number` and `--course-title` are required (`--code` and `--title`
are aliases). Existing files are skipped.

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
| `--migration-docs` | on (TTY asks) | Local `migration-docs/` for PDF/Word import; dumps gitignored |
| `--no-migration-docs` | | Skip that dir |
| `--symkit` | PATH / `$SYMKIT` / `../symkit` | Nested installer |
| `--no-agents` | off | Skip nested `symkit install` |
| `--adapters` | (symkit default: grok) | Passed through to nested install |

Later layers override the same destination: shape → runtime → org → pages.

## What it writes (default)

- `README.md`, `QUICKSTART.md`, `CONTRIBUTING.md`, `AGENTS.md`
- `docs/` stubs (modules, projects, admin README/PLANNING, AI expectations, `docs/slos.md` with course code/title)
- `assignments/`, `lectures/` (empty `_quarto.yml`), `data/public/`
- `.gitignore` (agent trees, restricted data)

Not written unless you opt in: `Containerfile`, `pyproject.toml`, org
`release.yml`, GitHub Pages.

When nested `symkit` runs: `AGENTS-SYMKIT.md`, pointer on `AGENTS.md`,
`.agents/` (gitignored), grok adapter by default, `docs/slos.md`.

`migration-docs/` (default) is for local PDF/Word dumps; convert with
`migrate-course`. Git ignores the dumps, not `migration-docs/README.md`.

## Path ownership

| Path | Owner |
|:--|:--|
| Course identity and layout | this repo (shape / runtime / org) |
| `docs/slos.md` | **this repo** (course code + title filled in). `symkit --docs slos` copies a blank only if the file is missing |
| `docs/ai-what-to-expect.md` | this repo (committed student handout; org overlay may replace) |
| `docs/ai/*` | symkit learner pack (copy-if-missing) |
| `.agents/`, adapters, `AGENTS-SYMKIT.md` | symkit |

Do not install `--role instructor` and then `--role learner` on the same
tree. Learner prune strips instructor agents.

## Tests

```bash
./tests/smoke.sh
```

## License

Apache License 2.0. See [LICENSE](LICENSE) and [NOTICE.md](NOTICE.md).

Copyright (c) 2026, PalEm Dynamics LLC.
