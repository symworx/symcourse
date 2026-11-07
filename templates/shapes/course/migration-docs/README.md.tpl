# migration-docs

This directory lives only on this machine. Back it up somewhere else. Git does not store the files you drop here.

Drop a legacy PDF or Word file in this folder. After you convert it, put the markdown in the course tree.

| Dump | Lands in |
|:-----|:---------|
| Syllabus, handbook, policy | `docs/` |
| A lecture | `lectures/` |
| An assignment or lab prompt | `assignments/` |

The converted markdown is the record. This tool does not convert the file. Use the instructor skill `migrate-course` when it is installed.

To track a file from this directory, add its path on its own line in [`.gitkeep`](.gitkeep), then run `symcourse new` again. Leave restricted extracts, answer keys, and student records untracked.
