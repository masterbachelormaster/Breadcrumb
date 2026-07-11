from __future__ import annotations

import argparse
import json
import sys
import zipfile
from collections import Counter
from pathlib import Path

from lxml import etree


NS = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
W = f"{{{NS}}}"
COMMENTS_REL = "http://schemas.openxmlformats.org/officeDocument/2006/relationships/comments"
COMMENT_PART_NAMES = {
    "word/comments.xml",
    "word/commentsExtended.xml",
    "word/commentsIds.xml",
    "word/commentsExtensible.xml",
    "word/people.xml",
}
ALLOWED_CHANGED_PARTS = COMMENT_PART_NAMES | {
    "word/document.xml",
    "word/_rels/document.xml.rels",
    "[Content_Types].xml",
}


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


def c14n(element: etree._Element | None) -> bytes:
    if element is None:
        return b""
    return etree.tostring(element, method="c14n")


def paragraph_signature(paragraph: etree._Element) -> tuple[bytes, tuple[tuple[str, bytes], ...]]:
    ppr = paragraph.find(f"{W}pPr")
    characters: list[tuple[str, bytes]] = []
    for run in paragraph.iter(f"{W}r"):
        if run.find(f"{W}commentReference") is not None:
            continue
        rpr = c14n(run.find(f"{W}rPr"))
        for node in run.iter():
            if node.tag in {f"{W}t", f"{W}delText", f"{W}instrText"} and node.text:
                characters.extend((character, rpr) for character in node.text)
            elif node.tag == f"{W}tab":
                characters.append(("\t", rpr))
            elif node.tag in {f"{W}br", f"{W}cr"}:
                characters.append(("\n", rpr))
    return c14n(ppr), tuple(characters)


def document_structure(document_xml: bytes) -> dict[str, object]:
    root = etree.fromstring(document_xml)
    paragraphs = [paragraph_signature(node) for node in root.iter(f"{W}p")]
    tables = []
    for table in root.iter(f"{W}tbl"):
        rows = []
        for row in table.findall(f"{W}tr"):
            rows.append(len(row.findall(f"{W}tc")))
        tables.append(tuple(rows))
    sections = [c14n(node) for node in root.iter(f"{W}sectPr")]
    revisions = {
        "insertions": len(root.findall(f".//{W}ins")),
        "deletions": len(root.findall(f".//{W}del")),
    }
    return {
        "paragraphs": paragraphs,
        "tables": tables,
        "sections": sections,
        "revisions": revisions,
    }


def comment_anchors(document_xml: bytes) -> tuple[dict[str, str], Counter[str]]:
    root = etree.fromstring(document_xml)
    active: list[str] = []
    text_by_id: dict[str, list[str]] = {}
    marker_counts: Counter[str] = Counter()

    def walk(node: etree._Element) -> None:
        if node.tag == f"{W}commentRangeStart":
            comment_id = node.get(f"{W}id")
            marker_counts[f"start:{comment_id}"] += 1
            active.append(comment_id)
            text_by_id.setdefault(comment_id, [])
            return
        if node.tag == f"{W}commentRangeEnd":
            comment_id = node.get(f"{W}id")
            marker_counts[f"end:{comment_id}"] += 1
            if comment_id in active:
                active.remove(comment_id)
            return
        if node.tag == f"{W}commentReference":
            comment_id = node.get(f"{W}id")
            marker_counts[f"reference:{comment_id}"] += 1
            return
        if node.tag in {f"{W}t", f"{W}delText"} and node.text:
            for comment_id in active:
                text_by_id.setdefault(comment_id, []).append(node.text)
            return
        if node.tag == f"{W}tab":
            for comment_id in active:
                text_by_id.setdefault(comment_id, []).append("\t")
            return
        if node.tag in {f"{W}br", f"{W}cr"}:
            for comment_id in active:
                text_by_id.setdefault(comment_id, []).append("\n")
            return
        for child in node:
            walk(child)

    walk(root)
    return {comment_id: "".join(parts) for comment_id, parts in text_by_id.items()}, marker_counts


def comments(comments_xml: bytes) -> list[dict[str, str]]:
    root = etree.fromstring(comments_xml)
    output = []
    for comment in root.findall(f"{W}comment"):
        pieces: list[str] = []
        for node in comment.iter():
            if node.tag == f"{W}t" and node.text:
                pieces.append(node.text)
            elif node.tag == f"{W}tab":
                pieces.append("\t")
            elif node.tag in {f"{W}br", f"{W}cr"}:
                pieces.append("\n")
        output.append(
            {
                "id": comment.get(f"{W}id"),
                "author": comment.get(f"{W}author", ""),
                "text": "".join(pieces),
            }
        )
    return output


def rels_without_comments(xml_bytes: bytes) -> list[bytes]:
    root = etree.fromstring(xml_bytes)
    kept = []
    for child in root:
        relationship_type = child.get("Type", "")
        if relationship_type == COMMENTS_REL or "comments" in relationship_type or relationship_type.endswith("/people"):
            continue
        kept.append(c14n(child))
    return sorted(kept)


