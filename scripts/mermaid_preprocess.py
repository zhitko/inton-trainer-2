#!/usr/bin/env python3
"""Replace ```mermaid fenced blocks with rendered diagram image links.

Writes a processed Markdown file and diagram assets into --out-dir.
Mermaid-cli extracts the graph; then mermaid_to_word lays it out the same
way as the Word diagrams. PDF/PNG are exported from that layout (Inkscape).
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path
from shutil import which

sys.path.insert(0, str(Path(__file__).resolve().parent))
from mermaid_to_word import write_layout_svg

MERMAID_BLOCK = re.compile(
    r"^```mermaid[ \t]*\n(.*?)^```[ \t]*\n?",
    re.MULTILINE | re.DOTALL,
)


def render_mermaid(
    mmd_path: Path,
    out_path: Path,
    *,
    config: Path,
    fonts_dir: Path | None,
    puppeteer_config: Path | None,
) -> None:
    out_path.parent.mkdir(parents=True, exist_ok=True)
    work = mmd_path.parent
    mounts = [
        "-v",
        f"{work.resolve()}:/data:rw",
        "-v",
        f"{config.resolve()}:/config/mermaid.json:ro",
    ]
    if fonts_dir and fonts_dir.is_dir():
        mounts += ["-v", f"{fonts_dir.resolve()}:/usr/share/fonts/truetype/dejavu:ro"]
    if puppeteer_config and puppeteer_config.is_file():
        mounts += [
            "-v",
            f"{puppeteer_config.resolve()}:/config/puppeteer.json:ro",
        ]

    cmd = [
        "docker",
        "run",
        "--rm",
        "-u",
        f"{_uid_gid()}",
        *mounts,
        "minlag/mermaid-cli:latest",
        "-i",
        f"/data/{mmd_path.name}",
        "-o",
        f"/data/{out_path.name}",
        "-c",
        "/config/mermaid.json",
        "-b",
        "white",
        "-w",
        "1600",
        "-s",
        "2",
    ]
    if puppeteer_config and puppeteer_config.is_file():
        cmd += ["-p", "/config/puppeteer.json"]

    subprocess.run(cmd, check=True, capture_output=True, text=True)


def _uid_gid() -> str:
    import os

    return f"{os.getuid()}:{os.getgid()}"


def _inkscape_export(svg_path: Path, dest: Path) -> None:
    if not which("inkscape"):
        raise RuntimeError("inkscape is required to export laid-out diagrams for PDF")
    cmd = [
        "inkscape",
        str(svg_path),
        f"--export-type={dest.suffix.lstrip('.')}",
        f"--export-filename={dest}",
        "--export-area-drawing",
    ]
    subprocess.run(cmd, check=True, capture_output=True, text=True)


def process(md_path: Path, out_dir: Path, fmt: str, config: Path, fonts_dir: Path | None,
            puppeteer_config: Path | None) -> Path:
    text = md_path.read_text(encoding="utf-8")
    out_dir.mkdir(parents=True, exist_ok=True)
    blocks = list(MERMAID_BLOCK.finditer(text))
    if not blocks:
        out_md = out_dir / "input.md"
        out_md.write_text(text, encoding="utf-8")
        return out_md

    parts: list[str] = []
    last = 0
    for i, match in enumerate(blocks, start=1):
        parts.append(text[last:match.start()])
        body = match.group(1).strip() + "\n"
        stem = f"mermaid-{i:02d}"
        mmd_path = out_dir / f"{stem}.mmd"
        src_svg = out_dir / f"{stem}.src.svg"
        layout_svg = out_dir / f"{stem}.svg"
        mmd_path.write_text(body, encoding="utf-8")
        print(f"    rendering {stem} ...", file=sys.stderr, flush=True)
        render_mermaid(
            mmd_path,
            src_svg,
            config=config,
            fonts_dir=fonts_dir,
            puppeteer_config=puppeteer_config,
        )
        if not src_svg.is_file():
            candidates = sorted(out_dir.glob(f"{stem}*"))
            raise RuntimeError(
                f"Expected {src_svg.name} after mermaid-cli; found: "
                + ", ".join(p.name for p in candidates)
            )
        write_layout_svg(src_svg, layout_svg)
        if fmt == "svg":
            img_name = layout_svg.name
        else:
            img_path = out_dir / f"{stem}.{fmt}"
            _inkscape_export(layout_svg, img_path)
            img_name = img_path.name
        parts.append(f"\n![]({img_name})\n\n")
        last = match.end()
    parts.append(text[last:])

    out_md = out_dir / "input.md"
    out_md.write_text("".join(parts), encoding="utf-8")
    return out_md


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("markdown", type=Path)
    ap.add_argument("--out-dir", type=Path, required=True)
    ap.add_argument("--format", choices=("svg", "png", "pdf"), default="svg")
    ap.add_argument("--config", type=Path, required=True)
    ap.add_argument("--fonts-dir", type=Path, default=None)
    ap.add_argument("--puppeteer-config", type=Path, default=None)
    args = ap.parse_args()

    try:
        out_md = process(
            args.markdown,
            args.out_dir,
            args.format,
            args.config,
            args.fonts_dir,
            args.puppeteer_config,
        )
    except subprocess.CalledProcessError as e:
        sys.stderr.write(e.stderr or e.stdout or str(e))
        sys.stderr.write("\n")
        return e.returncode or 1
    print(out_md)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
