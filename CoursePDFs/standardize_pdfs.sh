#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
# standardize_pdfs.sh
# Renames PDFs in CoursePDFs to the format: ${subjectName}${noteNo:0>3}.pdf
#   e.g.  Adaab1.pdf  →  Adaab001.pdf
#         Fiqh12.pdf  →  Fiqh012.pdf
#         Adaab005.pdf → (already correct, skipped)
#
# Usage:
#   bash standardize_pdfs.sh [path/to/CoursePDFs]
#
# If no path is given, it defaults to ./CoursePDFs in the current directory.
# Add --dry-run as the second argument to preview changes without renaming.
# ──────────────────────────────────────────────────────────────────────────────

set -euo pipefail

FOLDER="${1:-./CoursePDFs}"
DRY_RUN=false
[[ "${2:-}" == "--dry-run" ]] && DRY_RUN=true

# Colours for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

if [[ ! -d "$FOLDER" ]]; then
  echo "Error: Directory '$FOLDER' not found." >&2
  exit 1
fi

echo -e "${CYAN}Scanning:${RESET} $FOLDER"
$DRY_RUN && echo -e "${YELLOW}[DRY-RUN mode — no files will be changed]${RESET}"
echo ""

renamed=0
skipped=0
already_ok=0

# Pattern: already correct — <letters><exactly 3 digits>.pdf  e.g. Adaab005.pdf
CORRECT_RE='^([A-Za-z]+)([0-9]{3})\.pdf$'

# Pattern: no spaces, just needs number padding — e.g. Adaab1.pdf, Fiqh12.pdf
NOSPACE_RE='^([A-Za-z]+)([0-9]{1,2})\.pdf$'

# Pattern: spaces between words and/or before number — e.g. "Hadeeth Hifd 6.pdf", "Aqeedah 1.pdf"
# Last token must be a number; everything before it is the subject (words joined).
SPACED_RE='^(([A-Za-z]+ )+)([0-9]{1,3})\.pdf$'

while IFS= read -r -d '' file; do
  dir="$(dirname "$file")"
  base="$(basename "$file")"

  # ── Already correct ────────────────────────────────────────────────────────
  if [[ "$base" =~ $CORRECT_RE ]]; then
    (( already_ok++ )) || true
    continue
  fi

  # ── No-space form that just needs zero-padding ─────────────────────────────
  if [[ "$base" =~ $NOSPACE_RE ]]; then
    subject="${BASH_REMATCH[1]}"
    number="${BASH_REMATCH[2]}"

  # ── Spaced form: "Hadeeth Hifd 6.pdf" → "HadeethHifd006.pdf" ─────────────
  elif [[ "$base" =~ $SPACED_RE ]]; then
    raw_subject="${BASH_REMATCH[1]}"          # e.g. "Hadeeth Hifd "
    number="${BASH_REMATCH[3]}"               # e.g. "6"
    subject="${raw_subject// /}"              # strip all spaces → "HadeethHifd"

  # ── Unrecognised — leave untouched ────────────────────────────────────────
  else
    echo -e "${YELLOW}  UNRECOGNISED (skipped):${RESET} $base"
    (( skipped++ )) || true
    continue
  fi

  new_base="${subject}$(printf '%03d' "$number").pdf"
  new_file="$dir/$new_base"

  if [[ "$file" == "$new_file" ]]; then
    (( already_ok++ )) || true
    continue
  fi

  if [[ -e "$new_file" ]]; then
    echo -e "${YELLOW}  SKIP (target exists):${RESET} $base  →  $new_base"
    (( skipped++ )) || true
    continue
  fi

  echo -e "${GREEN}  RENAME:${RESET} $base  →  $new_base"
  if ! $DRY_RUN; then
    mv -- "$file" "$new_file"
  fi
  (( renamed++ )) || true

done < <(find "$FOLDER" -maxdepth 1 -iname "*.pdf" -print0 | sort -z)

echo ""
echo "──────────────────────────────────────"
if $DRY_RUN; then
  echo -e "Would rename : $renamed file(s)"
else
  echo -e "Renamed      : $renamed file(s)"
fi
echo -e "Already OK   : $already_ok file(s)"
echo -e "Skipped      : $skipped file(s)"
echo "──────────────────────────────────────"
