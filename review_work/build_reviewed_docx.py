#!/usr/bin/env python3
"""Construct the reviewed DOCX from a fixed comment manifest.

This script performs an OOXML-only edit: it removes the source review comments,
adds the finalized manifest as exact-range native Word comments, and validates
that document content and formatting-related package parts remain unchanged.
"""

from __future__ import annotations

import copy
import datetime as dt
import json
import re
import sys
import zipfile
from pathlib import Path

from lxml import etree


W_NS = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
R_NS = "http://schemas.openxmlformats.org/officeDocument/2006/relationships"
PKG_REL_NS = "http://schemas.openxmlformats.org/package/2006/relationships"
CT_NS = "http://schemas.openxmlformats.org/package/2006/content-types"
XML_NS = "http://www.w3.org/XML/1998/namespace"

NS = {"w": W_NS, "r": R_NS, "pr": PKG_REL_NS, "ct": CT_NS}

COMMENT_REL = (
    "http://schemas.openxmlformats.org/officeDocument/2006/relationships/comments"
)
COMMENT_CONTENT_TYPE = (
    "application/vnd.openxmlformats-officedocument.wordprocessingml.comments+xml"
)

LEGACY_AND_MODERN_COMMENT_PARTS = {
    "word/comments.xml",
    "word/commentsExtended.xml",
    "word/commentsIds.xml",
    "word/commentsExtensible.xml",
    "word/people.xml",
}


def qn(namespace: str, local: str) -> str:
    return f"{{{namespace}}}{local}"


def xml_bytes(root: etree._Element) -> bytes:
    return etree.tostring(
        root, xml_declaration=True, encoding="UTF-8", standalone="yes"
    )


def parse_manifest(path: Path) -> list[dict[str, object]]:
    """Parse this manifest's deliberately simple one-line YAML mapping form."""
    entries: list[dict[str, object]] = []
    current: dict[str, object] | None = None
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        if not raw_line.strip():
            continue
        new_match = re.fullmatch(r"- (\w+): (.*)", raw_line)
        item_match = re.fullmatch(r"  (\w+): (.*)", raw_line)
        if new_match:
            if current is not None:
                entries.append(current)
            current = {}
            key, raw_value = new_match.groups()
        elif item_match and current is not None:
            key, raw_value = item_match.groups()
        else:
            raise ValueError(f"Unsupported manifest line: {raw_line!r}")

        if raw_value == "null":
            value: object = None
        elif raw_value.startswith('"'):
            value = json.loads(raw_value)
        else:
            value = raw_value
        current[key] = value

    if current is not None:
        entries.append(current)

    required = {"comment_id", "anchor_text", "comment_body"}
    for index, entry in enumerate(entries, start=1):
        missing = required - entry.keys()
        if missing:
            raise ValueError(f"Manifest entry {index} lacks {sorted(missing)}")
    return entries


def paragraph_text(paragraph: etree._Element) -> str:
    return "".join(paragraph.xpath(".//w:t/text()", namespaces=NS))


def text_nodes(paragraph: etree._Element) -> list[etree._Element]:
    return paragraph.xpath(".//w:t", namespaces=NS)


def update_space_attribute(text_element: etree._Element) -> None:
    value = text_element.text or ""
    space_key = qn(XML_NS, "space")
    if value[:1].isspace() or value[-1:].isspace():
        text_element.set(space_key, "preserve")
    else:
        text_element.attrib.pop(space_key, None)


