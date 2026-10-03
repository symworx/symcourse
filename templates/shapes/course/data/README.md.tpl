# Data

Public, redistributable sample files for **__COURSE_CODE__**. Students open these files with the assignment that names them.

## How this folder is organized

```text
data/
  README.md
  public/
    sample.csv
  private/          # gitignored; local only if you must
```

- Store **only public, redistributable sample files** under `data/public/` (tiny CSVs, synthetic examples).
- **Never commit** PHI, credentialed extracts, student records, or other restricted data.
- Large local extracts stay outside the repo.

## How a sample is recorded

Each sample is a small file in `data/public/` plus a line in the list below. The line names the file and what a reader is allowed to redistribute.

| File | What it is |
|:--|:--|
| `data/public/…` | Add one row per sample as you add the file |

## What belongs somewhere else

Restricted extracts stay outside the repository. Document how to obtain them in [`docs/admin/`](../docs/admin/), not the bytes. Assignment instructions that use a sample live in [`assignments/`](../assignments/).

## Add the next sample

Put the file in `data/public/` and add a row to the table above.
