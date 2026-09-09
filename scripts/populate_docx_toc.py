#!/usr/bin/env python3
"""Fill the empty pandoc DOCX table of contents with heading hyperlinks.

Pandoc's ``--toc`` for DOCX inserts a Word TOC field with no entries. Microsoft
Word can populate it on open (Update Fields); LibreOffice, Google Docs, and
WPS typically show a heading and a blank list. This script replaces that empty
field with a static, clickable contents list built from Heading 1–3 bookmarks.
"""

from __future__ import annotations

import argparse
import re
import sys
import zipfile
from pathlib import Path
from xml.etree import ElementTree as ET
from xml.sax.saxutils import escape

W_NS = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"

# Pandoc writes the TOC field as a single empty paragraph. Newer/older
# versions may split fldChar/instrText across runs or add a placeholder.
TOC_FIELD_RE = re.compile(
    r"<w:p>\s*"
    r"(?:<w:pPr>.*?</w:pPr>\s*)?"
    r"(?:<w:r>\s*)?"
    r'<w:fldChar\b[^>]*w:fldCharType="begin"[^/]*/>\s*'
    r"(?:</w:r>\s*<w:r>\s*)?"
    r"<w:instrText\b[^>]*>[^<]*TOC[^<]*</w:instrText>\s*"
    r"(?:</w:r>\s*<w:r>\s*)?"
    r'<w:fldChar\b[^>]*w:fldCharType="separate"[^/]*/>\s*'
    r"(?:</w:r>\s*<w:r>\s*(?:<w:rPr>.*?</w:rPr>\s*)?(?:<w:t\b[^>]*>[^<]*</w:t>\s*)?</w:r>\s*<w:r>\s*)?"
    r'<w:fldChar\b[^>]*w:fldCharType="end"[^/]*/>\s*'
    r"(?:</w:r>\s*)?"
    r"</w:p>",
    re.DOTALL,
)

TOC_STYLE_XML = """
  <w:style w:type="paragraph" w:styleId="TOC1">
    <w:name w:val="toc 1"/>
    <w:basedOn w:val="BodyText"/>
    <w:next w:val="BodyText"/>
    <w:autoRedefine/>
    <w:pPr>
      <w:spacing w:after="60"/>
      <w:ind w:left="0"/>
    </w:pPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="TOC2">
    <w:name w:val="toc 2"/>
    <w:basedOn w:val="BodyText"/>
    <w:next w:val="BodyText"/>
    <w:autoRedefine/>
    <w:pPr>
      <w:spacing w:after="40"/>
      <w:ind w:left="360"/>
    </w:pPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="TOC3">
    <w:name w:val="toc 3"/>
    <w:basedOn w:val="BodyText"/>
    <w:next w:val="BodyText"/>
    <w:autoRedefine/>
    <w:pPr>
      <w:spacing w:after="40"/>
      <w:ind w:left="720"/>
    </w:pPr>
  </w:style>
"""


def q(tag: str) -> str:
    return f"{{{W_NS}}}{tag}"


def local(tag: str) -> str:
    return tag.split("}")[-1]


def para_style(p: ET.Element) -> str:
    p_pr = p.find(q("pPr"))
    if p_pr is None:
        return ""
    p_style = p_pr.find(q("pStyle"))
    if p_style is None:
        return ""
    return p_style.get(q("val")) or ""


def heading_level(style: str) -> int | None:
    match = re.fullmatch(r"Heading([1-9])", style or "")
    return int(match.group(1)) if match else None


def para_text(p: ET.Element) -> str:
    return "".join((t.text or "") for t in p.iter(q("t")))


def bookmark_name(el: ET.Element) -> str | None:
    name = el.get(q("name"))
    if not name or name.startswith("_"):
        return None
    return name


def collect_headings(document_xml: str, max_level: int) -> list[tuple[int, str, str | None]]:
    root = ET.fromstring(document_xml)
    body = root.find(q("body"))
    if body is None:
        return []

    headings: list[tuple[int, str, str | None]] = []
    pending: list[str] = []
    title_text: str | None = None

    for el in list(body):
        tag = local(el.tag)
        if tag == "bookmarkStart":
            name = bookmark_name(el)
            if name:
                pending.append(name)
            continue
        if tag != "p":
            continue

        for child in el:
            if local(child.tag) == "bookmarkStart":
                name = bookmark_name(child)
                if name:
                    pending.append(name)

        style = para_style(el)
        if style == "Title" and title_text is None:
            title_text = para_text(el).strip()
            continue

        level = heading_level(style)
        if not level or level > max_level:
            continue

        text = para_text(el).strip()
        if not text:
            pending.clear()
            continue

        # Metadata title is emitted as both Title and Heading 1; skip the duplicate.
        if level == 1 and title_text and text == title_text:
            pending.clear()
            continue

        bookmark = pending[-1] if pending else None
        pending.clear()
        headings.append((level, text, bookmark))

    return headings