def split_run_at_text_offset(
    run: etree._Element, text_element: etree._Element, offset: int
) -> tuple[etree._Element, etree._Element]:
    """Split a simple Word run at an offset while preserving run properties.

    Non-text run content before the split text (for example a rendered-page-break
    marker) remains only in the left run; content after it remains only in the
    right run. This prevents duplication of layout-affecting markup.
    """
    if etree.QName(run).localname != "r" or text_element.getparent() is not run:
        raise ValueError("Anchor boundary is not in a direct w:r/w:t pair")
    direct_text_nodes = run.xpath("./w:t", namespaces=NS)
    if len(direct_text_nodes) != 1 or direct_text_nodes[0] is not text_element:
        raise ValueError("Anchor boundary run contains multiple or nested w:t nodes")

    value = text_element.text or ""
    if not (0 < offset < len(value)):
        raise ValueError("Run split offset is not internal to the text node")

    left = copy.deepcopy(run)
    right = copy.deepcopy(run)
    left_text = left.xpath("./w:t", namespaces=NS)[0]
    right_text = right.xpath("./w:t", namespaces=NS)[0]
    left_text.text = value[:offset]
    right_text.text = value[offset:]
    update_space_attribute(left_text)
    update_space_attribute(right_text)

    original_children = list(run)
    text_index = original_children.index(text_element)

    # Retain rPr on both sides; retain other content only on its original side.
    for original_index, child in enumerate(list(left)):
        if etree.QName(child).localname != "rPr" and original_index > text_index:
            left.remove(child)
    for original_index, child in enumerate(list(right)):
        if etree.QName(child).localname != "rPr" and original_index < text_index:
            right.remove(child)

    parent = run.getparent()
    if parent is None:
        raise ValueError("Run has no parent")
    run_index = parent.index(run)
    parent.remove(run)
    parent.insert(run_index, left)
    parent.insert(run_index + 1, right)
    return left, right


def split_paragraph_boundary(paragraph: etree._Element, position: int) -> None:
    """Create a run boundary at the requested character position if needed."""
    text = paragraph_text(paragraph)
    if position in (0, len(text)):
        return
    cursor = 0
    for node in text_nodes(paragraph):
        value = node.text or ""
        next_cursor = cursor + len(value)
        if cursor < position < next_cursor:
            split_run_at_text_offset(node.getparent(), node, position - cursor)
            return
        if position == cursor or position == next_cursor:
            return
        cursor = next_cursor
    raise ValueError(f"Could not split paragraph at character {position}")


def find_unique_anchor(
    document_root: etree._Element, anchor: str
) -> tuple[etree._Element, int]:
    hits: list[tuple[etree._Element, int]] = []
    for paragraph in document_root.xpath(".//w:p", namespaces=NS):
        text = paragraph_text(paragraph)
        start = 0
        while True:
            found = text.find(anchor, start)
            if found < 0:
                break
            hits.append((paragraph, found))
            start = found + 1
    if len(hits) != 1:
        raise ValueError(f"Anchor has {len(hits)} occurrences, expected 1: {anchor!r}")
    return hits[0]


def boundary_runs(
    paragraph: etree._Element, start: int, end: int
) -> tuple[etree._Element, etree._Element]:
    cursor = 0
    start_run: etree._Element | None = None
    end_run: etree._Element | None = None
    for node in text_nodes(paragraph):
        value = node.text or ""
        node_start = cursor
        node_end = cursor + len(value)
        if value and node_start == start:
            start_run = node.getparent()
        if value and node_end == end:
            end_run = node.getparent()
        cursor = node_end
    if start_run is None or end_run is None:
        raise ValueError(f"Exact run boundaries not found for range {start}:{end}")
    if start_run.getparent() is not paragraph or end_run.getparent() is not paragraph:
        raise ValueError("Exact anchor is nested in unsupported inline markup")
    return start_run, end_run


def add_range_comment(
    document_root: etree._Element,
    comment_id: int,
    anchor: str,
) -> None:
    paragraph, start = find_unique_anchor(document_root, anchor)
    end = start + len(anchor)

    # Split the later boundary first so a same-run range remains easy to split.
    split_paragraph_boundary(paragraph, end)
    split_paragraph_boundary(paragraph, start)
    first_run, last_run = boundary_runs(paragraph, start, end)

    start_marker = etree.Element(qn(W_NS, "commentRangeStart"))
    start_marker.set(qn(W_NS, "id"), str(comment_id))
    paragraph.insert(paragraph.index(first_run), start_marker)

    end_marker = etree.Element(qn(W_NS, "commentRangeEnd"))
    end_marker.set(qn(W_NS, "id"), str(comment_id))
    paragraph.insert(paragraph.index(last_run) + 1, end_marker)

    reference_run = etree.Element(qn(W_NS, "r"))
    rpr = etree.SubElement(reference_run, qn(W_NS, "rPr"))
    rstyle = etree.SubElement(rpr, qn(W_NS, "rStyle"))
    rstyle.set(qn(W_NS, "val"), "CommentReference")
    reference = etree.SubElement(reference_run, qn(W_NS, "commentReference"))
    reference.set(qn(W_NS, "id"), str(comment_id))
    paragraph.insert(paragraph.index(end_marker) + 1, reference_run)


