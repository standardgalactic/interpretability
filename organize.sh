#!/usr/bin/env bash
set -euo pipefail

# organize.sh
#
# Conservative cleanup for a research/writing directory.
#
# Default:
#   ./organize.sh
#
# Actually perform moves:
#   ./organize.sh --apply
#
# It deliberately does NOT try to infer the topic of every prose note.

APPLY=0

if [[ "${1:-}" == "--apply" ]]; then
    APPLY=1
elif [[ $# -gt 0 ]]; then
    printf 'Usage: %s [--apply]\n' "$0" >&2
    exit 2
fi

move() {
    local src="$1"
    local dst="$2"

    [[ -e "$src" ]] || return 0

    if [[ -e "$dst" ]]; then
        printf 'SKIP  %-55s -> %s  [destination exists]\n' "$src" "$dst"
        return 0
    fi

    printf 'MOVE  %-55s -> %s\n' "$src" "$dst"

    if (( APPLY )); then
        mkdir -p "$(dirname "$dst")"
        mv -- "$src" "$dst"
    fi
}

slugify() {
    printf '%s' "$1" |
        tr '[:upper:]' '[:lower:]' |
        sed -E \
            -e 's/[[:space:]_]+/-/g' \
            -e 's/[^a-z0-9.-]+/-/g' \
            -e 's/-+/-/g' \
            -e 's/^-//' \
            -e 's/-$//'
}

# ------------------------------------------------------------
# 1. Recognizable paper families
# ------------------------------------------------------------

papers=(
    "Causal Mechanistic Interpretability"
    "Causal Mediation"
    "Event-Nodes and Texture-nodes"
    "Event-Nodes"
    "From Inspection to Intervention"
    "Mechanistic Interpretability"
    "The Limits of Interpretability"
    "Two-Channel Causal Mediation"
    "recency-as-salience"
)

for title in "${papers[@]}"; do
    dir="papers/$(slugify "$title")"

    # Final/current versions.
    for ext in tex pdf txt; do
        if [[ -f "$title.$ext" ]]; then
            move "$title.$ext" "$dir/$(slugify "$title").$ext"
        fi
    done

    # Numbered drafts.
    for file in "$title"*"draft "*.{tex,pdf,txt}; do
        [[ -e "$file" ]] || continue
        move "$file" "$dir/$(slugify "$file")"
    done
done

# ------------------------------------------------------------
# 2. Spherepop material
# ------------------------------------------------------------

for file in *Spherepop* *SpherePop*; do
    [[ -e "$file" ]] || continue
    move "$file" "spherepop/$(slugify "$file")"
done

# ------------------------------------------------------------
# 3. Gemini exports
# ------------------------------------------------------------

for file in "Google Gemini"*.txt; do
    [[ -e "$file" ]] || continue
    move "$file" "generated/gemini/$(slugify "$file")"
done

# ------------------------------------------------------------
# 4. Generated / rendered HTML
# ------------------------------------------------------------

for file in *.html; do
    [[ -e "$file" ]] || continue
    move "$file" "generated/html/$(slugify "$file")"
done

# ------------------------------------------------------------
# 5. Audio and subtitle artifacts
# ------------------------------------------------------------

for file in *.mp3 *.wav *.vtt *.srt; do
    [[ -e "$file" ]] || continue
    move "$file" "media/$(slugify "$file")"
done

# ------------------------------------------------------------
# 6. Utilities
# ------------------------------------------------------------

for file in *.sh *.py; do
    [[ -e "$file" ]] || continue

    # Don't move this script while it is running.
    [[ "$file" == "$(basename "$0")" ]] && continue

    move "$file" "tools/$(slugify "$file")"
done

# ------------------------------------------------------------
# 7. Generic writing-support/generated markdown
# ------------------------------------------------------------

support_docs=(
    "analogy-guide.md"
    "blog-post.md"
    "briefing-document.md"
    "concept-explainer.md"
    "technical-paper.md"
)

for file in "${support_docs[@]}"; do
    [[ -e "$file" ]] || continue
    move "$file" "generated/writing/$(slugify "$file")"
done

# ------------------------------------------------------------
# 8. Obvious metadata/intermediate artifacts
# ------------------------------------------------------------

for file in *.cloak; do
    [[ -e "$file" ]] || continue
    move "$file" "archive/$(slugify "$file")"
done

# ------------------------------------------------------------
# 9. Remaining loose TXT files become notes.
#
# This is intentionally last. Anything recognized above has
# already been extracted.
# ------------------------------------------------------------

for file in *.txt; do
    [[ -e "$file" ]] || continue
    move "$file" "notes/$(slugify "$file")"
done

printf '\n'

if (( APPLY )); then
    printf 'Organization complete.\n'
else
    printf 'DRY RUN ONLY. No files were changed.\n'
    printf 'Run %s --apply to perform these moves.\n' "$0"
fi
