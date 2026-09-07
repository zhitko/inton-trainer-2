#!/usr/bin/env python3
"""Replace Mermaid SVG pictures in a DOCX with native Word drawing shapes.

Each flowchart node becomes an editable text box (or diamond), and edges become
arrow connectors. Word can then move, restyle, and edit the labels directly.
"""

from __future__ import annotations

import argparse
import math
import re
import sys
import zipfile
from dataclasses import dataclass, field
from pathlib import Path
from xml.etree import ElementTree as ET
from xml.sax.saxutils import escape

SVG_NS = "http://www.w3.org/2000/svg"
EMU_PER_INCH = 914400
# Fit diagrams to typical Word content width (1" margins on letter/A4).
PAGE_WIDTH_EMU = int(6.3 * EMU_PER_INCH)
# Child-space units: 1 SVG pixel = UNIT (keeps integers in DrawingML paths).
UNIT = 10000
MIN_FONT_HALF_POINTS = 18  # 9 pt
MAX_FONT_HALF_POINTS = 22  # 11 pt

NS = {"svg": SVG_NS}


def local(tag: str) -> str:
    return tag.split("}")[-1]


def parse_translate(value: str | None) -> tuple[float, float]:
    if not value:
        return 0.0, 0.0
    total_x = total_y = 0.0
    for match in re.finditer(
        r"translate\(\s*([-\d.eE]+)(?:[ ,]\s*([-\d.eE]+))?\s*\)", value
    ):
        total_x += float(match.group(1))
        total_y += float(match.group(2) or 0.0)
    return total_x, total_y


def parse_points(value: str) -> list[tuple[float, float]]:
    nums = [float(x) for x in re.findall(r"[-+]?\d*\.?\d+(?:e[-+]?\d+)?", value)]
    return list(zip(nums[0::2], nums[1::2]))


def text_of(el: ET.Element) -> str:
    """Join tspans, inserting a space when Mermaid wrapped a line without one."""
    tspans = [t for t in el.iter(f"{{{SVG_NS}}}tspan") if local(t.tag) == "tspan"]
    # Only innermost tspans that actually hold characters.
    leaves = [t for t in tspans if list(t) == [] and (t.text or "").strip() != ""]
    if not leaves:
        return "".join(el.itertext()).strip()
    parts: list[str] = []
    for t in leaves:
        chunk = "".join(t.itertext())
        if (
            parts
            and not parts[-1][-1].isspace()
            and chunk
            and chunk[0].isalnum()
            and parts[-1][-1].isalnum()
        ):
            parts.append(" ")
        parts.append(chunk)
    return "".join(parts).strip()


PATH_TOKEN = re.compile(
    r"([MmLlHhVvCcSsQqTtAaZz])|([-+]?\d*\.?\d+(?:[eE][-+]?\d+)?)"
)


def parse_path(d: str) -> list[tuple[float, float]]:
    """Flatten an SVG path to a polyline (cubics sampled)."""
    tokens: list[str] = [m.group(0) for m in PATH_TOKEN.finditer(d)]
    i = 0
    cmd = ""
    cx = cy = 0.0
    sx = sy = 0.0
    points: list[tuple[float, float]] = []

    def nums(n: int) -> list[float]:
        nonlocal i
        out: list[float] = []
        while len(out) < n and i < len(tokens):
            if PATH_TOKEN.fullmatch(tokens[i]) and tokens[i] not in "MmLlHhVvCcSsQqTtAaZz":
                try:
                    out.append(float(tokens[i]))
                    i += 1
                    continue
                except ValueError:
                    break
            break
        return out

    def add(x: float, y: float) -> None:
        if not points or abs(points[-1][0] - x) > 0.05 or abs(points[-1][1] - y) > 0.05:
            points.append((x, y))

    while i < len(tokens):
        tok = tokens[i]
        if tok.isalpha():
            cmd = tok
            i += 1
            if cmd in "Zz":
                add(sx, sy)
            continue
        if not cmd:
            i += 1
            continue
        rel = cmd.islower()
        c = cmd.upper()
        if c == "M":
            v = nums(2)
            if len(v) < 2:
                break
            x, y = v
            if rel:
                x += cx
                y += cy
            cx, cy = x, y
            sx, sy = x, y
            add(x, y)
            cmd = "l" if rel else "L"
        elif c == "L":
            v = nums(2)
            if len(v) < 2:
                break
            x, y = v
            if rel:
                x += cx
                y += cy
            cx, cy = x, y
            add(x, y)
        elif c == "H":
            v = nums(1)
            if not v:
                break
            x = v[0] + (cx if rel else 0)
            cx = x
            add(cx, cy)
        elif c == "V":
            v = nums(1)
            if not v:
                break
            y = v[0] + (cy if rel else 0)
            cy = y
            add(cx, cy)
        elif c == "C":
            v = nums(6)
            if len(v) < 6:
                break
            x1, y1, x2, y2, x, y = v
            if rel:
                x1 += cx
                y1 += cy
                x2 += cx
                y2 += cy
                x += cx
                y += cy
            for t in (0.25, 0.5, 0.75, 1.0):
                mt = 1 - t
                px = (
                    mt**3 * cx
                    + 3 * mt**2 * t * x1
                    + 3 * mt * t**2 * x2
                    + t**3 * x
                )
                py = (
                    mt**3 * cy
                    + 3 * mt**2 * t * y1
                    + 3 * mt * t**2 * y2
                    + t**3 * y
                )
                add(px, py)
            cx, cy = x, y
        elif c == "Q":
            v = nums(4)
            if len(v) < 4:
                break
            x1, y1, x, y = v
            if rel:
                x1 += cx
                y1 += cy
                x += cx
                y += cy
            for t in (0.5, 1.0):
                mt = 1 - t
                px = mt**2 * cx + 2 * mt * t * x1 + t**2 * x
                py = mt**2 * cy + 2 * mt * t * y1 + t**2 * y
                add(px, py)
            cx, cy = x, y
        else:
            # Skip unsupported (A/S/T) by consuming two numbers if possible.
            nums(2)
    return points