def strip_source_comment_markup(document_root: etree._Element) -> int:
    removed = 0
    for tag in ("commentRangeStart", "commentRangeEnd"):
        for element in list(
            document_root.xpath(f".//w:{tag}", namespaces=NS)
        ):
            parent = element.getparent()
            if parent is not None:
                parent.remove(element)
                removed += 1

    for reference in list(
        document_root.xpath(".//w:commentReference", namespaces=NS)
    ):
        run = reference.getparent()
        if run is None:
            continue
        run.remove(reference)
        removed += 1
        if etree.QName(run).localname == "r" and all(
            etree.QName(child).localname == "rPr" for child in run
        ):
            parent = run.getparent()
            if parent is not None:
                parent.remove(run)
    return removed


def make_comments_xml(entries: list[dict[str, object]]) -> bytes:
    root = etree.Element(qn(W_NS, "comments"), nsmap={"w": W_NS})
    timestamp = dt.datetime.now(dt.UTC).replace(microsecond=0).isoformat().replace(
        "+00:00", "Z"
    )
    for comment_id, entry in enumerate(entries):
        comment = etree.SubElement(root, qn(W_NS, "comment"))
        comment.set(qn(W_NS, "id"), str(comment_id))
        comment.set(qn(W_NS, "author"), str(entry.get("author", "Codex Academic Editor")))
        comment.set(qn(W_NS, "initials"), str(entry.get("initials", "CAE")))
        comment.set(qn(W_NS, "date"), timestamp)
        paragraph = etree.SubElement(comment, qn(W_NS, "p"))
        run = etree.SubElement(paragraph, qn(W_NS, "r"))
        text = etree.SubElement(run, qn(W_NS, "t"))
        text.set(qn(XML_NS, "space"), "preserve")
        text.text = str(entry["comment_body"])
    return xml_bytes(root)


def update_relationships(root: etree._Element) -> None:
    for relationship in list(root.findall(qn(PKG_REL_NS, "Relationship"))):
        rel_type = relationship.get("Type", "")
        target = relationship.get("Target", "")
        if "comments" in rel_type.lower() or rel_type.endswith("/people"):
            root.remove(relationship)
        elif target in {
            "comments.xml",
            "commentsExtended.xml",
            "commentsIds.xml",
            "commentsExtensible.xml",
            "people.xml",
        }:
            root.remove(relationship)

    used_ids = {relationship.get("Id") for relationship in root}
    number = 1
    while f"rId{number}" in used_ids:
        number += 1
    relationship = etree.SubElement(root, qn(PKG_REL_NS, "Relationship"))
    relationship.set("Id", f"rId{number}")
    relationship.set("Type", COMMENT_REL)
    relationship.set("Target", "comments.xml")


def update_content_types(root: etree._Element) -> None:
    for override in list(root.findall(qn(CT_NS, "Override"))):
        part_name = override.get("PartName", "")
        if part_name.startswith("/word/comments") or part_name == "/word/people.xml":
            root.remove(override)
    override = etree.SubElement(root, qn(CT_NS, "Override"))
    override.set("PartName", "/word/comments.xml")
    override.set("ContentType", COMMENT_CONTENT_TYPE)


def story_signature(root: etree._Element) -> list[tuple[str | None, str]]:
    signature: list[tuple[str | None, str]] = []
    for paragraph in root.xpath(".//w:p", namespaces=NS):
        styles = paragraph.xpath("./w:pPr/w:pStyle/@w:val", namespaces=NS)
        signature.append((styles[0] if styles else None, paragraph_text(paragraph)))
    return signature


def table_signature(root: etree._Element) -> list[list[list[str]]]:
    tables: list[list[list[str]]] = []
    for table in root.xpath(".//w:tbl", namespaces=NS):
        rows: list[list[str]] = []
        for row in table.xpath("./w:tr", namespaces=NS):
            cells: list[str] = []
            for cell in row.xpath("./w:tc", namespaces=NS):
                cells.append("\n".join(paragraph_text(p) for p in cell.xpath(".//w:p", namespaces=NS)))
            rows.append(cells)
        tables.append(rows)
    return tables


