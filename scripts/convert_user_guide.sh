#!/usr/bin/env bash
#
# convert_user_guide.sh — Convert docs/user_guide.md to DOCX and PDF
#
# Uses the pandoc/latex Docker image so no local pandoc or LaTeX is needed.
#
# Usage:
#   ./scripts/convert_user_guide.sh              # convert to both DOCX and PDF
#   ./scripts/convert_user_guide.sh --docx        # DOCX only
#   ./scripts/convert_user_guide.sh --pdf         # PDF only
#   ./scripts/convert_user_guide.sh --help        # show this message
#
# Output:
#   docs/user_guide.docx
#   docs/user_guide.pdf
#
# Requirements:
#   - Docker (or Podman with docker-compatible alias)
#   - The docs/screenshots/ directory may contain PNG files referenced
#     in the markdown; they will be embedded if present.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

DOCS_DIR="$PROJECT_DIR/docs"
MD_FILE="$DOCS_DIR/user_guide.md"
DOCX_OUT="$DOCS_DIR/user_guide.docx"
PDF_OUT="$DOCS_DIR/user_guide.pdf"

DOCKER_IMAGE="pandoc/latex:latest"

do_docx=false
do_pdf=false

usage() {
    sed -n '3,15p' "$0"
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

if [[ ! -f "$MD_FILE" ]]; then
    echo "Error: Markdown file not found: $MD_FILE"
    exit 1
fi

# --- Pull image if not present ---
if ! docker image inspect "$DOCKER_IMAGE" &>/dev/null; then
    echo "Pulling Docker image $DOCKER_IMAGE ..."
    docker pull "$DOCKER_IMAGE"
fi

# --- Helper: run pandoc inside the container ---
# Mount docs/ as read-write so pandoc can read the .md + screenshots
# and write the output files into the same directory.
# Note: pandoc/latex entrypoint is /usr/local/bin/pandoc, so we pass options directly.
run_pandoc() {
    local outfile="$1"; shift
    docker run --rm \
        --user "$(id -u):$(id -g)" \
        -v "$DOCS_DIR:/data:rw" \
        -v "$SCRIPT_DIR:/scripts:ro" \
        "$DOCKER_IMAGE" \
        "/data/user_guide.md" \
            --from markdown \
            --resource-path "/data" \
            --lua-filter "/scripts/scale_images.lua" \
            --toc \
            --toc-depth=3 \
            -o "/data/$outfile" \
            "$@"
}

# --- Convert to DOCX ---
if $do_docx; then
    echo "Converting to DOCX ..."
    run_pandoc "user_guide.docx" \
        --to docx \
        --metadata title="IntonTrainer 2 — User Guide"
    echo "  -> $DOCX_OUT"
fi

# --- Convert to PDF ---
if $do_pdf; then
    echo "Converting to PDF ..."
    run_pandoc "user_guide.pdf" \
        --to pdf \
        --metadata title="IntonTrainer 2 — User Guide" \
        --pdf-engine=xelatex \
        -V fontsize=11pt \
        -V geometry:margin=1in \
        -V colorlinks=true \
        -V linkcolor=blue \
        -V header-includes="\usepackage{float}\floatplacement{figure}{H}"
    echo "  -> $PDF_OUT"
fi

echo "Done."