@dataclass
class Node:
    kind: str  # rect | diamond
    x: float
    y: float
    w: float
    h: float
    text: str

    @property
    def cx(self) -> float:
        return self.x + self.w / 2

    @property
    def cy(self) -> float:
        return self.y + self.h / 2

    def set_center(self, cx: float, cy: float) -> None:
        self.x = cx - self.w / 2
        self.y = cy - self.h / 2


@dataclass
class Edge:
    points: list[tuple[float, float]]
    src: Node | None = None
    dst: Node | None = None
    label: str = ""


@dataclass
class Label:
    x: float
    y: float
    w: float
    h: float
    text: str


@dataclass
class Diagram:
    width: float
    height: float
    nodes: list[Node] = field(default_factory=list)
    edges: list[Edge] = field(default_factory=list)
    labels: list[Label] = field(default_factory=list)


def parse_mermaid_svg(path: Path) -> Diagram:
    tree = ET.parse(path)
    root = tree.getroot()
    vb = (root.get("viewBox") or "0 0 100 100").split()
    vb_x, vb_y, vb_w, vb_h = map(float, vb)

    diagram = Diagram(width=vb_w, height=vb_h)

    for g in root.iter(f"{{{SVG_NS}}}g"):
        cls = g.get("class") or ""
        if "node" not in cls.split():
            continue
        if "cluster" in cls:
            continue
        ntx, nty = parse_translate(g.get("transform"))
        text = ""
        for t in g.iter(f"{{{SVG_NS}}}text"):
            got = text_of(t)
            if got:
                text = got
        shape_el = None
        for ch in g:
            if local(ch.tag) in ("rect", "polygon", "circle", "ellipse"):
                if "background" in (ch.get("class") or ""):
                    continue
                shape_el = ch
                break
        if shape_el is None:
            for ch in g.iter():
                if local(ch.tag) in ("rect", "polygon") and "background" not in (
                    ch.get("class") or ""
                ):
                    if ch.get("class") in (None, "", "basic label-container", "label-container"):
                        shape_el = ch
                        break
        if shape_el is None:
            continue
        tag = local(shape_el.tag)
        stx, sty = parse_translate(shape_el.get("transform"))
        ox, oy = ntx + stx, nty + sty
        if tag == "rect":
            x = ox + float(shape_el.get("x") or 0)
            y = oy + float(shape_el.get("y") or 0)
            w = float(shape_el.get("width") or 0)
            h = float(shape_el.get("height") or 0)
            if w < 8 or h < 8:
                continue
            diagram.nodes.append(Node("rect", x, y, w, h, text))
        elif tag == "polygon":
            pts = [(ox + px, oy + py) for px, py in parse_points(shape_el.get("points") or "")]
            if len(pts) < 3:
                continue
            xs = [p[0] for p in pts]
            ys = [p[1] for p in pts]
            diagram.nodes.append(
                Node("diamond", min(xs), min(ys), max(xs) - min(xs), max(ys) - min(ys), text)
            )

    for path in root.iter(f"{{{SVG_NS}}}path"):
        cls = path.get("class") or ""
        if "flowchart-link" not in cls and path.get("data-edge") != "true":
            continue
        # Skip arrowhead markers (they live under <marker>).
        parent_tags = []
        parent = path
        # ElementTree has no parent map by default; markers have tiny viewBoxes.
        d = path.get("d") or ""
        pts = parse_path(d)
        if len(pts) < 2:
            continue
        diagram.edges.append(Edge(pts))

    for g in root.iter(f"{{{SVG_NS}}}g"):
        cls = g.get("class") or ""
        if "edgeLabel" not in cls.split():
            continue
        tx, ty = parse_translate(g.get("transform"))
        if tx == 0 and ty == 0:
            continue
        label = text_of(g)
        if not label:
            continue
        # Approximate label box; Word will wrap.
        w = max(90.0, min(220.0, 8.0 * len(label)))
        h = 22.0
        diagram.labels.append(Label(tx - w / 2, ty - h / 2, w, h, label))

    # Drop duplicate empty-ish nodes.
    diagram.nodes = [n for n in diagram.nodes if n.w > 4 and n.h > 4]
    _bind_edges(diagram)
    align_diagram(diagram)
    return diagram


