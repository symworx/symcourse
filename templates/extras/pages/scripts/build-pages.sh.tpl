#!/usr/bin/env bash
# Build static GitHub Pages output from site/ into _site/.
# Rewrites ../docs|lectures|assignments links to GitHub blob URLs (markdown is not rendered on Pages).
# If lectures/_built/ exists (quarto render), merge it to _site/lectures/.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="${ROOT}/site"
OUT="${ROOT}/_site"
LECTURES_BUILT="${ROOT}/lectures/_built"

REPO="${GITHUB_REPOSITORY:-__GITHUB_REPOSITORY_DEFAULT__}"
BRANCH="${PAGES_BLOB_BRANCH:-${GITHUB_REF_NAME:-}}"
if [[ -z "${BRANCH}" ]]; then
  BRANCH="$(git -C "${ROOT}" symbolic-ref --short HEAD 2>/dev/null || true)"
fi
if [[ -z "${BRANCH}" || "${BRANCH}" == "HEAD" || "${BRANCH}" == *'/'* ]]; then
  BRANCH="worx"
fi
BLOB_BASE="https://github.com/${REPO}/blob/${BRANCH}"

if [[ ! -d "${SRC}" ]]; then
  echo "error: missing ${SRC}" >&2
  exit 1
fi

rm -rf "${OUT}"
mkdir -p "${OUT}"
cp -a "${SRC}/." "${OUT}/"

touch "${OUT}/.nojekyll"

if [[ -d "${LECTURES_BUILT}" ]]; then
  mkdir -p "${OUT}/lectures"
  cp -a "${LECTURES_BUILT}/." "${OUT}/lectures/"
  echo "  lectures: merged ${LECTURES_BUILT} → ${OUT}/lectures"
else
  echo "  lectures: skip (no ${LECTURES_BUILT}; render with quarto first)"
fi

while IFS= read -r -d '' f; do
  tmp="${f}.tmp"
  sed \
    -e "s|href=\"../../docs/|href=\"${BLOB_BASE}/docs/|g" \
    -e "s|href=\"../docs/|href=\"${BLOB_BASE}/docs/|g" \
    -e "s|href=\"../../lectures/|href=\"${BLOB_BASE}/lectures/|g" \
    -e "s|href=\"../lectures/|href=\"${BLOB_BASE}/lectures/|g" \
    -e "s|href=\"../../assignments/|href=\"${BLOB_BASE}/assignments/|g" \
    -e "s|href=\"../assignments/|href=\"${BLOB_BASE}/assignments/|g" \
    "${f}" > "${tmp}"
  mv "${tmp}" "${f}"
done < <(find "${OUT}" -type f -name '*.html' -print0)

{
  echo "built: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "repo: ${REPO}"
  echo "blob_branch: ${BRANCH}"
} > "${OUT}/.build-stamp.txt"

echo "Pages build ready at ${OUT}"
echo "  blob base: ${BLOB_BASE}"
