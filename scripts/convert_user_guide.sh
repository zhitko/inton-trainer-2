#!/usr/bin/env bash
#
# convert_user_guide.sh — Convert Markdown docs under docs/ to DOCX and PDF
#
# Uses the pandoc/latex Docker image so no local pandoc or LaTeX is needed.
# Mermaid diagrams are rendered with mermaid-cli, then laid out the same way
# for both formats: native Word shapes in DOCX, vector PDF figures in PDF.
#
# Usage:
#   ./scripts/convert_user_guide.sh              # convert all docs/*.md to DOCX + PDF
#   ./scripts/convert_user_guide.sh --docx        # DOCX only
#   ./scripts/convert_user_guide.sh --pdf         # PDF only
#   ./scripts/convert_user_guide.sh --help        # show this message
#
# Output (next to each source file):
#   docs/<name>.docx
#   docs/<name>.pdf
#
# Requirements:
#   - Docker (or Podman with docker-compatible alias)
#   - Host fonts with Cyrillic coverage for PDF / Mermaid (DejaVu under
#     /usr/share/fonts/truetype/dejavu, typical on Linux)
#   - Host CJK fonts for Chinese examples in PDF (Noto CJK under
#     /usr/share/fonts/opentype/noto, or Droid Sans Fallback). Override
#     with CJK_FONTS_DIR.
#   - The docs/screenshots/ directory may contain PNG files referenced
#     in the markdown; they will be embedded if present.
#
# Notes:
#   - Mermaid blocks become native Word shapes in DOCX (click a box to edit text).
#   - PDF uses the same layout as vector figures (via Inkscape).
#   - screenshots/README.md is skipped (asset index, not a guide).
#   - PDF uses LuaLaTeX so missing Han glyphs fall back to Noto Serif CJK SC.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

DOCS_DIR="$PROJECT_DIR/docs"
CACHE_ROOT="$DOCS_DIR/.convert_cache"
DOCKER_IMAGE="pandoc/latex:latest"
MERMAID_IMAGE="minlag/mermaid-cli:latest"
# Host DejaVu fonts (Latin + Cyrillic). Override with FONTS_DIR if needed.
HOST_FONTS_DIR="${FONTS_DIR:-/usr/share/fonts/truetype/dejavu}"
# Host CJK fonts (Han). Override with CJK_FONTS_DIR if needed.
HOST_CJK_FONTS_DIR="${CJK_FONTS_DIR:-/usr/share/fonts/opentype/noto}"
HOST_DROID_FONTS_DIR="${DROID_FONTS_DIR:-/usr/share/fonts/truetype/droid}"
MERMAID_CONFIG="$SCRIPT_DIR/mermaid.json"
PREPROCESS_PY="$SCRIPT_DIR/mermaid_preprocess.py"

do_docx=false
do_pdf=false

usage() {
    sed -n '3,33p' "$0"
    exit 0
}

# --- Parse arguments ---
if [[ $# -eq 0 ]]; then
    do_docx=true
    do_pdf=true
else
    for arg in "$@"; do
        case "$arg" in
            --docx) do_docx=true ;;
            --pdf)  do_pdf=true  ;;
            --help) usage        ;;
            *)
                echo "Unknown option: $arg"
                usage
                ;;
        esac
    done
fi

# --- Pre-flight checks ---
if ! command -v docker &>/dev/null; then
    echo "Error: docker is not installed or not in PATH."
    exit 1
fi

if $do_pdf && ! command -v inkscape &>/dev/null; then
    echo "Error: inkscape is required for PDF diagrams (same layout as Word)."
    echo "Install inkscape, or convert with --docx only."
    exit 1
fi

if [[ ! -d "$DOCS_DIR" ]]; then
    echo "Error: docs directory not found: $DOCS_DIR"
    exit 1
fi

mapfile -t MD_FILES < <(
    find "$DOCS_DIR" -type f -name '*.md' ! -path '*/screenshots/*' ! -path '*/.convert_cache/*' | sort
)

