from __future__ import annotations

import argparse
import json
import zipfile
from pathlib import Path

from lxml import etree


W_NS = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
W = f"{{{W_NS}}}"


def all_text(node: etree._Element) -> str:
    pieces: list[str] = []
    for item in node.iter():
        if item.tag in {f"{W}t", f"{W}delText", f"{W}instrText"} and item.text:
            pieces.append(item.text)
        elif item.tag == f"{W}tab":
            pieces.append("\t")
        elif item.tag in {f"{W}br", f"{W}cr"}:
            pieces.append("\n")
    return "".join(pieces)


parser = argparse.ArgumentParser()
parser.add_argument("docx", type=Path)
args = parser.parse_args()

with zipfile.ZipFile(args.docx) as archive:
    root = etree.fromstring(archive.read("word/document.xml"))

changes = []
for node in root.xpath(".//w:ins | .//w:del", namespaces={"w": W_NS}):
    paragraph = node
    while paragraph is not None and paragraph.tag != f"{W}p":
        paragraph = paragraph.getparent()
    paragraph_text = all_text(paragraph) if paragraph is not None else ""
    changes.append(
        {
            "kind": etree.QName(node).localname,
            "id": node.get(f"{W}id"),
            "author": node.get(f"{W}author"),
            "date": node.get(f"{W}date"),
            "text": all_text(node),
            "paragraph_text": paragraph_text,
        }
    )

print(json.dumps({"count": len(changes), "changes": changes}, ensure_ascii=False, indent=2))
