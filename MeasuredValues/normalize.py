#!/usr/bin/env python3
"""Convert the tree-shaped ioreg dumps under MeasuredValues into pruned JSON.

Usage:
    python3 MeasuredValues/normalize.py            # write <name>.json next to <name>.txt
    python3 MeasuredValues/normalize.py --matrix   # regenerate KeyMatrix.md

See MeasuredValues/README.md for the pruning policy and the known parsing limits.
"""

import argparse
import json
import re
import sys
from pathlib import Path

MEASURED_VALUES_DIRECTORY = Path(__file__).resolve().parent
SERVICE_DIRECTORY_NAMES = ("AppleSmartBattery", "AppleSmartBatteryPack")

EXCLUDED_TOP_LEVEL_KEYS = {
    "PortControllerInfo",
    "FedDetails",
    "AppleRawAdapterDetails",
    "DeadBatteryBootData",
    "IOReportLegend",
    "IOGeneralInterest",
    "IOReportLegendPublic",
}

REDACTED_KEYS = {"Serial", "SerialString", "MfgData", "ManufacturerData"}
REDACTED_PATHS = {("LifetimeData", "Raw")}
REDACTED_PLACEHOLDER = "<redacted>"

FORCE_STRING_KEYS = {"HwVersion", "FwVersion", "Model", "Description", "Manufacturer", "Name", "DeviceName"}

NON_BREAKING_SPACE = "\u00a0"

BRANCH_PATTERN = re.compile(r"^((?:[│ ]   )*)(?:├|└)── (.*)$")
DATA_BLOB_PATTERN = re.compile(r"^\{length = (\d+), bytes = 0x.*\}$")
INTEGER_PATTERN = re.compile(r"^-?\d+$")
DECIMAL_PATTERN = re.compile(r"^-?\d+\.\d+$")

ARRAY_ELEMENT_MARKER = "."


class Node:
    def __init__(self, name):
        self.name = name
        self.children = []


def parse_tree(text):
    """Build a Node tree from the ├── / └── dump, tolerating NBSP indentation."""
    root = Node(ARRAY_ELEMENT_MARKER)
    stack = [root]
    for raw_line in text.replace(NON_BREAKING_SPACE, " ").splitlines():
        line = raw_line.rstrip()
        if not line or line == ARRAY_ELEMENT_MARKER:
            continue
        match = BRANCH_PATTERN.match(line)
        if match is None:
            raise ValueError(f"unparsable line: {raw_line!r}")
        depth = len(match.group(1)) // 4
        if depth + 1 > len(stack):
            raise ValueError(f"indentation jumps by more than one level: {raw_line!r}")
        del stack[depth + 1 :]
        node = Node(match.group(2))
        stack[-1].children.append(node)
        stack.append(node)
    return root


def parse_scalar(text, key):
    data_blob = DATA_BLOB_PATTERN.match(text)
    if data_blob is not None:
        return f"<data: {data_blob.group(1)} bytes>"
    if key in FORCE_STRING_KEYS or text.startswith("0x"):
        return text
    if INTEGER_PATTERN.match(text) is not None:
        if len(text.lstrip("-")) > 1 and text.lstrip("-").startswith("0"):
            return text
        return int(text)
    if DECIMAL_PATTERN.match(text) is not None:
        return float(text)
    return text


def convert(node, path, issues):
    children = node.children
    if not children:
        return None
    if all(child.name == ARRAY_ELEMENT_MARKER for child in children):
        return [convert(child, path, issues) for child in children]
    if all(not child.children for child in children):
        if len(children) == 1:
            return parse_scalar(children[0].name, node.name)
        return [parse_scalar(child.name, node.name) for child in children]
    result = {}
    for child in children:
        if child.name in result:
            issues.append(f"duplicate key {'.'.join(path + (child.name,))}")
        result[child.name] = convert(child, path + (child.name,), issues)
    return dict(sorted(result.items()))


def redact(value, path):
    key = path[-1] if path else None
    if key in REDACTED_KEYS or path[-2:] in REDACTED_PATHS:
        return REDACTED_PLACEHOLDER
    if isinstance(value, dict):
        return {name: redact(child, path + (name,)) for name, child in value.items()}
    if isinstance(value, list):
        return [redact(child, path) for child in value]
    return value


