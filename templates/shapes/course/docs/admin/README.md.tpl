# Admin / logistics

Faculty-facing logistics for **__COURSE_CODE__**: credentialing, guest access, tool accounts, and how to obtain a restricted dataset.

Students use the module cards, lecture notes, and assignments. This folder is for the people running the course.

## How this folder is organized

```text
docs/admin/
  README.md
  PLANNING.md
```

Add a short note here when a tool or dataset needs an access step. Name the file for the thing it covers, for example `guest-access.md`.

## How an access note is organized

- What the person needs (account, guest seat, data-use agreement)
- Who approves it
- Where the approved files live, which is outside this repository

## What belongs somewhere else

Published course outcomes live in [`docs/slos.md`](../slos.md) (copied by
`symkit --docs slos`). Do not keep a second SLO list here.

Term counts (how many modules, how many assignments) belong in [`PLANNING.md`](PLANNING.md).

Do **not** put secrets, class rosters, or restricted data here. If a dataset requires a DUA, document *how to get access*, not the data.

## Add the next note

Create a markdown file in this folder for that access step, and link it from [`PLANNING.md`](PLANNING.md) when faculty need it during the term.
