# Contributing

Author on `develop`. This repository is private.

`symcourse` scaffolds **course shape** (layout, runtime, identity). Agent
packs, adapters, and `docs/slos.md` come from
[csymd/symkit](https://github.com/csymd/symkit). Do not pass `--scaffold`
to `symkit` on a tree this tool created.

```bash
./cli/symcourse new ian-6xx \
  --course-number "IAN 6xx" \
  --course-title "Course title"
./tests/smoke.sh
```

Keep package `AGENTS.md` templates short. Do not commit secrets, credentials,
or restricted data.
