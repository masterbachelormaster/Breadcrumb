from __future__ import annotations

import json
import argparse
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


parser = argparse.ArgumentParser()
parser.add_argument("docx", nargs="?", type=Path, default=Path("review_work/source.docx"))
parser.add_argument("--contains")
args = parser.parse_args()

source = args.docx
with zipfile.ZipFile(source) as archive:
    root = etree.fromstring(archive.read("word/document.xml"))

paragraphs = []
for index, paragraph in enumerate(root.iter(f"{W}p"), start=1):
    style_nodes = paragraph.xpath("./w:pPr/w:pStyle/@w:val", namespaces={"w": W[1:-1]})
    paragraphs.append(
        {
            "index": index,
            "style": style_nodes[0] if style_nodes else None,
            "text": paragraph_text(paragraph),
        }
    )

if args.contains:
    paragraphs = [item for item in paragraphs if args.contains in item["text"]]

print(json.dumps(paragraphs, ensure_ascii=False, indent=2))
