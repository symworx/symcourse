# Assignments

This folder holds *what to do* for **__COURSE_CODE__**.
**Grading criteria, weights, and point values are on __LMS__ only**—not in these files.

**Hand-in:** submit each deliverable on **__LMS__**. Use this repo for materials,
sample data, and local drafting—not for graded submission (unless the
instructor says otherwise).

**No hard due dates in these files.** Suggested windows, milestone gates, and
how work is graded stay on **__LMS__**.

## How this folder is organized

Use one directory per kind of work:

```text
assignments/
  README.md
  checkpoints/          # discussion posts or worksheets
    module-00.md
  labs/                 # lab instructions (no data)
    lab-00.md
    lab-01.md
  project/              # midterm, final, and other project briefs
    README.md
    midterm.md
    final.md
```

`module-NN.md` matches the session card `docs/modules/module-NN.md`. `lab-NN.md` is a lab. `NN` is a zero-padded number (`00`, `01`, `02`). Project briefs live in [`project/`](project/).

A flat layout still works when the course has only a few files:

```text
assignments/
  README.md
  lab-01.md
  homework-01.md
```

## How an assignment file is organized

- What you will do
- What you turn in
- Starter files, including paths under `data/public/`
- Related module (`docs/modules/module-NN.md`)

## What belongs somewhere else

Session plans go in [`docs/modules/`](../docs/modules/). Lecture notes go in [`lectures/`](../lectures/). Sample files go in [`data/public/`](../data/public/). Weights and due dates stay on **__LMS__**.

## Add the next assignment

- Checkpoint: `assignments/checkpoints/module-NN.md`
- Lab: `assignments/labs/lab-NN.md`
- Project: a file under [`assignments/project/`](project/), as that README describes

Use the sections above. When the work belongs to one module, use that module number in the file name.
