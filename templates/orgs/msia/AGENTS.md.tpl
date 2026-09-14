# AGENTS.md — UNCG ILRS course materials

Instructions for AI coding agents working in **course materials** repositories (faculty/maintainer workflows).

## Mission

Author and maintain graduate course materials for UNCG ILRS / MSIA. Students pull stable materials from **`main`**; **graded work is submitted on Canvas**, not to this repository (unless a course explicitly says otherwise).

## Hard rules

- **Never** commit credentialed extracts, PHI, secrets, or other DUA-restricted data.
- Public, redistributable samples only under paths like `data/public/`. Large extracts stay outside the repo.
- Do not invent course handbook, dates, grading weights, student records, or institutional policy.
- Do not put answer keys or private solutions in student-facing paths without an explicit faculty decision.
- Prefer existing repo conventions (branches, releases, `uv`/container) over inventing new tooling.

## How work ships (typical org pattern)

| Branch / artifact | Role |
|:--|:--|
| `develop` | Day-to-day authoring |
| `main` | Stable, student-facing materials |
| `YYYY.S.m` releases | Tagged materials drops (`S=1` fall, `S=2` spring) |

Ship path: land work on `develop` → merge to `main` → tag `vYYYY.S.m`. Org how-tos: [msia-faculty](https://github.com/uncg-msia/msia-faculty). Student-facing contributing stays short in this repo’s `CONTRIBUTING.md`.

## Agent behavior

- Match existing module cards, lecture notes, and assignment structure before adding new formats.
- Prefer short, accurate, runnable examples over long lectures.
- When unsure whether content is redistributable or student-safe, **ask** before committing.
- Keep changes scoped; do not drive-by reformat unrelated files.

## Related modular rules

If present under `.agents/rules/` (and vendor adapters), also follow:

- `ai-course-policy.md` — **thin agent pointer** to student AI expectations (do not duplicate full policy here)
- `org-course-materials.md` — materials and release norms
- `data-handling.md` — data layout and restricted-data boundaries

**Student-facing AI expectations** (canonical for humans): `docs/ai-what-to-expect.md`
Course-specific student policy deltas belong in course `docs/`, not long prose under `.agents/`.

## Skills

On-demand procedures live under `.agents/skills/` (e.g. `release-materials`). Use them when the task matches their description.