def _bind_edges(diagram: Diagram) -> None:
    """Attach each edge (and label) to the nearest source and target nodes."""
    if not diagram.nodes:
        return
    for edge in diagram.edges:
        if len(edge.points) < 2:
            continue
        edge.src = _nearest_node(diagram.nodes, *edge.points[0])
        edge.dst = _nearest_node(diagram.nodes, *edge.points[-1])
        if edge.src is edge.dst and len(diagram.nodes) > 1:
            edge.dst = _nearest_node(
                [n for n in diagram.nodes if n is not edge.src], *edge.points[-1]
            )
    unused = list(diagram.labels)
    for edge in diagram.edges:
        if not unused:
            break
        mid = edge.points[len(edge.points) // 2]
        best_i = min(
            range(len(unused)),
            key=lambda i: (unused[i].x + unused[i].w / 2 - mid[0]) ** 2
            + (unused[i].y + unused[i].h / 2 - mid[1]) ** 2,
        )
        label = unused[best_i]
        dist = math.hypot(
            label.x + label.w / 2 - mid[0], label.y + label.h / 2 - mid[1]
        )
        if dist < 160:
            edge.label = label.text
            unused.pop(best_i)
    diagram.labels = []


def _nearest_node(nodes: list[Node], x: float, y: float) -> Node:
    def score(n: Node) -> float:
        dx = 0.0 if n.x <= x <= n.x + n.w else min(abs(x - n.x), abs(x - n.x - n.w))
        dy = 0.0 if n.y <= y <= n.y + n.h else min(abs(y - n.y), abs(y - n.y - n.h))
        return dx * dx + dy * dy + 0.001 * ((x - n.cx) ** 2 + (y - n.cy) ** 2)

    return min(nodes, key=score)


def _anchor(node: Node, toward: Node) -> tuple[float, float]:
    """Point on node's border facing `toward` (cardinal)."""
    dx = toward.cx - node.cx
    dy = toward.cy - node.cy
    if abs(dx) >= abs(dy):
        return (node.x + node.w if dx >= 0 else node.x, node.cy)
    return (node.cx, node.y + node.h if dy >= 0 else node.y)


def _route(p1: tuple[float, float], p2: tuple[float, float]) -> list[tuple[float, float]]:
    x1, y1 = p1
    x2, y2 = p2
    if abs(y1 - y2) < 6:
        y = (y1 + y2) / 2
        return [(x1, y), (x2, y)]
    if abs(x1 - x2) < 6:
        x = (x1 + x2) / 2
        return [(x, y1), (x, y2)]
    # Prefer going out horizontally first (flowchart LR), then vertical, then in.
    mx = (x1 + x2) / 2
    return [(x1, y1), (mx, y1), (mx, y2), (x2, y2)]


def _label_box(text: str, x: float, y: float) -> Label:
    w = max(64.0, min(180.0, 7.0 * len(text) + 14))
    h = 18.0
    return Label(x - w / 2, y - h / 2, w, h, text)


def _wrap_text(text: str, width: int = 20) -> list[str]:
    text = re.sub(r"\s+", " ", text).strip()
    if not text:
        return [""]
    lines: list[str] = []
    rest = text
    while len(rest) > width:
        window = rest[: width + 1]
        brk = max(
            window.rfind(", "),
            window.rfind(" "),
            window.rfind("/"),
            window.rfind("–"),
            window.rfind("-"),
        )
        if brk < max(4, width // 4):
            brk = width
        line = rest[:brk].rstrip(" ,/-")
        if not line:
            line, rest = rest[:width], rest[width:]
        else:
            rest = rest[brk:].lstrip(" ,/-")
        lines.append(line)
    if rest:
        lines.append(rest)
    return lines


def _size_nodes(nodes: list[Node]) -> None:
    for n in nodes:
        lines = _wrap_text(n.text, 18 if n.kind == "diamond" else 22)
        n.text = "\n".join(lines)
        tw = max(len(s) for s in lines) * 7.1
        th = len(lines) * 16.0
        if n.kind == "diamond":
            side = max(100.0, min(136.0, tw + 52.0, th + 72.0))
            n.w = n.h = side
        else:
            n.w = max(108.0, min(170.0, tw + 28.0))
            n.h = max(48.0, th + 24.0)


def _branch_lane(label: str) -> int:
    low = label.lower()
    if any(w in low for w in ("yes", "да", "above", "выше", "true")):
        return -1
    if any(w in low for w in ("no", "нет", "below", "ниже", "false")):
        return 1
    return 0


def align_diagram(diagram: Diagram) -> None:
    """Layered flowchart layout: wrap long chains, stack yes/no branches."""
    nodes = diagram.nodes
    if not nodes:
        return

    _size_nodes(nodes)

    children: dict[int, list[Node]] = {id(n): [] for n in nodes}
    parents: dict[int, list[Node]] = {id(n): [] for n in nodes}
    edge_label: dict[tuple[int, int], str] = {}
    for e in diagram.edges:
        if e.src is None or e.dst is None or e.src is e.dst:
            continue
        children[id(e.src)].append(e.dst)
        parents[id(e.dst)].append(e.src)
        if e.label:
            edge_label[(id(e.src), id(e.dst))] = e.label

    # Longest-path column (left → right).
    rank: dict[int, int] = {}

    def get_rank(n: Node) -> int:
        nid = id(n)
        if nid in rank:
            return rank[nid]
        ps = parents[nid]
        rank[nid] = 0 if not ps else max(get_rank(p) for p in ps) + 1
        return rank[nid]

    for n in nodes:
        get_rank(n)
    max_r = max(rank.values()) if rank else 0
    n_layers = max_r + 1

    diamonds = [n for n in nodes if n.kind == "diamond"]
    wrap = n_layers
    if n_layers > 6:
        wrap = 5
        for d in diamonds:
            r = rank[id(d)]
            if 3 <= r <= 5 and max_r - r >= 1:
                wrap = r
                break
    elif n_layers >= 5 and not diamonds:
        wrap = 3 if n_layers <= 6 else 4

    col_of = {nid: r % wrap for nid, r in rank.items()}
    band_of = {nid: r // wrap for nid, r in rank.items()}

    # Lanes: only stack true siblings (same rank), e.g. yes/no of a diamond.
    lane: dict[int, int] = {id(n): 0 for n in nodes}
    for n in nodes:
        kids = children[id(n)]
        by_rank: dict[int, list[Node]] = {}
        for k in kids:
            by_rank.setdefault(rank[id(k)], []).append(k)
        for group in by_rank.values():
            if len(group) < 2:
                continue
            scored: list[tuple[int, Node]] = []
            for k in group:
                side = _branch_lane(edge_label.get((id(n), id(k)), ""))
                scored.append((side, k))
            scored.sort(key=lambda t: (t[0], t[1].cy, t[1].text))
            # Unlabeled forks stay on the main lane unless this is a decision diamond.
            if all(s == 0 for s, _ in scored) and n.kind != "diamond":
                continue
            if all(s == 0 for s, _ in scored) and len(scored) == 2:
                scored[0] = (-1, scored[0][1])
                scored[1] = (1, scored[1][1])
            for side, k in scored:
                if side:
                    lane[id(k)] = int(side)

    # Inherit lane from a single parent when still 0.
    for n in sorted(nodes, key=lambda x: rank[id(x)]):
        nid = id(n)
        if lane[nid] != 0:
            continue
        ps = parents[nid]
        if len(ps) == 1:
            lane[nid] = lane[id(ps[0])]
        elif len(ps) == 2 and any(p.kind == "diamond" for p in ps):
            continue
        elif ps:
            lane[nid] = int(round(sum(lane[id(p)] for p in ps) / len(ps)))

    # Collisions at the same (band, col, lane): push extras down.
    while True:
        buckets: dict[tuple[int, int, int], list[Node]] = {}
        for n in nodes:
            key = (band_of[id(n)], col_of[id(n)], lane[id(n)])
            buckets.setdefault(key, []).append(n)
        moved = False
        for group in buckets.values():
            if len(group) < 2:
                continue
            group.sort(key=lambda n: (n.cy, n.text))
            for n in group[1:]:
                lane[id(n)] += 1
                moved = True
        if not moved:
            break

    pad = 16.0
    col_gap = 36.0
    row_gap = 28.0

    # Place band by band so each band has compact rows.
    # Map (band, lane) → row index globally.
    bands = sorted(set(band_of.values()))
    global_row: dict[int, int] = {}
    row_cursor = 0
    for b in bands:
        used = sorted({lane[id(n)] for n in nodes if band_of[id(n)] == b})
        local = {ln: i for i, ln in enumerate(used)}
        for n in nodes:
            if band_of[id(n)] == b:
                global_row[id(n)] = row_cursor + local[lane[id(n)]]
        row_cursor += len(used)

    n_cols = wrap
    n_rows = row_cursor

    # Column width / row height from occupants (or a default for empty).
    col_w = [108.0] * n_cols
    row_h = [48.0] * n_rows
    for n in nodes:
        c, r = col_of[id(n)], global_row[id(n)]
        col_w[c] = max(col_w[c], n.w)
        row_h[r] = max(row_h[r], n.h)

    col_cx: list[float] = []
    x = pad
    for w in col_w:
        col_cx.append(x + w / 2)
        x += w + col_gap
    row_cy: list[float] = []
    y = pad
    for h in row_h:
        row_cy.append(y + h / 2)
        y += h + row_gap

    for n in nodes:
        n.set_center(col_cx[col_of[id(n)]], row_cy[global_row[id(n)]])

    new_edges: list[Edge] = []
    new_labels: list[Label] = []
    seen: set[tuple[int, int, str]] = set()
    for edge in diagram.edges:
        if edge.src is None or edge.dst is None or edge.src is edge.dst:
            continue
        key = (id(edge.src), id(edge.dst), edge.label)
        if key in seen:
            continue
        seen.add(key)
        pts = _route(_anchor(edge.src, edge.dst), _anchor(edge.dst, edge.src))
        new_edges.append(Edge(pts, edge.src, edge.dst, edge.label))
        if edge.label:
            segs = list(zip(pts, pts[1:]))
            (a, b) = max(
                segs, key=lambda s: abs(s[0][0] - s[1][0]) + abs(s[0][1] - s[1][1])
            )
            mx, my = (a[0] + b[0]) / 2, (a[1] + b[1]) / 2
            if abs(a[1] - b[1]) < 4:
                my -= 13
            else:
                mx += 14
            new_labels.append(_label_box(edge.label, mx, my))
    diagram.edges = new_edges
    diagram.labels = new_labels

    max_x = max(n.x + n.w for n in nodes)
    max_y = max(n.y + n.h for n in nodes)
    for e in diagram.edges:
        max_x = max(max_x, *(p[0] for p in e.points))
        max_y = max(max_y, *(p[1] for p in e.points))
    for lb in diagram.labels:
        max_x = max(max_x, lb.x + lb.w)
        max_y = max(max_y, lb.y + lb.h)
    diagram.width = max_x + pad
    diagram.height = max_y + pad

def _u(value: float) -> int:
    return max(0, int(round(value * UNIT)))


def _shape_xfrm(x: float, y: float, w: float, h: float) -> str:
    return (
        f'<a:xfrm><a:off x="{_u(x)}" y="{_u(y)}"/>'
        f'<a:ext cx="{max(_u(w), 1)}" cy="{max(_u(h), 1)}"/></a:xfrm>'
    )


def _textbox(text: str, font_half_pts: int) -> str:
    lines = text.split("\n") or [""]
    paras = []
    for line in lines:
        paras.append(
            '<w:p><w:pPr><w:jc w:val="center"/>'
            '<w:spacing w:before="0" w:after="0"/></w:pPr>'
            f'<w:r><w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri" '
            f'w:eastAsia="Calibri" w:cs="Calibri"/>'
            f'<w:sz w:val="{font_half_pts}"/><w:szCs w:val="{font_half_pts}"/></w:rPr>'
            f'<w:t xml:space="preserve">{escape(line)}</w:t></w:r></w:p>'
        )
    return (
        "<wps:txbx><w:txbxContent>"
        f"{''.join(paras)}"
        "</w:txbxContent></wps:txbx>"
        '<wps:bodyPr wrap="square" lIns="36000" tIns="36000" rIns="36000" bIns="36000" '
        'anchor="ctr" anchorCtr="1"><a:normAutofit/></wps:bodyPr>'
    )


def _solid(rgb: str) -> str:
    return f'<a:solidFill><a:srgbClr val="{rgb}"/></a:solidFill>'


def node_xml(node: Node, shape_id: int, font_half_pts: int) -> str:
    geom = "diamond" if node.kind == "diamond" else "roundRect"
    adj = (
        '<a:avLst><a:gd name="adj" fmla="val 8333"/></a:avLst>'
        if geom == "roundRect"
        else "<a:avLst/>"
    )
    fill = "FFF2CC" if node.kind == "diamond" else "E8EEF7"
    line = "BF8F00" if node.kind == "diamond" else "5B7C99"
    return (
        f"<wps:wsp>"
        f'<wps:cNvPr id="{shape_id}" name="Node {shape_id}"/>'
        f'<wps:cNvSpPr txBox="1"/>'
        f"<wps:spPr>{_shape_xfrm(node.x, node.y, node.w, node.h)}"
        f'<a:prstGeom prst="{geom}">{adj}</a:prstGeom>'
        f"{_solid(fill)}"
        f'<a:ln w="12700">{_solid(line)}</a:ln></wps:spPr>'
        f"{_textbox(node.text, font_half_pts)}"
        f"</wps:wsp>"
    )


def label_xml(label: Label, shape_id: int, font_half_pts: int) -> str:
    return (
        f"<wps:wsp>"
        f'<wps:cNvPr id="{shape_id}" name="Label {shape_id}"/>'
        f'<wps:cNvSpPr txBox="1"/>'
        f"<wps:spPr>{_shape_xfrm(label.x, label.y, label.w, label.h)}"
        f'<a:prstGeom prst="rect"><a:avLst/></a:prstGeom>'
        f"{_solid('FFFFFF')}<a:ln><a:noFill/></a:ln></wps:spPr>"
        f"{_textbox(label.text, max(font_half_pts - 2, 16))}"
        f"</wps:wsp>"
    )


def edge_xml(edge: Edge, shape_id: int) -> str:
    xs = [p[0] for p in edge.points]
    ys = [p[1] for p in edge.points]
    min_x, max_x = min(xs), max(xs)
    min_y, max_y = min(ys), max(ys)
    pad = 2.0
    min_x -= pad
    min_y -= pad
    w = max(max_x - min_x + 2 * pad, 2.0)
    h = max(max_y - min_y + 2 * pad, 2.0)
    pw, ph = max(_u(w), 1), max(_u(h), 1)
    cmds = []
    for i, (x, y) in enumerate(edge.points):
        px = min(max(int(round((x - min_x) * UNIT)), 0), pw)
        py = min(max(int(round((y - min_y) * UNIT)), 0), ph)
        tag = "a:moveTo" if i == 0 else "a:lnTo"
        cmds.append(f'<{tag}><a:pt x="{px}" y="{py}"/></{tag}>')
    path = "".join(cmds)
    return (
        f"<wps:wsp>"
        f'<wps:cNvPr id="{shape_id}" name="Connector {shape_id}"/>'
        f"<wps:cNvCnPr/>"
        f"<wps:spPr>{_shape_xfrm(min_x, min_y, w, h)}"
        f"<a:custGeom><a:avLst/><a:gdLst/><a:ahLst/><a:cxnLst/>"
        f'<a:rect l="l" t="t" r="r" b="b"/>'
        f'<a:pathLst><a:path w="{pw}" h="{ph}" fill="none" stroke="true">{path}</a:path></a:pathLst>'
        f"</a:custGeom><a:noFill/>"
        f'<a:ln w="9525">{_solid("555555")}'
        f'<a:tailEnd type="triangle" w="med" len="med"/></a:ln></wps:spPr>'
        f"<wps:bodyPr/>"
        f"</wps:wsp>"
    )


def drawing_xml(diagram: Diagram, doc_pr_id: int, name: str) -> str:
    scale = PAGE_WIDTH_EMU / max(diagram.width, 1.0)
    height_emu = max(int(diagram.height * scale), 1)
    width_emu = PAGE_WIDTH_EMU
    # Font: 16 SVG px → points, then clamp.
    font_pt = 16.0 * scale / (EMU_PER_INCH / 72.0)
    font_half = int(round(font_pt * 2))
    font_half = max(MIN_FONT_HALF_POINTS, min(MAX_FONT_HALF_POINTS, font_half))

    parts: list[str] = []
    sid = doc_pr_id * 50
    for edge in diagram.edges:
        sid += 1
        parts.append(edge_xml(edge, sid))
    for node in diagram.nodes:
        sid += 1
        parts.append(node_xml(node, sid, font_half))
    for label in diagram.labels:
        sid += 1
        parts.append(label_xml(label, sid, font_half))

    ch_w = max(_u(diagram.width), 1)
    ch_h = max(_u(diagram.height), 1)
    inner = "".join(parts)
    return (
        f'<w:drawing><wp:inline distT="0" distB="0" distL="0" distR="0">'
        f'<wp:extent cx="{width_emu}" cy="{height_emu}"/>'
        f'<wp:effectExtent l="0" t="0" r="0" b="0"/>'
        f'<wp:docPr id="{doc_pr_id}" name="{escape(name)}"/>'
        f"<wp:cNvGraphicFramePr>"
        f'<a:graphicFrameLocks xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" noChangeAspect="0"/>'
        f"</wp:cNvGraphicFramePr>"
        f'<a:graphic xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main">'
        f'<a:graphicData uri="http://schemas.microsoft.com/office/word/2010/wordprocessingGroup">'
        f'<wpg:wgp xmlns:wpg="http://schemas.microsoft.com/office/word/2010/wordprocessingGroup" '
        f'xmlns:wps="http://schemas.microsoft.com/office/word/2010/wordprocessingShape">'
        f"<wpg:cNvGrpSpPr/><wpg:grpSpPr><a:xfrm>"
        f'<a:off x="0" y="0"/><a:ext cx="{width_emu}" cy="{height_emu}"/>'
        f'<a:chOff x="0" y="0"/><a:chExt cx="{ch_w}" cy="{ch_h}"/>'
        f"</a:xfrm></wpg:grpSpPr>"
        f"{inner}"
        f"</wpg:wgp></a:graphicData></a:graphic></wp:inline></w:drawing>"
    )


def diagram_to_svg(diagram: Diagram) -> str:
    """Draw the laid-out flowchart as SVG (same geometry as the Word shapes)."""
    w = max(diagram.width, 1.0)
    h = max(diagram.height, 1.0)
    parts = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{w:.1f}" height="{h:.1f}" '
        f'viewBox="0 0 {w:.1f} {h:.1f}">',
        "<defs>",
        '<marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" '
        'markerWidth="8" markerHeight="8" orient="auto-start-reverse">',
        '<path d="M 0 0 L 10 5 L 0 10 z" fill="#555555"/>',
        "</marker>",
        "</defs>",
        '<rect width="100%" height="100%" fill="white"/>',
    ]
    for edge in diagram.edges:
        if len(edge.points) < 2:
            continue
        d = []
        for i, (x, y) in enumerate(edge.points):
            d.append(f"{'M' if i == 0 else 'L'}{x:.1f},{y:.1f}")
        parts.append(
            f'<path d="{" ".join(d)}" fill="none" stroke="#555555" '
            f'stroke-width="1.6" marker-end="url(#arrow)"/>'
        )
    for node in diagram.nodes:
        if node.kind == "diamond":
            hw, hh = node.w / 2, node.h / 2
            pts = (
                f"{node.cx:.1f},{node.cy - hh:.1f} {node.cx + hw:.1f},{node.cy:.1f} "
                f"{node.cx:.1f},{node.cy + hh:.1f} {node.cx - hw:.1f},{node.cy:.1f}"
            )
            parts.append(
                f'<polygon points="{pts}" fill="#FFF2CC" stroke="#BF8F00" '
                f'stroke-width="1.5"/>'
            )
        else:
            parts.append(
                f'<rect x="{node.x:.1f}" y="{node.y:.1f}" width="{node.w:.1f}" '
                f'height="{node.h:.1f}" rx="8" ry="8" fill="#E8EEF7" '
                f'stroke="#5B7C99" stroke-width="1.5"/>'
            )
        lines = [ln for ln in node.text.split("\n") if ln] or [""]
        line_h = 14.0
        y0 = node.cy - (len(lines) - 1) * line_h / 2 + 4
        for i, line in enumerate(lines):
            parts.append(
                f'<text x="{node.cx:.1f}" y="{y0 + i * line_h:.1f}" '
                f'text-anchor="middle" font-family="DejaVu Sans, Liberation Sans, sans-serif" '
                f'font-size="12" fill="#222222">{escape(line)}</text>'
            )
    for label in diagram.labels:
        parts.append(
            f'<text x="{label.x + label.w / 2:.1f}" y="{label.y + label.h / 2 + 4:.1f}" '
            f'text-anchor="middle" font-family="DejaVu Sans, Liberation Sans, sans-serif" '
            f'font-size="10" fill="#444444">{escape(label.text)}</text>'
        )
    parts.append("</svg>")
    return "\n".join(parts)


def write_layout_svg(src_mermaid_svg: Path, dest_svg: Path) -> None:
    diagram = parse_mermaid_svg(src_mermaid_svg)
    dest_svg.write_text(diagram_to_svg(diagram), encoding="utf-8")


DRAWING_RE = re.compile(r"<w:drawing>.*?</w:drawing>", re.DOTALL)
DESCR_RE = re.compile(r'(?:descr|name)="(mermaid-\d+\.svg)"')
ROOT_NS_RE = re.compile(r"(<w:document\b)([^>]*)(>)")
IGNORABLE_RE = re.compile(r'mc:Ignorable="([^"]*)"')


def ensure_namespaces(document_xml: str) -> str:
    extras = {
        "xmlns:wps": "http://schemas.microsoft.com/office/word/2010/wordprocessingShape",
        "xmlns:wpg": "http://schemas.microsoft.com/office/word/2010/wordprocessingGroup",
        "xmlns:mc": "http://schemas.openxmlformats.org/markup-compatibility/2006",
    }

    def add(match: re.Match[str]) -> str:
        attrs = match.group(2)
        for key, uri in extras.items():
            if key not in attrs:
                attrs += f' {key}="{uri}"'
        found = IGNORABLE_RE.search(attrs)
        needed = ["wps", "wpg"]
        if found:
            tokens = found.group(1).split()
            for token in needed:
                if token not in tokens:
                    tokens.append(token)
            attrs = IGNORABLE_RE.sub(f'mc:Ignorable="{" ".join(tokens)}"', attrs, count=1)
        else:
            attrs += ' mc:Ignorable="wps wpg"'
        return match.group(1) + attrs + match.group(3)

    return ROOT_NS_RE.sub(add, document_xml, count=1)


def patch_docx(docx_path: Path, svg_dir: Path) -> int:
    replaced = 0
    with zipfile.ZipFile(docx_path, "r") as zin:
        items = {name: zin.read(name) for name in zin.namelist()}

    doc_xml = items["word/document.xml"].decode("utf-8")
    next_id = 1000

    def repl(match: re.Match[str]) -> str:
        nonlocal replaced, next_id
        block = match.group(0)
        found = DESCR_RE.search(block)
        if not found:
            return block
        svg_name = found.group(1)
        svg_path = svg_dir / svg_name
        src_path = svg_dir / svg_name.replace(".svg", ".src.svg")
        if src_path.is_file():
            svg_path = src_path
        if not svg_path.is_file():
            print(f"    skip {svg_name}: SVG not in {svg_dir}", file=sys.stderr)
            return block
        diagram = parse_mermaid_svg(svg_path)
        if not diagram.nodes:
            print(f"    skip {svg_name}: no nodes parsed", file=sys.stderr)
            return block
        next_id += 1
        replaced += 1
        print(
            f"    {svg_name}: {len(diagram.nodes)} nodes, "
            f"{len(diagram.edges)} edges → native Word group",
            file=sys.stderr,
        )
        native = drawing_xml(diagram, next_id, svg_name)
        # Keep the original picture as Fallback so Word still opens the
        # file if it cannot load the 2010 drawing extensions.
        return (
            "<mc:AlternateContent>"
            f'<mc:Choice Requires="wpg">{native}</mc:Choice>'
            f"<mc:Fallback>{block}</mc:Fallback>"
            "</mc:AlternateContent>"
        )

    new_xml = DRAWING_RE.sub(repl, doc_xml)
    new_xml = ensure_namespaces(new_xml)
    items["word/document.xml"] = new_xml.encode("utf-8")

    # Drop unused mermaid media; leave screenshot PNGs.
    rels_name = "word/_rels/document.xml.rels"
    if replaced and rels_name in items:
        rels = items[rels_name].decode("utf-8")
        # Remove relationships whose target is a mermaid svg/png produced by pandoc
        # only if no remaining r:embed points at them. Safer: leave rels; Word ignores extras.
        items[rels_name] = rels.encode("utf-8")

    tmp = docx_path.with_suffix(".docx.tmp")
    with zipfile.ZipFile(tmp, "w", compression=zipfile.ZIP_DEFLATED) as zout:
        for name, data in items.items():
            info = zipfile.ZipInfo(name)
            info.compress_type = zipfile.ZIP_DEFLATED
            info.create_system = 0  # MS-DOS; Word on Windows is picky about Unix flags
            zout.writestr(info, data)
    tmp.replace(docx_path)
    return replaced


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("docx", type=Path)
    ap.add_argument("--svg-dir", type=Path, required=True)
    args = ap.parse_args()
    if not args.docx.is_file():
        print(f"Error: {args.docx} not found", file=sys.stderr)
        return 1
    n = patch_docx(args.docx, args.svg_dir)
    print(f"  Replaced {n} diagram(s) with native Word shapes.", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