def toc_paragraph(level: int, text: str, bookmark: str | None) -> str:
    style = f"TOC{min(level, 3)}"
    indent = (level - 1) * 360
    escaped = escape(text)
    inner: str
    if bookmark:
        inner = (
            f'<w:hyperlink w:anchor="{escape(bookmark, {"\"": "&quot;"})}" w:history="1">'
            f'<w:r><w:rPr><w:rStyle w:val="Hyperlink"/></w:rPr>'
            f'<w:t xml:space="preserve">{escaped}</w:t></w:r>'
            f"</w:hyperlink>"
        )
    else:
        inner = f'<w:r><w:t xml:space="preserve">{escaped}</w:t></w:r>'
    return (
        f"<w:p>"
        f"<w:pPr><w:pStyle w:val=\"{style}\"/>"
        f'<w:ind w:left="{indent}"/></w:pPr>'
        f"{inner}"
        f"</w:p>"
    )


def ensure_toc_styles(styles_xml: str) -> str:
    if 'w:styleId="TOC1"' in styles_xml:
        return styles_xml
    if not styles_xml.rstrip().endswith("</w:styles>"):
        return styles_xml
    return styles_xml.rstrip()[: -len("</w:styles>")] + TOC_STYLE_XML + "</w:styles>\n"


def rewrite_zip(docx_path: Path, items: dict[str, bytes]) -> None:
    tmp = docx_path.with_suffix(".docx.tmp")
    with zipfile.ZipFile(tmp, "w", compression=zipfile.ZIP_DEFLATED) as zout:
        for name, data in items.items():
            info = zipfile.ZipInfo(name)
            info.compress_type = zipfile.ZIP_DEFLATED
            info.create_system = 0
            zout.writestr(info, data)
    tmp.replace(docx_path)


TOC_HEADING_TEXT_RE = re.compile(
    r'(<w:p>\s*<w:pPr>\s*<w:pStyle w:val="TOCHeading"[^/]*/>\s*</w:pPr>\s*'
    r"<w:r>\s*<w:t\b[^>]*>)([^<]*)(</w:t>)",
    re.DOTALL,
)


def set_toc_heading(document_xml: str, toc_title: str) -> str:
    escaped = escape(toc_title)
    new_xml, n = TOC_HEADING_TEXT_RE.subn(rf"\g<1>{escaped}\g<3>", document_xml, count=1)
    return new_xml if n == 1 else document_xml


def populate_docx_toc(
    docx_path: Path, max_level: int = 3, toc_title: str | None = None
) -> int:
    with zipfile.ZipFile(docx_path, "r") as zin:
        items = {name: zin.read(name) for name in zin.namelist()}

    doc_xml = items["word/document.xml"].decode("utf-8")
    headings = collect_headings(doc_xml, max_level)
    if not headings:
        print("    TOC: no headings found; left unchanged", file=sys.stderr)
        return 0

    if not TOC_FIELD_RE.search(doc_xml):
        print("    TOC: pandoc TOC field not found; left unchanged", file=sys.stderr)
        return 0

    # User guides use # for the document title (omitted above) and ## for
    # real sections. Shift so the shallowest remaining heading is TOC1.
    min_level = min(level for level, _text, _bookmark in headings)
    entries = "".join(
        toc_paragraph(level - min_level + 1, text, bookmark)
        for level, text, bookmark in headings
    )
    new_xml, n = TOC_FIELD_RE.subn(entries, doc_xml, count=1)
    if n != 1:
        print("    TOC: failed to replace empty field; left unchanged", file=sys.stderr)
        return 0

    if toc_title:
        new_xml = set_toc_heading(new_xml, toc_title)

    items["word/document.xml"] = new_xml.encode("utf-8")

    styles_name = "word/styles.xml"
    if styles_name in items:
        items[styles_name] = ensure_toc_styles(items[styles_name].decode("utf-8")).encode("utf-8")

    rewrite_zip(docx_path, items)
    print(f"    TOC: filled {len(headings)} heading(s)", file=sys.stderr)
    return len(headings)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("docx", type=Path)
    ap.add_argument("--toc-depth", type=int, default=3)
    ap.add_argument("--toc-title", type=str, default=None)
    args = ap.parse_args()
    if not args.docx.is_file():
        print(f"Error: {args.docx} not found", file=sys.stderr)
        return 1
    populate_docx_toc(args.docx, max_level=args.toc_depth, toc_title=args.toc_title)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
