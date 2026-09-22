# Contributing

GitHub Flow (**SymWorx org standard**). The default branch is **`worx`**. Open pull requests against **`worx`**.

```text
feature/*  ──PR──►  worx  ──tag──►  vX.Y.Z
                 day-to-day CI         publish on tag
```

| Branch | Role |
|:-------|:-----|
| `worx` | Default. Open feature pull requests here. Keep it releasable. |
| `feature/*` (or `fix/*`, `docs/*`, `chore/*`) | Short-lived work |
| `release/vX.Y.Z` | Optional freeze when a release needs soak or last-minute fixes |

Do not force-push `worx`.

## Opening a pull request

1. Fork the repository, or use a branch if you have write access, and clone.
2. Branch from **`worx`** (`git checkout -b feat/your-feature-name`).
3. Keep the change focused. Include tests when behavior changes.
4. Push and open a pull request against **`worx`**.
5. Stay engaged with review comments.

Build and test commands are in [DEVELOPMENT.md](DEVELOPMENT.md).

AI-assisted contributions are fine. You remain responsible for the result: explain the change, meet the quality bar, and own the code after merge.

## This repository

`symcourse` scaffolds course shape (layout, runtime, identity overlays). Agent packs, adapters, and `docs/slos.md` come from the org agent-harness installer (`symkit`). Do not pass `--scaffold` to `symkit` on a tree this tool created.

`catalog.yaml` lists shapes, runtimes, orgs, and presets. Add a new org by dropping identity templates under `templates/orgs/<id>/` and registering them in the catalog. Do not hardcode new ids in the scaffolder (`src/`).

```bash
./cli/symcourse list
./cli/symcourse new bio-101 \
  --course-number "BIO 101" \
  --course-title "Intro Biology" \
  --no-agents
./tests/smoke.sh
```

Keep course `AGENTS.md` templates short. Do not commit secrets, credentials, or restricted data.

## Releasing

A release is a version bump and a changelog entry on `worx`, then a manual tag `vX.Y.Z`. Publish runs on that tag, not on every merge to `worx`.

```bash
./scripts/bump-version.sh patch --changelog
```

Details: [DEVELOPMENT.md](DEVELOPMENT.md#releasing).

## Conduct

[Contributor Covenant v2.1](https://www.contributor-covenant.org/version/2/1/code_of_conduct/).
