#!/usr/bin/env bash
# Copyright (c) 2026, PalEm Dynamics LLC
# Licensed under the Apache License, Version 2.0.

# Integration gate for ./cli/symcourse new
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CLI="$ROOT/cli/symcourse"
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

[[ -x "$CLI" ]] || fail "cli/symcourse is not executable"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

"$CLI" help >/dev/null
"$CLI" -h >/dev/null

# missing required flags
if "$CLI" new smoke-bad "$TMP/bad" >/dev/null 2>&1; then
  fail "new without --course-number/--course-title must fail"
fi

T1="$TMP/ian-smoke"
"$CLI" new ian-smoke "$T1" \
  --course-number "IAN 000" \
  --course-title "Smoke Course" \
  --no-agents

[[ -f "$T1/README.md" ]] || fail "README"
[[ -f "$T1/Containerfile" ]] || fail "Containerfile"
[[ -f "$T1/docs/admin/PLANNING.md" ]] || fail "admin PLANNING"
[[ -f "$T1/docs/ai-what-to-expect.md" ]] || fail "AI policy handout"
[[ -f "$T1/assignments/README.md" ]] || fail "assignments"
[[ -f "$T1/lectures/_quarto.yml" ]] || fail "quarto yml"
[[ -d "$T1/.git" ]] || fail "git init"
[[ ! -e "$T1/docs/admin/SLO.md" ]] || fail "must not write docs/admin/SLO.md"
[[ ! -e "$T1/docs/slos.md" ]] || fail "--no-agents must not write docs/slos.md"
grep -q "IAN 000" "$T1/README.md" || fail "course-number substitution"
grep -q "Smoke Course" "$T1/README.md" || fail "course-title substitution"
grep -q "SYMKIT_VERSION=0.2.0" "$T1/Containerfile" || fail "symkit pin"

# copy-if-missing
echo keep-me >>"$T1/README.md"
"$CLI" new ian-smoke "$T1" \
  --course-number "IAN 000" \
  --course-title "Smoke Course" \
  --no-agents
grep -q keep-me "$T1/README.md" || fail "must not clobber README"

# --with-pages
T2="$TMP/ian-pages"
"$CLI" new ian-pages "$T2" \
  --course-number "IAN 001" \
  --course-title "Pages Course" \
  --with-pages \
  --no-agents
[[ -f "$T2/site/index.html" ]] || fail "pages index"
[[ -f "$T2/.github/workflows/pages.yml" ]] || fail "pages workflow"

if command -v symkit >/dev/null 2>&1; then
  T3="$TMP/ian-agents"
  "$CLI" new ian-agents "$T3" \
    --course-number "IAN 002" \
    --course-title "Agents Course"
  [[ -f "$T3/docs/slos.md" ]] || fail "nested --docs slos"
  [[ ! -e "$T3/docs/admin/SLO.md" ]] || fail "still no admin SLO"
  [[ -f "$T3/AGENTS-SYMKIT.md" ]] || fail "AGENTS-SYMKIT.md from nested install"
  grep -q AGENTS-SYMKIT.md "$T3/AGENTS.md" || fail "pointer on AGENTS.md"
else
  printf 'note: symkit not on PATH; skipped nested-install checks\n'
fi

printf 'OK\n'