if [[ ${#MD_FILES[@]} -eq 0 ]]; then
    echo "Error: no Markdown files found under $DOCS_DIR"
    exit 1
fi

ensure_image() {
    local image="$1"
    if ! docker image inspect "$image" &>/dev/null; then
        echo "Pulling Docker image $image ..."
        docker pull "$image"
    fi
}

ensure_image "$DOCKER_IMAGE"
ensure_image "$MERMAID_IMAGE"

if [[ ! -d "$HOST_FONTS_DIR" ]]; then
    echo "Error: DejaVu fonts not found: $HOST_FONTS_DIR"
    echo "Install fonts-dejavu-core (Debian/Ubuntu) or set FONTS_DIR to a DejaVu folder."
    exit 1
fi

# Title from the first AT1, otherwise the file stem.
doc_title() {
    local md="$1"
    local title
    title="$(grep -m1 -E '^# ' "$md" | sed 's/^# //')" || true
    if [[ -z "${title:-}" ]]; then
        title="$(basename "$md" .md)"
    fi
    printf '%s' "$title"
}

# Extra docker -v mounts for PDF fonts (also reused so DOCX sees same fonts if needed).
DOCKER_FONT_MOUNTS=( -v "$HOST_FONTS_DIR:/usr/share/fonts/truetype/dejavu:ro" )
if [[ -d "$HOST_CJK_FONTS_DIR" ]]; then
    DOCKER_FONT_MOUNTS+=( -v "$HOST_CJK_FONTS_DIR:/usr/share/fonts/opentype/noto:ro" )
fi
if [[ -d "$HOST_DROID_FONTS_DIR" ]]; then
    DOCKER_FONT_MOUNTS+=( -v "$HOST_DROID_FONTS_DIR:/usr/share/fonts/truetype/droid:ro" )
fi

# Preprocess Mermaid → images; prints path to processed markdown.
preprocess_md() {
    local md_abs="$1"
    local stem="$2"
    local fmt="$3"
    local out_dir="$CACHE_ROOT/$stem-$fmt"

    rm -rf "$out_dir"
    mkdir -p "$out_dir"

    if ! grep -q '^```mermaid' "$md_abs"; then
        # No diagrams: point pandoc at the original file via a thin wrapper dir.
        cp "$md_abs" "$out_dir/input.md"
        printf '%s' "$out_dir/input.md"
        return
    fi

    python3 "$PREPROCESS_PY" "$md_abs" \
        --out-dir "$out_dir" \
        --format "$fmt" \
        --config "$MERMAID_CONFIG" \
        --fonts-dir "$HOST_FONTS_DIR"
}

# --- Helper: run pandoc inside the container ---
# md_abs: processed markdown (often under .convert_cache)
# cache_dir: directory containing that markdown + diagram images
run_pandoc() {
    local md_abs="$1"
    local cache_dir="$2"
    local outfile_rel="$3"
    local title="$4"
    shift 4

    local md_name
    md_name="$(basename "$md_abs")"

    docker run --rm \
        --user "$(id -u):$(id -g)" \
        -e HOME=/tmp \
        -e XDG_CACHE_HOME=/tmp/.cache \
        -v "$DOCS_DIR:/data:rw" \
        -v "$cache_dir:/cache:ro" \
        -v "$SCRIPT_DIR:/scripts:ro" \
        "${DOCKER_FONT_MOUNTS[@]}" \
        --entrypoint sh \
        "$DOCKER_IMAGE" \
        -c 'mkdir -p /tmp/.cache/fontconfig && fc-cache -f >/dev/null 2>&1; exec pandoc "$@"' \
        -- \
        "/cache/$md_name" \
            --from markdown \
            --resource-path "/cache:/data" \
            --lua-filter "/scripts/scale_images.lua" \
            --lua-filter "/scripts/wrap_tables.lua" \
            --toc \
            --toc-depth=3 \
            --metadata "title=$title" \
            -o "/data/$outfile_rel" \
            "$@"
}

echo "Found ${#MD_FILES[@]} Markdown file(s) under docs/"

for md in "${MD_FILES[@]}"; do
    rel="${md#"$DOCS_DIR"/}"
    stem="${rel%.md}"
    # Flatten nested paths for cache dir names
    stem_safe="${stem//\//__}"
    title="$(doc_title "$md")"

    echo ""
    echo "==> $rel"

    if $do_docx; then
        echo "  Preparing Mermaid diagrams (SVG for Word) ..."
        docx_md="$(preprocess_md "$md" "$stem_safe" svg)"
        docx_cache="$(dirname "$docx_md")"
        echo "  Converting to DOCX ..."
        run_pandoc "$docx_md" "$docx_cache" "${stem}.docx" "$title" --to docx
        echo "  Converting diagrams to native Word shapes ..."
        python3 "$SCRIPT_DIR/mermaid_to_word.py" "$DOCS_DIR/${stem}.docx" --svg-dir "$docx_cache"
        echo "  -> $DOCS_DIR/${stem}.docx"
    fi

    if $do_pdf; then
        echo "  Preparing diagrams (same layout as Word, vector PDF) ..."
        pdf_md="$(preprocess_md "$md" "$stem_safe" pdf)"
        pdf_cache="$(dirname "$pdf_md")"
        echo "  Converting to PDF ..."
        run_pandoc "$pdf_md" "$pdf_cache" "${stem}.pdf" "$title" \
            --to pdf \
            --pdf-engine=lualatex \
            -V mainfont="DejaVu Serif" \
            -V sansfont="DejaVu Sans" \
            -V monofont="DejaVu Sans Mono" \
            -V fontsize=11pt \
            -V geometry:margin=1in \
            -V colorlinks=true \
            -V linkcolor=blue \
            --include-in-header="/scripts/pdf_header.tex"
        echo "  -> $DOCS_DIR/${stem}.pdf"
    fi
done

echo ""
echo "Done."
echo "Tip: In Word, click a diagram box to edit its text; ungroup to move nodes."
