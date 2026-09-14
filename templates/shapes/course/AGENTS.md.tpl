# AGENTS.md — course materials

Instructions for AI coding agents working in **course materials** repositories
(faculty and maintainer workflows).

## Mission

Author and maintain course materials. Students pull stable materials from the
published branch (`main` unless the repo says otherwise). Graded work is
submitted on **__LMS__**, not to this repository, unless the course explicitly
says otherwise.

## Source of course truth

1. Syllabus / __LMS__ for the term
2. Course SLOs when present (`docs/slos.md` or `documents/slos.md`)
3. Module cards and assignment objectives (must not contradict 1–2)
4. The instructor of record

**Do not invent** learning outcomes, syllabus dates, grading weights, student
records, or institutional policy. If the SLO file is missing or still
placeholder, ask.

## Hard rules

- **Never** commit credentialed, DUA-restricted, clinical, or personally
  identifiable data.
- Public, redistributable samples only under paths like `data/public/`.
- Do not invent syllabus dates, grading weights, student records, or
  institutional policy.
- Do not put answer keys or private solutions in student-facing paths without
  an explicit faculty decision.
- Prefer existing repo conventions over inventing new tooling.

## How work ships (typical)

| Branch / artifact | Role |
|:------------------|:-----|
| `develop` | Day-to-day authoring |
| `main` | Stable, student-facing materials |
| Tagged releases | Materials drops (scheme is course-defined) |

Follow the course `CONTRIBUTING.md` when present.

## Agent behavior

- Match existing module cards, lecture notes, and assignment structure before
  adding new formats.
- Prefer short, accurate, runnable examples over long lectures.
- When unsure whether content is redistributable or student-safe, **ask**
  before committing.
- Keep changes scoped; do not drive-by reformat unrelated files.

## Related modular rules

If present under `.agents/rules/` (and vendor adapters), also follow:

- `ai-course-policy.md` — thin pointer to `docs/ai-what-to-expect.md`
- `course-materials.md` — materials, what to commit, release norms
- `slos-as-truth.md` — published course outcomes; do not invent SLOs
- `data-handling.md` — data layout and restricted-data boundaries

Student-facing AI expectations: `docs/ai-what-to-expect.md`.
Course-specific policy deltas belong in course `docs/`, not long prose under
`.agents/`.

## Skills

On-demand procedures live under `.agents/skills/` (e.g. `release-materials`).
Use them when the task matches their description.