def tracked_change_signature(root: etree._Element) -> list[bytes]:
    return [
        etree.tostring(node, method="c14n")
        for node in root.xpath(".//w:ins | .//w:del", namespaces=NS)
    ]


def anchored_text_for_id(document_root: etree._Element, comment_id: int) -> str:
    id_value = str(comment_id)
    starts = document_root.xpath(
        ".//w:commentRangeStart[@w:id=$id]", namespaces=NS, id=id_value
    )
    ends = document_root.xpath(
        ".//w:commentRangeEnd[@w:id=$id]", namespaces=NS, id=id_value
    )
    references = document_root.xpath(
        ".//w:commentReference[@w:id=$id]", namespaces=NS, id=id_value
    )
    if not (len(starts) == len(ends) == len(references) == 1):
        raise ValueError(
            f"Comment {comment_id} anchor counts are "
            f"{len(starts)}/{len(ends)}/{len(references)}"
        )
    start = starts[0]
    end = ends[0]
    if start.getparent() is not end.getparent():
        raise ValueError(f"Comment {comment_id} range crosses unsupported parents")
    parent = start.getparent()
    collected: list[str] = []
    inside = False
    for child in parent:
        if child is start:
            inside = True
            continue
        if child is end:
            break
        if inside:
            collected.extend(child.xpath(".//w:t/text()", namespaces=NS))
    return "".join(collected)


def validate_output(
    source: Path,
    output: Path,
    entries: list[dict[str, object]],
    source_document_root: etree._Element,
) -> dict[str, object]:
    with zipfile.ZipFile(source) as source_zip, zipfile.ZipFile(output) as output_zip:
        output_names = set(output_zip.namelist())
        if "word/comments.xml" not in output_names:
            raise ValueError("Output lacks word/comments.xml")
        forbidden = LEGACY_AND_MODERN_COMMENT_PARTS - {"word/comments.xml"}
        extras = forbidden & output_names
        if extras:
            raise ValueError(f"Stale source comment metadata parts remain: {sorted(extras)}")

        document_root = etree.fromstring(output_zip.read("word/document.xml"))
        comments_root = etree.fromstring(output_zip.read("word/comments.xml"))
        comments = comments_root.xpath("./w:comment", namespaces=NS)
        if len(comments) != len(entries):
            raise ValueError(f"Found {len(comments)} comments, expected {len(entries)}")

        expected_ids = {str(index) for index in range(len(entries))}
        actual_ids = {comment.get(qn(W_NS, "id")) for comment in comments}
        if actual_ids != expected_ids:
            raise ValueError(f"Comment IDs differ: {actual_ids} versus {expected_ids}")

        for comment_id, entry in enumerate(entries):
            comment = comments_root.xpath(
                "./w:comment[@w:id=$id]", namespaces=NS, id=str(comment_id)
            )[0]
            body = "".join(comment.xpath(".//w:t/text()", namespaces=NS))
            if body != entry["comment_body"]:
                raise ValueError(f"Comment body mismatch for manifest entry {comment_id + 1}")
            expected_author = str(entry.get("author", "Codex Academic Editor"))
            expected_initials = str(entry.get("initials", "CAE"))
            if comment.get(qn(W_NS, "author")) != expected_author:
                raise ValueError(f"Unexpected author for comment {comment_id}")
            if comment.get(qn(W_NS, "initials")) != expected_initials:
                raise ValueError(f"Unexpected initials for comment {comment_id}")
            anchor = anchored_text_for_id(document_root, comment_id)
            if anchor != entry["anchor_text"]:
                raise ValueError(f"Anchor mismatch for manifest entry {comment_id + 1}")

        if story_signature(document_root) != story_signature(source_document_root):
            raise ValueError("Document paragraph text/order/styles changed")
        if table_signature(document_root) != table_signature(source_document_root):
            raise ValueError("Document table structure/content changed")

        for unchanged_part in (
            "word/styles.xml",
            "word/numbering.xml",
            "word/footnotes.xml",
            "word/endnotes.xml",
            "word/settings.xml",
        ):
            if source_zip.read(unchanged_part) != output_zip.read(unchanged_part):
                raise ValueError(f"Unrequested change in {unchanged_part}")

        source_tracked = tracked_change_signature(source_document_root)
        output_tracked = tracked_change_signature(document_root)
        if output_tracked != source_tracked:
            raise ValueError("Tracked changes differ from the source review")
        tracked = len(output_tracked)

        rels = etree.fromstring(output_zip.read("word/_rels/document.xml.rels"))
        comment_rels = [
            relationship
            for relationship in rels.findall(qn(PKG_REL_NS, "Relationship"))
            if relationship.get("Type") == COMMENT_REL
            and relationship.get("Target") == "comments.xml"
        ]
        if len(comment_rels) != 1:
            raise ValueError(f"Expected one comments relationship, found {len(comment_rels)}")

        content_types = etree.fromstring(output_zip.read("[Content_Types].xml"))
        overrides = content_types.xpath(
            "./ct:Override[@PartName='/word/comments.xml']", namespaces=NS
        )
        if len(overrides) != 1 or overrides[0].get("ContentType") != COMMENT_CONTENT_TYPE:
            raise ValueError("Comments content-type override is invalid")

        return {
            "comment_count": len(comments),
            "anchors_validated": len(entries),
            "comment_bodies_validated": len(entries),
            "source_paragraphs": len(story_signature(source_document_root)),
            "tables": len(table_signature(source_document_root)),
            "tracked_changes": tracked,
        }


