# Contributing

Author on `develop`.

`symcourse` scaffolds **course shape** (layout, runtime, identity overlays).
Agent packs, adapters, and `docs/slos.md` come from
[symworx/symkit](https://github.com/symworx/symkit). Do not pass `--scaffold`
to `symkit` on a tree this tool created.

`catalog.yaml` lists shapes, runtimes, orgs, and presets. Add a new org by
dropping identity templates under `templates/orgs/<id>/` and registering
them in the catalog. Do not hardcode new ids in `makecourse.sh`.

```bash
./cli/symcourse list
./cli/symcourse new bio-101 \
  --course-number "BIO 101" \
  --course-title "Intro Biology" \
  --no-agents
./tests/smoke.sh
```

Keep course `AGENTS.md` templates short. Do not commit secrets, credentials,
or restricted data.