def content_types_without_comments(xml_bytes: bytes) -> list[bytes]:
    root = etree.fromstring(xml_bytes)
    kept = []
    for child in root:
        part_name = child.get("PartName", "").lstrip("/")
        if part_name not in COMMENT_PART_NAMES:
            kept.append(c14n(child))
    return sorted(kept)


parser = argparse.ArgumentParser()
parser.add_argument("source", type=Path)
parser.add_argument("reviewed", type=Path)
parser.add_argument("manifest", type=Path)
args = parser.parse_args()

manifest = load_flat_manifest(args.manifest)
problems: list[str] = []

with zipfile.ZipFile(args.source) as source_zip, zipfile.ZipFile(args.reviewed) as reviewed_zip:
    source_names = set(source_zip.namelist())
    reviewed_names = set(reviewed_zip.namelist())

    for common_part in sorted(source_names & reviewed_names):
        if common_part not in ALLOWED_CHANGED_PARTS:
            if source_zip.read(common_part) != reviewed_zip.read(common_part):
                problems.append(f"Unrequested binary change in {common_part}")

    unexpected_added = reviewed_names - source_names - COMMENT_PART_NAMES
    unexpected_removed = source_names - reviewed_names - COMMENT_PART_NAMES
    if unexpected_added:
        problems.append(f"Unexpected added parts: {sorted(unexpected_added)}")
    if unexpected_removed:
        problems.append(f"Unexpected removed parts: {sorted(unexpected_removed)}")

    source_structure = document_structure(source_zip.read("word/document.xml"))
    reviewed_structure = document_structure(reviewed_zip.read("word/document.xml"))
    if source_structure["paragraphs"] != reviewed_structure["paragraphs"]:
        problems.append("Paragraph text, order, paragraph properties, or character formatting changed")
    if source_structure["tables"] != reviewed_structure["tables"]:
        problems.append("Table/row/cell structure changed")
    if source_structure["sections"] != reviewed_structure["sections"]:
        problems.append("Section/page-layout properties changed")
    if reviewed_structure["revisions"] != source_structure["revisions"]:
        problems.append(
            f"Tracked-change counts differ: source={source_structure['revisions']} reviewed={reviewed_structure['revisions']}"
        )

    if rels_without_comments(source_zip.read("word/_rels/document.xml.rels")) != rels_without_comments(
        reviewed_zip.read("word/_rels/document.xml.rels")
    ):
        problems.append("Non-comment document relationships changed")
    if content_types_without_comments(source_zip.read("[Content_Types].xml")) != content_types_without_comments(
        reviewed_zip.read("[Content_Types].xml")
    ):
        problems.append("Non-comment content types changed")

    if "word/comments.xml" not in reviewed_names:
        problems.append("word/comments.xml is missing")
        reviewed_comments = []
    else:
        reviewed_comments = comments(reviewed_zip.read("word/comments.xml"))

    anchors_by_id, marker_counts = comment_anchors(reviewed_zip.read("word/document.xml"))

if len(reviewed_comments) != len(manifest):
    problems.append(f"Comment count mismatch: expected {len(manifest)}, found {len(reviewed_comments)}")

comment_by_text: dict[str, list[dict[str, str]]] = {}
for comment in reviewed_comments:
    comment_by_text.setdefault(comment["text"], []).append(comment)

for entry in manifest:
    body = str(entry["comment_body"])
    matches = comment_by_text.get(body, [])
    if len(matches) != 1:
        problems.append(f"{entry['comment_id']} comment body matched {len(matches)} comments")
        continue
    comment = matches[0]
    comment_id = comment["id"]
    expected_author = str(entry.get("author", "Codex Academic Editor"))
    if comment["author"] != expected_author:
        problems.append(
            f"{entry['comment_id']} has unexpected author {comment['author']!r}; expected {expected_author!r}"
        )
    for marker in ("start", "end", "reference"):
        if marker_counts[f"{marker}:{comment_id}"] != 1:
            problems.append(
                f"{entry['comment_id']} id={comment_id} has {marker_counts[f'{marker}:{comment_id}']} {marker} markers"
            )
    actual_anchor = anchors_by_id.get(comment_id)
    if actual_anchor != entry["anchor_text"]:
        problems.append(
            f"{entry['comment_id']} anchor mismatch: expected={entry['anchor_text']!r} actual={actual_anchor!r}"
        )

extra_bodies = [comment["text"] for comment in reviewed_comments if comment["text"] not in {str(item["comment_body"]) for item in manifest}]
if extra_bodies:
    problems.append(f"Extra comment bodies found: {extra_bodies}")

if problems:
    print("VALIDATION FAILED")
    for problem in problems:
        print(f"- {problem}")
    sys.exit(1)

print(
    f"VALIDATION PASSED: {len(manifest)} comments; bodies, authors, anchors, markers, source text/order/styles, tables, footnotes/package parts, relationships, and tracked-change counts match expectations."
)
