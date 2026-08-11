#!/usr/bin/env bash
#
# Instaluje hooki gita z tego repo (.git/hooks nie jest wersjonowany,
# więc każdy klon musi to odpalić raz).
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOK="$ROOT/.git/hooks/pre-commit"

cat > "$HOOK" <<'EOF'
#!/usr/bin/env bash
# Podbija wersję aplikacji przy każdym commicie i dołącza zmianę do commita.
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"

# Pomijamy merge i commity bez zmian w plikach aplikacji
if [ -f "$ROOT/.git/MERGE_HEAD" ]; then
    exit 0
fi

NEW="$("$ROOT/scripts/bump-version.sh" patch)"
git add "$ROOT/index.html"
echo "pre-commit: wersja aplikacji podbita do v$NEW"
EOF

chmod +x "$HOOK"
chmod +x "$ROOT/scripts/bump-version.sh"
echo "Zainstalowano hook: $HOOK"
