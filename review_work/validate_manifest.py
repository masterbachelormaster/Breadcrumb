from __future__ import annotations

import argparse
import json
import sys
import zipfile
from pathlib import Path

from lxml import etree


W = "{http://schemas.openxmlformats.org/wordprocessingml/2006/main}"


def paragraph_text(paragraph: etree._Element) -> str:
    pieces: list[str] = []
    for node in paragraph.iter():
        if node.tag in {f"{W}t", f"{W}delText"} and node.text:
            pieces.append(node.text)
        elif node.tag == f"{W}tab":
            pieces.append("\t")
        elif node.tag in {f"{W}br", f"{W}cr"}:
            pieces.append("\n")
    return "".join(pieces)


def load_flat_manifest(path: Path) -> list[dict[str, object]]:
    entries: list[dict[str, object]] = []
    current: dict[str, object] | None = None
    for raw_line in path.read_text().splitlines():
        if not raw_line.strip():
            continue
        if raw_line.startswith("- comment_id: "):
            if current is not None:
                entries.append(current)
            current = {"comment_id": raw_line.removeprefix("- comment_id: ")}
            continue
        if current is None or not raw_line.startswith("  "):
            raise ValueError(f"Unsupported manifest line: {raw_line}")
        key, value = raw_line.strip().split(": ", 1)
        if value == "null":
            current[key] = None
        elif value.startswith('"'):
            current[key] = json.loads(value)
        else:
            current[key] = value
    if current is not None:
        entries.append(current)
    return entries


parser = argparse.ArgumentParser()
parser.add_argument("--manifest", type=Path, default=Path("review_work/comment_manifest.yaml"))
parser.add_argument("--source", type=Path, default=Path("review_work/source.docx"))
parser.add_argument("--anchors-only", action="store_true")
args = parser.parse_args()

manifest = load_flat_manifest(args.manifest)
with zipfile.ZipFile(args.source) as archive:
    root = etree.fromstring(archive.read("word/document.xml"))

paragraphs = [paragraph_text(node) for node in root.iter(f"{W}p")]
problems: list[str] = []

expected_ids = [f"C{index:03d}" for index in range(1, len(manifest) + 1)]
actual_ids = [entry["comment_id"] for entry in manifest]
if actual_ids != expected_ids:
    problems.append(f"Non-sequential IDs: {actual_ids}")

for entry in manifest:
    anchor = entry["anchor_text"]
    matches = [(index, text.count(anchor)) for index, text in enumerate(paragraphs, start=1) if anchor in text]
    occurrence_count = sum(count for _, count in matches)
    if occurrence_count != 1:
        problems.append(
            f"{entry['comment_id']} anchor occurs {occurrence_count} times; paragraphs={matches}"
        )
    if not args.anchors_only and entry["change_type"] == "rewrite" and not entry["replacement_text"]:
        problems.append(f"{entry['comment_id']} rewrite lacks replacement_text")
    if (
        not args.anchors_only
        and
        entry["change_type"] == "rewrite"
        and entry["replacement_text"]
        and str(entry["replacement_text"]) not in str(entry["comment_body"])
    ):
        problems.append(f"{entry['comment_id']} comment_body omits its exact replacement_text")
    if not args.anchors_only and entry["change_type"] != "rewrite" and entry["replacement_text"] is not None:
        problems.append(f"{entry['comment_id']} non-rewrite has replacement_text")
    if not args.anchors_only and entry["change_type"] in {"move", "merge"} and not entry["target_location"]:
        problems.append(f"{entry['comment_id']} {entry['change_type']} lacks target_location")
    if not args.anchors_only and entry["change_type"] not in {"move", "merge"} and entry["target_location"] is not None:
        problems.append(f"{entry['comment_id']} has unexpected target_location")

if problems:
    print("\n".join(problems))
    sys.exit(1)

print(f"Validated {len(manifest)} manifest entries; every anchor occurs exactly once.")