def build(source: Path, manifest: Path, output: Path) -> dict[str, object]:
    entries = parse_manifest(manifest)
    if not entries:
        raise ValueError("Manifest is empty")

    with zipfile.ZipFile(source) as source_zip:
        source_document_root = etree.fromstring(source_zip.read("word/document.xml"))
        source_comment_markup = sum(
            len(source_document_root.xpath(f".//w:{name}", namespaces=NS))
            for name in ("commentRangeStart", "commentRangeEnd", "commentReference")
        )
        document_root = copy.deepcopy(source_document_root)
        removed = strip_source_comment_markup(document_root)
        if removed != source_comment_markup:
            raise ValueError(
                f"Expected to remove {source_comment_markup} existing comment markers/references, removed {removed}"
            )

        # Confirm source uniqueness before adding any range markup.
        for entry in entries:
            find_unique_anchor(document_root, str(entry["anchor_text"]))

        for comment_id, entry in enumerate(entries):
            try:
                add_range_comment(document_root, comment_id, str(entry["anchor_text"]))
            except Exception as error:
                raise ValueError(
                    f"Failed to add comment {entry.get('comment_id', comment_id)} at anchor {entry['anchor_text']!r}"
                ) from error

        rels_root = etree.fromstring(source_zip.read("word/_rels/document.xml.rels"))
        update_relationships(rels_root)
        content_types_root = etree.fromstring(source_zip.read("[Content_Types].xml"))
        update_content_types(content_types_root)

        overrides = {
            "word/document.xml": xml_bytes(document_root),
            "word/comments.xml": make_comments_xml(entries),
            "word/_rels/document.xml.rels": xml_bytes(rels_root),
            "[Content_Types].xml": xml_bytes(content_types_root),
        }

        output.parent.mkdir(parents=True, exist_ok=True)
        with zipfile.ZipFile(output, "w", zipfile.ZIP_DEFLATED) as output_zip:
            for info in source_zip.infolist():
                name = info.filename
                if name in LEGACY_AND_MODERN_COMMENT_PARTS and name != "word/comments.xml":
                    continue
                if name in overrides:
                    output_zip.writestr(info, overrides.pop(name))
                else:
                    output_zip.writestr(info, source_zip.read(name))
            for name, data in overrides.items():
                output_zip.writestr(name, data)

    report = validate_output(source, output, entries, source_document_root)
    report["source_comment_markup_removed"] = removed
    report["output"] = str(output)
    return report


def main() -> None:
    if len(sys.argv) != 4:
        raise SystemExit("Usage: build_reviewed_docx.py SOURCE MANIFEST OUTPUT")
    report = build(Path(sys.argv[1]), Path(sys.argv[2]), Path(sys.argv[3]))
    print(json.dumps(report, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
