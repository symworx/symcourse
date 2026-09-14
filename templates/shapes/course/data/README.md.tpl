# Data

- Store **only public, redistributable sample files** here (tiny CSVs, synthetic examples).
- **Never commit** PHI, credentialed extracts, student records, or other restricted data.
- Large local extracts: keep outside the repo and document paths in notes, not in git.

Suggested layout:

```text
data/public/
  README.md
  …sample files…
data/private/    # gitignored; local only if you must
```
