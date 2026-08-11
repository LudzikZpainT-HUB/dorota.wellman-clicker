#!/usr/bin/env bash
#
# Generuje favicon.ico i favicon-180.png ze źródłowego favicon.svg.
#
# SVG renderujemy przeglądarką, a nie ImageMagickiem - jego wbudowany rysownik
# SVG nie obsługuje gradientów i tło wychodzi czarne. ImageMagick składa dopiero
# .ico z gotowego PNG-a.
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SVG="$ROOT/favicon.svg"
PNG="$ROOT/favicon-180.png"
ICO="$ROOT/favicon.ico"

[ -f "$SVG" ] || { echo "build-favicon: brak $SVG" >&2; exit 1; }
command -v convert >/dev/null || { echo "build-favicon: potrzebny ImageMagick (convert)" >&2; exit 1; }

# Szukamy czegoś, co umie wyrenderować SVG
CHROME=""
for candidate in \
    "${CHROME_BIN:-}" \
    "$HOME"/.cache/ms-playwright/chromium-*/chrome-linux64/chrome \
    /snap/bin/chromium \
    /usr/bin/chromium \
    /usr/bin/chromium-browser \
    /usr/bin/google-chrome
do
    if [ -n "$candidate" ] && [ -x "$candidate" ]; then CHROME="$candidate"; break; fi
done
[ -n "$CHROME" ] || { echo "build-favicon: nie znalazłem przeglądarki (ustaw CHROME_BIN)" >&2; exit 1; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

cp "$SVG" "$WORK/favicon.svg"
cat > "$WORK/wrap.html" <<'HTML'
<!doctype html>
<style>html,body{margin:0;background:transparent}img{width:180px;height:180px;display:block}</style>
<img src="favicon.svg">
HTML

"$CHROME" --headless --no-sandbox --disable-gpu --hide-scrollbars \
    --window-size=180,180 --default-background-color=00000000 \
    --screenshot="$WORK/shot.png" "file://$WORK/wrap.html" >/dev/null 2>&1

[ -s "$WORK/shot.png" ] || { echo "build-favicon: render nie wyszedł" >&2; exit 1; }

convert "$WORK/shot.png" -resize 180x180 "$PNG"
convert "$PNG" -define icon:auto-resize=48,32,16 "$ICO"

echo "Zbudowano:"
identify "$PNG" "$ICO" | sed 's/^/  /'
