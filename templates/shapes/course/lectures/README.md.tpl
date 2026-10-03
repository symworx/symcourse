# Lectures

Lecture notes and optional slides for **__COURSE_CODE__**. Each module has its own directory. Open the matching session card in [`docs/modules/`](../docs/modules/) for how that meeting runs. These notes are what to study.

Dates for the term stay on **__LMS__**.

## How this folder is organized

```text
lectures/
  README.md
  _quarto.yml
  module-00/
    notes.md
    index.qmd          # optional slides
  module-01/
    notes.md
```

`module-NN` uses a zero-padded number and matches `docs/modules/module-NN.md`. `notes.md` is the reading. `index.qmd` is optional Quarto slides. `_quarto.yml` is the local render project. Rendered HTML goes to `lectures/_built/` and is gitignored.

## How a notes file is organized

- Title and the module it belongs to
- Concepts and worked examples for that meeting
- Materials used: the assignment path and any files under `data/public/`

## Module index

Replace the example row when that module exists. Add one row per module.

| Module | Topic | Notes | Slides |
|:--|:--|:--|:--|
| `module-00` | Example topic. Replace this row. | `lectures/module-00/notes.md` | optional |

## Slides

One Quarto source per module: `lectures/module-NN/index.qmd`. Add that path to `render:` in `_quarto.yml`, then:

```bash
cd lectures && quarto render
```

## Add the next module

1. Create `lectures/module-NN/notes.md`.
2. Create `docs/modules/module-NN.md` for the session card.
3. Add a row to the index above.
4. Add `index.qmd` only when the module has slides, and list it in `_quarto.yml`.
