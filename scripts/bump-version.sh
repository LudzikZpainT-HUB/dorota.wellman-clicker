#!/usr/bin/env bash
#
# Podbija wersję aplikacji (patch) w index.html.
# Wywoływane automatycznie przez hook .git/hooks/pre-commit.
# Ręcznie: ./scripts/bump-version.sh            -> 1.0.3 => 1.0.4
#          ./scripts/bump-version.sh minor      -> 1.0.3 => 1.1.0
#          ./scripts/bump-version.sh major      -> 1.0.3 => 2.0.0
#
set -euo pipefail

PART="${1:-patch}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FILE="$ROOT/index.html"
PATTERN="const APP_VERSION = '"

if [ ! -f "$FILE" ]; then
    echo "bump-version: brak pliku $FILE" >&2
    exit 1
fi

CURRENT="$(grep -oP "${PATTERN}\K[0-9]+\.[0-9]+\.[0-9]+" "$FILE" || true)"
if [ -z "$CURRENT" ]; then
    echo "bump-version: nie znalazłem APP_VERSION w $FILE" >&2
    exit 1
fi

IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT"

case "$PART" in
    major) MAJOR=$((MAJOR + 1)); MINOR=0; PATCH=0 ;;
    minor) MINOR=$((MINOR + 1)); PATCH=0 ;;
    patch) PATCH=$((PATCH + 1)) ;;
    *) echo "bump-version: nieznany argument '$PART' (użyj major|minor|patch)" >&2; exit 1 ;;
esac

NEW="${MAJOR}.${MINOR}.${PATCH}"
sed -i "s/${PATTERN}${CURRENT}'/${PATTERN}${NEW}'/" "$FILE"

echo "$NEW"
