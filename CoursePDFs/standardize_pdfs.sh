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

# Pattern for an ALREADY-correct name:  <letters><exactly 3 digits>.pdf
CORRECT_RE='^([A-Za-z]+)([0-9]{3})\.pdf$'

# Pattern for a name that needs fixing:  <letters><1 or 2 digits>.pdf
FIXABLE_RE='^([A-Za-z]+)([0-9]{1,2})\.pdf$'

while IFS= read -r -d '' file; do
  dir="$(dirname "$file")"
  base="$(basename "$file")"

  # Already correct — skip silently
  if [[ "$base" =~ $CORRECT_RE ]]; then
    (( already_ok++ )) || true
    continue
  fi

  # Needs renaming
  if [[ "$base" =~ $FIXABLE_RE ]]; then
    subject="${BASH_REMATCH[1]}"
    number="${BASH_REMATCH[2]}"
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
  else
    # Name doesn't match either pattern — leave it alone
    echo -e "${YELLOW}  UNRECOGNISED (skipped):${RESET} $base"
    (( skipped++ )) || true
  fi

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