def key_paths(value, path=()):
    if isinstance(value, dict):
        paths = set()
        for name, child in value.items():
            paths.add(path + (name,))
            paths |= key_paths(child, path + (name,))
        return paths
    if isinstance(value, list):
        paths = set()
        for child in value:
            paths |= key_paths(child, path)
        return paths
    return set()


def node_paths(node, path=()):
    """Every key path in the raw tree, ignoring leaf value nodes."""
    paths = set()
    for child in node.children:
        if not child.children:
            continue
        if child.name == ARRAY_ELEMENT_MARKER:
            paths |= node_paths(child, path)
            continue
        paths.add(path + (child.name,))
        paths |= node_paths(child, path + (child.name,))
    return paths


def normalize(text):
    """Return (json_ready_value, issues) for one dump."""
    issues = []
    root = parse_tree(text)
    root.children = [child for child in root.children if child.name not in EXCLUDED_TOP_LEVEL_KEYS]
    converted = convert(root, (), issues)
    if converted is None:
        converted = {}
    expected = node_paths(root)
    produced = key_paths(converted)
    missing = expected - produced
    if missing:
        issues.append(f"keys lost during conversion: {sorted('.'.join(p) for p in missing)}")
    return redact(converted, ()), issues


def dump_files():
    return sorted(
        path
        for name in SERVICE_DIRECTORY_NAMES
        for path in (MEASURED_VALUES_DIRECTORY / name).glob("*.txt")
    )


def write_json_files():
    failed = False
    for source in dump_files():
        value, issues = normalize(source.read_text(encoding="utf-8"))
        for issue in issues:
            print(f"{source.relative_to(MEASURED_VALUES_DIRECTORY)}: {issue}", file=sys.stderr)
            failed = True
        destination = source.with_suffix(".json")
        destination.write_text(json.dumps(value, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        print(f"{source.relative_to(MEASURED_VALUES_DIRECTORY)} -> {destination.name}")
    return 1 if failed else 0


def write_matrix_file():
    lines = [
        "# Key availability matrix",
        "",
        "Generated by `python3 MeasuredValues/normalize.py --matrix`. Do not edit by hand.",
        "",
        "`o` = the key is present in that dump, `-` = absent. Only keys up to two levels deep are listed;",
        "keys present in every dump of a service are collected in a separate list instead of filling the table.",
        "",
    ]
    for directory_name in SERVICE_DIRECTORY_NAMES:
        paths = sorted((MEASURED_VALUES_DIRECTORY / directory_name).glob("*.json"))
        if not paths:
            continue
        documents = [json.loads(path.read_text(encoding="utf-8")) for path in paths]
        present = [{".".join(key) for key in key_paths(document) if len(key) <= 2} for document in documents]
        every_key = sorted(set().union(*present))
        shared = [key for key in every_key if all(key in columns for columns in present)]
        varying = [key for key in every_key if key not in shared]

        lines.append(f"## {directory_name}")
        lines.append("")
        lines.extend(f"{index}. `{path.stem}`" for index, path in enumerate(paths, start=1))
        lines.append("")
        lines.append("| Key | " + " | ".join(str(index) for index in range(1, len(paths) + 1)) + " |")
        lines.append("| --- | " + " | ".join(":-:" for _ in paths) + " |")
        for key in varying:
            lines.append(f"| `{key}` | " + " | ".join("o" if key in columns else "-" for columns in present) + " |")
        lines.append("")
        lines.append("### Present in every dump")
        lines.append("")
        lines.extend(f"- `{key}`" for key in shared)
        lines.append("")

    destination = MEASURED_VALUES_DIRECTORY / "KeyMatrix.md"
    destination.write_text("\n".join(lines), encoding="utf-8")
    print(f"wrote {destination.name}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--matrix", action="store_true", help="regenerate KeyMatrix.md instead of converting")
    arguments = parser.parse_args()
    if arguments.matrix:
        write_matrix_file()
        return 0
    return write_json_files()


if __name__ == "__main__":
    sys.exit(main())
