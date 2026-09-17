#!/usr/bin/env bash
# Copyright (c) 2026, Nathaniel Berry
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
"$CLI" list | grep -q 'shape    course' || fail "list defaults"
"$CLI" list | grep -q 'preset' || true
"$CLI" list | grep -q 'msia' || fail "list msia"

if "$CLI" new smoke-bad "$TMP/bad" >/dev/null 2>&1; then
  fail "new without --course-number/--course-title must fail"
fi
if "$CLI" new smoke-bad "$TMP/bad" --course-number X --course-title Y --shape nope >/dev/null 2>&1; then
  fail "unknown --shape must fail"
fi

# default: generic course, no runtime, no org
T1="$TMP/bio-101"
"$CLI" new bio-101 "$T1" \
  --course-number "BIO 101" \
  --course-title "Intro Biology" \
  --no-agents

[[ -f "$T1/README.md" ]] || fail "README"
[[ -f "$T1/assignments/README.md" ]] || fail "assignments"
[[ -f "$T1/lectures/_quarto.yml" ]] || fail "quarto yml"
[[ -f "$T1/docs/admin/PLANNING.md" ]] || fail "admin PLANNING"
[[ -d "$T1/.git" ]] || fail "git init"
[[ ! -e "$T1/Containerfile" ]] || fail "default runtime none must not write Containerfile"
[[ ! -e "$T1/pyproject.toml" ]] || fail "default must not write pyproject.toml"
[[ ! -e "$T1/docs/admin/SLO.md" ]] || fail "must not write docs/admin/SLO.md"
[[ ! -e "$T1/docs/slos.md" ]] || fail "--no-agents must not write docs/slos.md"
grep -q "BIO 101" "$T1/README.md" || fail "course-number substitution"
grep -q "Intro Biology" "$T1/README.md" || fail "course-title substitution"
grep -q "the course LMS" "$T1/assignments/README.md" || fail "generic LMS wording"
if grep -q "uncg-msia" "$T1/README.md"; then fail "generic README must not mention uncg-msia"; fi
if grep -q "Canvas" "$T1/README.md"; then fail "generic README must not mention Canvas"; fi

echo keep-me >>"$T1/README.md"
"$CLI" new bio-101 "$T1" \
  --course-number "BIO 101" \
  --course-title "Intro Biology" \
  --no-agents
grep -q keep-me "$T1/README.md" || fail "must not clobber README"

# --lms and --github-org on generic shape
T1b="$TMP/bio-lms"
"$CLI" new bio-lms "$T1b" \
  --course-number "BIO 102" \
  --course-title "LMS Override" \
  --lms Moodle \
  --github-org example-edu \
  --no-agents
grep -q "Moodle" "$T1b/assignments/README.md" || fail "--lms Moodle"
grep -q "github.com/example-edu/bio-lms" "$T1b/README.md" || fail "--github-org clone URL"

# uv runtime, still generic org
T_UV="$TMP/stats-uv"
"$CLI" new stats-uv "$T_UV" \
  --course-number "STAT 200" \
  --course-title "Stats" \
  --runtime uv \
  --no-agents
[[ -f "$T_UV/Containerfile" ]] || fail "uv Containerfile"
[[ -f "$T_UV/pyproject.toml" ]] || fail "uv pyproject"
grep -q "SYMKIT_VERSION=0.2.0" "$T_UV/Containerfile" || fail "symkit pin"
grep -q "BEGIN symcourse runtime uv" "$T_UV/.gitignore" || fail "uv gitignore fragment"
if grep -q "uncg-msia" "$T_UV/QUICKSTART.md"; then fail "uv QUICKSTART must not hardcode uncg-msia"; fi
grep -q "the course LMS" "$T_UV/QUICKSTART.md" || fail "uv QUICKSTART uses default LMS"

# pages extra, generic
T2="$TMP/hub-pages"
"$CLI" new hub-pages "$T2" \
  --course-number "HUB 1" \
  --course-title "Pages Course" \
  --with-pages \
  --github-org example-edu \
  --no-agents
[[ -f "$T2/site/index.html" ]] || fail "pages index"
[[ -f "$T2/.github/workflows/pages.yml" ]] || fail "pages workflow"
grep -q "example-edu.github.io/hub-pages" "$T2/site/README.md" || fail "pages URL from github-org"
if grep -q "uncg-msia" "$T2/site/index.html"; then fail "generic pages must not mention uncg-msia"; fi

# MSIA preset (today's IAN shape)
T3="$TMP/ian-6xx"
"$CLI" new ian-6xx "$T3" \
  --preset msia \
  --course-number "IAN 6xx" \
  --course-title "MSIA Course" \
  --no-agents
[[ -f "$T3/Containerfile" ]] || fail "preset msia Containerfile"
[[ -f "$T3/.github/workflows/release.yml" ]] || fail "msia release workflow"
grep -q "uncg-msia" "$T3/README.md" || fail "msia README org"
grep -q "Canvas" "$T3/QUICKSTART.md" || fail "msia QUICKSTART Canvas"
grep -q "msia-faculty" "$T3/CONTRIBUTING.md" || fail "msia faculty docs"

if command -v symkit >/dev/null 2>&1; then
  T4="$TMP/with-agents"
  "$CLI" new with-agents "$T4" \
    --course-number "CS 1" \
    --course-title "Agents Course"
  [[ -f "$T4/docs/slos.md" ]] || fail "nested --docs slos"
  [[ ! -e "$T4/docs/admin/SLO.md" ]] || fail "still no admin SLO"
  [[ -f "$T4/AGENTS-SYMKIT.md" ]] || fail "AGENTS-SYMKIT.md from nested install"
  grep -q AGENTS-SYMKIT.md "$T4/AGENTS.md" || fail "pointer on AGENTS.md"
  [[ ! -e "$T4/Containerfile" ]] || fail "nested install must not add Containerfile"
else
  printf 'note: symkit not on PATH; skipped nested-install checks\n'
fi

printf 'OK\n'
