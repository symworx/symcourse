#!/usr/bin/env python3
#
# Copyright (c) 2026, PalEm Dynamics LLC
# Licensed under the Apache License, Version 2.0.
#
"""Load catalog.yaml and resolve shape / runtime / org / extras into a file list.

YAML subset: comments, 2-space indent, mappings, lists of scalars or mappings.
No anchors, tags, or multiline scalars.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any


def parse_yaml(text: str) -> Any:
    lines: list[tuple[int, str]] = []
    for raw in text.splitlines():
        stripped = raw.strip()
        if not stripped or stripped.startswith("#"):
            continue
        indent = len(raw) - len(raw.lstrip(" "))
        line = raw.strip()
        if " #" in line and not _is_quoted(line):
            line = line.split(" #", 1)[0].rstrip()
        lines.append((indent, line))
    value, _ = _parse_block(lines, 0, 0)
    return value


def _is_quoted(line: str) -> bool:
    s = line.lstrip("- ").lstrip()
    return s.startswith('"') or s.startswith("'")


def _parse_block(lines: list[tuple[int, str]], i: int, indent: int) -> tuple[Any, int]:
    if i >= len(lines):
        return {}, i
    _, first = lines[i]
    if first.startswith("- "):
        return _parse_list(lines, i, indent)
    return _parse_map(lines, i, indent)


def _parse_map(lines: list[tuple[int, str]], i: int, indent: int) -> tuple[dict[str, Any], int]:
    out: dict[str, Any] = {}
    while i < len(lines):
        ind, line = lines[i]
        if ind < indent:
            break
        if ind > indent:
            raise ValueError(f"bad indent at {line!r}")
        if line.startswith("- "):
            raise ValueError(f"list item where mapping expected: {line!r}")
        key, colon, rest = line.partition(":")
        if not colon:
            raise ValueError(f"expected key: {line!r}")
        key = key.strip()
        rest = rest.strip()
        i += 1
        if rest == "":
            if i < len(lines) and lines[i][0] > indent:
                val, i = _parse_block(lines, i, lines[i][0])
            else:
                val = {}
        else:
            val = _parse_scalar(rest)
        out[key] = val
    return out, i


def _parse_list(lines: list[tuple[int, str]], i: int, indent: int) -> tuple[list[Any], int]:
    out: list[Any] = []
    while i < len(lines):
        ind, line = lines[i]
        if ind < indent:
            break
        if ind > indent:
            raise ValueError(f"bad indent at {line!r}")
        if not line.startswith("- "):
            break
        item = line[2:].strip()
        i += 1
        if item == "":
            if i < len(lines) and lines[i][0] > indent:
                val, i = _parse_block(lines, i, lines[i][0])
            else:
                val = None
        elif ":" in item and not item.startswith(("'", '"')):
            key, _, rest = item.partition(":")
            val = {key.strip(): _parse_scalar(rest.strip()) if rest.strip() else {}}
            while i < len(lines) and lines[i][0] > indent:
                nested, i = _parse_map(lines, i, lines[i][0])
                val.update(nested)
                break
        else:
            val = _parse_scalar(item)
        out.append(val)
    return out, i


def _parse_scalar(text: str) -> Any:
    if text == "" or text in ("null", "~"):
        return None
    if text in ("true", "True"):
        return True
    if text in ("false", "False"):
        return False
    if (text.startswith('"') and text.endswith('"')) or (
        text.startswith("'") and text.endswith("'")
    ):
        return text[1:-1]
    if text.isdigit() or (text.startswith("-") and text[1:].isdigit()):
        return int(text)
    return text


def load_catalog(path: Path) -> dict[str, Any]:
    data = parse_yaml(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        raise ValueError("catalog.yaml must be a mapping")
    return data


def _ids(section: dict[str, Any] | None) -> list[str]:
    if not section:
        return []
    return list(section.keys())


def apply_preset(
    catalog: dict[str, Any],
    *,
    preset: str,
    shape: str,
    runtime: str,
    org: str,
) -> tuple[str, str, str]:
    defaults = catalog.get("defaults") or {}
    if preset:
        presets = catalog.get("presets") or {}
        if preset not in presets:
            known = ", ".join(_ids(presets)) or "(none)"
            raise SystemExit(f"error: unknown --preset {preset!r} (known: {known})")
        spec = presets[preset] or {}
        shape = shape or spec.get("shape") or ""
        runtime = runtime or spec.get("runtime") or ""
        org = org or spec.get("org") or ""
    shape = shape or defaults.get("shape") or "course"
    runtime = runtime or defaults.get("runtime") or "none"
    org = org or defaults.get("org") or "none"
    return shape, runtime, org


def _require(section: dict[str, Any], kind: str, ident: str) -> dict[str, Any]:
    if ident not in section:
        known = ", ".join(section.keys()) or "(none)"
        raise SystemExit(f"error: unknown --{kind} {ident!r} (known: {known})")
    return section[ident] or {}


def _merge_files(layers: list[dict[str, Any]]) -> tuple[list[str], list[dict[str, str]]]:
    dirs: list[str] = []
    seen_dirs: set[str] = set()
    by_dest: dict[str, dict[str, str]] = {}
    for layer in layers:
        for d in layer.get("dirs") or []:
            if d not in seen_dirs:
                seen_dirs.add(d)
                dirs.append(d)
        for item in layer.get("files") or []:
            dest = item["dest"]
            by_dest[dest] = {
                "kind": "file",
                "src": item["src"],
                "dest": dest,
            }
        for item in layer.get("copies") or []:
            dest = item["dest"]
            by_dest[dest] = {
                "kind": "copy",
                "src": item["src"],
                "dest": dest,
                "mode": item.get("mode") or "",
            }
        frag = layer.get("gitignore_append")
        if frag:
            by_dest[f"__append__:{frag}"] = {
                "kind": "append",
                "src": frag,
                "dest": ".gitignore",
            }
        for keep in layer.get("keep") or []:
            by_dest[keep] = {"kind": "keep", "dest": keep}
    return dirs, list(by_dest.values())


def resolve(
    catalog: dict[str, Any],
    *,
    shape: str,
    runtime: str,
    org: str,
    pages: bool,
    migration_docs: bool,
    lms: str,
    github_org: str,
    course_name: str,
) -> dict[str, Any]:
    shapes = catalog.get("shapes") or {}
    runtimes = catalog.get("runtimes") or {}
    orgs = catalog.get("orgs") or {}
    extras = catalog.get("extras") or {}
    defaults = catalog.get("defaults") or {}

    shape_spec = _require(shapes, "shape", shape)
    runtime_spec = _require(runtimes, "runtime", runtime)
    org_spec = _require(orgs, "org", org)

    layers = [shape_spec, runtime_spec, org_spec]
    if pages:
        layers.append(_require(extras, "extra", "pages"))
    if migration_docs:
        layers.append(_require(extras, "extra", "migration_docs"))

    dirs, items = _merge_files(layers)

    vars_: dict[str, str] = {}
    default_lms = str(defaults.get("lms") or "the course LMS")
    vars_["LMS"] = lms or str((org_spec.get("vars") or {}).get("LMS") or default_lms)
    org_github = str((org_spec.get("vars") or {}).get("GITHUB_ORG") or "")
    vars_["GITHUB_ORG"] = github_org or org_github
    for key, value in (org_spec.get("vars") or {}).items():
        if key in ("LMS", "GITHUB_ORG"):
            continue
        vars_[str(key)] = "" if value is None else str(value)

    ghorg = vars_["GITHUB_ORG"]
    if ghorg:
        vars_["CLONE_SNIPPET"] = f"git clone https://github.com/{ghorg}/{course_name}.git"
        vars_["REPO_WEB"] = f"https://github.com/{ghorg}/{course_name}"
        host = vars_.get("GITHUB_PAGES_HOST") or f"{ghorg}.github.io"
        vars_["PAGES_URL"] = f"https://{host}/{course_name}/"
        vars_["GITHUB_REPOSITORY_DEFAULT"] = f"{ghorg}/{course_name}"
    else:
        vars_["CLONE_SNIPPET"] = "git clone <repository-url>"
        vars_["REPO_WEB"] = "the course repository"
        vars_["PAGES_URL"] = "(GitHub Pages URL once enabled)"
        vars_["GITHUB_REPOSITORY_DEFAULT"] = f"YOUR_ORG/{course_name}"
        vars_.setdefault("GITHUB_PAGES_HOST", "")
    vars_.setdefault("FACULTY_DOCS", "")
    vars_.setdefault("GITHUB_PAGES_HOST", vars_.get("GITHUB_PAGES_HOST", ""))

    return {
        "shape": shape,
        "runtime": runtime,
        "org": org,
        "pages": pages,
        "migration_docs": migration_docs,
        "dirs": dirs,
        "items": items,
        "vars": vars_,
    }


def format_list(catalog: dict[str, Any]) -> str:
    lines = [
        f"{catalog.get('kit', {}).get('name', 'symcourse')} catalog",
        "",
        "Defaults:",
        f"  shape    {catalog.get('defaults', {}).get('shape')}",
        f"  runtime  {catalog.get('defaults', {}).get('runtime')}",
        f"  org      {catalog.get('defaults', {}).get('org')}",
        "",
        "Shapes:",
    ]
    for name, spec in (catalog.get("shapes") or {}).items():
        lines.append(f"  {name:12} {(spec or {}).get('description', '')}")
    lines += ["", "Runtimes:"]
    for name, spec in (catalog.get("runtimes") or {}).items():
        lines.append(f"  {name:12} {(spec or {}).get('description', '')}")
    lines += ["", "Orgs:"]
    for name, spec in (catalog.get("orgs") or {}).items():
        lines.append(f"  {name:12} {(spec or {}).get('description', '')}")
    lines += ["", "Presets:"]
    for name, spec in (catalog.get("presets") or {}).items():
        spec = spec or {}
        lines.append(
            f"  {name:12} shape={spec.get('shape')} runtime={spec.get('runtime')} "
            f"org={spec.get('org')}  {(spec.get('description') or '')}"
        )
    lines.append("")
    return "\n".join(lines)


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(prog="catalog.py")
    p.add_argument("--catalog", type=Path, required=True)
    sub = p.add_subparsers(dest="cmd", required=True)

    sub.add_parser("list")

    r = sub.add_parser("resolve")
    r.add_argument("--shape", default="")
    r.add_argument("--runtime", default="")
    r.add_argument("--org", default="")
    r.add_argument("--preset", default="")
    r.add_argument("--pages", action="store_true")
    r.add_argument("--migration-docs", action="store_true")
    r.add_argument("--lms", default="")
    r.add_argument("--github-org", default="")
    r.add_argument("--course-name", default="course")
    r.add_argument(
        "--plain",
        action="store_true",
        help="Emit TAB lines for the shell scaffolder (VAR/DIR/FILE/COPY/APPEND/KEEP)",
    )

    args = p.parse_args(argv)
    catalog = load_catalog(args.catalog)
    if args.cmd == "list":
        sys.stdout.write(format_list(catalog))
        return 0

    shape, runtime, org = apply_preset(
        catalog,
        preset=args.preset,
        shape=args.shape,
        runtime=args.runtime,
        org=args.org,
    )
    resolved = resolve(
        catalog,
        shape=shape,
        runtime=runtime,
        org=org,
        pages=args.pages,
        migration_docs=args.migration_docs,
        lms=args.lms,
        github_org=args.github_org,
        course_name=args.course_name,
    )
    if args.plain:
        sys.stdout.write(_format_plain(resolved))
        return 0
    json.dump(resolved, sys.stdout, indent=2)
    sys.stdout.write("\n")
    return 0


def _format_plain(resolved: dict[str, Any]) -> str:
    lines = [
        f"META\tshape\t{resolved['shape']}",
        f"META\truntime\t{resolved['runtime']}",
        f"META\torg\t{resolved['org']}",
    ]
    for key, value in resolved["vars"].items():
        lines.append(f"VAR\t{key}\t{value}")
    for d in resolved["dirs"]:
        lines.append(f"DIR\t{d}")
    for item in resolved["items"]:
        kind = item["kind"].upper()
        if kind == "KEEP":
            lines.append(f"KEEP\t{item['dest']}")
        elif kind == "APPEND":
            lines.append(f"APPEND\t{item['src']}\t{item['dest']}")
        elif kind == "COPY":
            lines.append(f"COPY\t{item['src']}\t{item['dest']}\t{item.get('mode') or ''}")
        else:
            lines.append(f"FILE\t{item['src']}\t{item['dest']}")
    lines.append("")
    return "\n".join(lines)


if __name__ == "__main__":
    raise SystemExit(main())
