# Assignments

This folder holds *what to do* for **__COURSE_CODE__**.
**Grading criteria, weights, and point values are on __LMS__ only**—not in these files.

**Hand-in:** submit each deliverable on **__LMS__**. Use this repo for materials,
sample data, and local drafting—not for graded submission (unless the
instructor says otherwise).

**No hard due dates in these files.** Suggested windows, milestone gates, and
how work is graded stay on **__LMS__**.

## How this folder is organized

You may take a flat directory stucture or nested structure based on you preference. The flat structure may look like: 

```text
assignments/
  README.md
  lab-01.md
  homework-01.md
```
Alternatively, subdirectories (recommended) may be formatted similar to:

```text
assignments/
  checkponts/     # Discussion board posts or worksheets
    module-01.md
  labs/           # Lab documents and instuctions (no data)
    lab-00.md
    lab-01.md
  project/        # Project materials/documents
    midterm.md
    final.md
```

`lab-NN.md` is a lab. `homework-NN.md` is a homework. `NN` is a zero-padded number. Use the name that matches the kind of work.

## How an assignment file is organized

- What you will do
- What you turn in
- Starter files, including paths under `data/public/`
- Related module (`docs/modules/module-NN.md`)

## What belongs somewhere else

Session plans go in [`docs/modules/`](../docs/modules/). Lecture notes go in [`lectures/`](../lectures/). Sample files go in [`data/public/`](../data/public/). Weights and due dates stay on **__LMS__**.

## Add the next assignment

Create `assignments/lab-NN.md` or `assignments/homework-NN.md` with the sections above, and name that file from the related module card.
