# Modules

**__COURSE_CODE__ — __COURSE_TITLE__**

**Grading criteria and weights: __LMS__ only.** This repo describes materials
and *what to do*; submit work on **__LMS__** unless otherwise instructed.

Each module is a pair of files. The session card is how the meeting runs. The lecture notes are what to study.

## How this folder is organized

```text
docs/modules/
  README.md
  module-00.md
  module-01.md
```

`module-NN.md` uses a zero-padded number. The lecture notes for that module live at `lectures/module-NN/notes.md`.

| Artifact | Path | Role |
|:--|:--|:--|
| **Session card** | `docs/modules/module-NN.md` | Live meeting design |
| **Lecture notes** | `lectures/module-NN/notes.md` | Content notes |

## How a session card is organized

- Purpose of the meeting
- Learning objectives for this session
- Timed sketch
- What to prepare
- What you leave with
- Materials used (lecture notes, public data, assignment)

When [`docs/slos.md`](../slos.md) exists, the objectives on the card stay aligned with that list. Do not put calendar due dates in these files. The term calendar is on **__LMS__**.

## What belongs somewhere else

Lecture prose and slides go in [`lectures/`](../../lectures/). Assignment prompts go in [`assignments/`](../../assignments/). Point values stay on **__LMS__**.

## Add the next module

1. Create `docs/modules/module-NN.md` with the sections above.
2. Create `lectures/module-NN/notes.md`.
3. Add a row to the index in [`lectures/README.md`](../../lectures/README.md).
