# Multiwersum Clicker: Dorota vs Czemoóó

Gra typu clicker w jednym pliku `index.html` — bez frameworków, bez budowania, bez
zależności. Wystarczy otworzyć plik albo wystawić katalog na dowolnym hostingu
statycznym (GitHub Pages działa od razu).

## Tryby topki pieniędzy

Gra chodzi w dwóch trybach, w zależności od tego, czy skonfigurujesz Supabase:

| | tryb lokalny (domyślny) | tryb chmury (Supabase) |
|---|---|---|
| Konta | tylko w tej przeglądarce | na serwerze |
| Topka | konta z tego urządzenia | wspólna dla wszystkich graczy |
| Postęp między urządzeniami | nie przenosi się | przenosi się |
| Hasło | hash w `localStorage`, **nie jest zabezpieczeniem** | prawdziwe logowanie po stronie serwera |

Tryb gościa działa w obu przypadkach: pomija logowanie, zapisuje postęp lokalnie
i nie trafia do topki.

## Włączenie topki wspólnej (Supabase)

1. Załóż darmowy projekt na [supabase.com](https://supabase.com).
2. **SQL Editor** → wklej całe [`supabase/schema.sql`](supabase/schema.sql) → **Run**.
   Tworzy to tabelę `profiles` i reguły RLS: czytać topkę może każdy, pisać —
   tylko właściciel swojego wiersza.
3. **Authentication → Sign In / Providers → Email**: wyłącz **Confirm email**.
   Gra loguje na nick, a nie na e-mail (adres jest składany z nicka jako
   `nick@multiwersum-clicker.invalid`), więc potwierdzenie nigdy by nie dotarło.
4. **Project Settings → API**: skopiuj *Project URL* i klucz *anon public*.
5. Wklej je na początku `<script>` w `index.html`:

   ```js
   const SUPABASE_CONFIG = {
       url: 'https://twoj-projekt.supabase.co',
       anonKey: 'eyJhbGciOi...'
   };
   ```

Klucz `anon` jest publiczny i **ma** leżeć w kodzie strony — o bezpieczeństwo
danych dbają reguły RLS, nie tajność tego klucza. Puste wartości = tryb lokalny.

Hasło musi mieć co najmniej 6 znaków (domyślne minimum Supabase).

### Czego to nie załatwia

Wynik jest liczony w przeglądarce i wysyłany na serwer, więc **gracz z otwartą
konsolą może wpisać sobie dowolną kwotę** i trafi ona do topki. Odporna topka
wymagałaby liczenia stanu gry po stronie serwera, co przy grze idle oznacza
przepisanie całej mechaniki. Reguły RLS pilnują tylko tego, żeby nikt nie
podmienił wyniku *komuś innemu* ani nie zmienił swojego nicka.

## Wersjonowanie

Wersja jest widoczna pod grą i podbijana automatycznie przy każdym commicie przez
hook `pre-commit`. Po świeżym klonie trzeba go raz zainstalować:

```bash
./scripts/install-hooks.sh
```

- `scripts/bump-version.sh` — podbija `APP_VERSION` w `index.html`
  (`patch` domyślnie, przyjmuje też `minor` i `major`)
- przy `git commit --amend` dodawaj `--no-verify`, inaczej wersja rośnie przy
  commicie, który nie zmienia kodu

## Balans

Cały balans siedzi w stałych na początku skryptu i w tablicy `upgradesData`.
Ceny rosną z każdym zakupem, zysk doliczany jest liniowo.

Kluczowa zależność: dla ulepszeń klikania `CLICK_COST_GROWTH` **musi** być większe
od `CLICK_MULT`. Przy odwrotnej relacji liczba kliknięć potrzebnych na kolejny
zakup maleje, szereg zbiega i gra kończy się w kilka minut.

Przy obecnych liczbach (3 kliknięcia/s) portal do Świata 2 otwiera się po około
1,5 godziny, a ostatnie ulepszenie Świata 2 jest osiągalne po około 3,5 godziny.
Najprostsze pokrętło tempa to `CPS_COST_GROWTH`: 1.11 daje ~1,5 h do portalu,
1.13 około 5 h, 1.15 około 12 h.

## Struktura

```
index.html            cała gra: HTML + CSS + JS
dorota.jpg, plakal.mp3, czemooo.jpg, czemooo.mp3
favicon.svg           źródło ikony; .ico i .png są z niego generowane
favicon.ico, favicon-180.png
supabase/schema.sql   tabela profiles + RLS dla topki
scripts/              bump wersji i instalacja hooków
Dorota clicker/       stara wersja z jednym światem (nieużywana)
```

## Ikona

Źródłem jest `favicon.svg`. Po jego zmianie przegeneruj pozostałe rozmiary:

```bash
./scripts/build-favicon.sh
```

Skrypt renderuje SVG przez headless Chromium (ImageMagick nie radzi sobie
z gradientami w SVG — tło wychodzi czarne), a dopiero potem składa `.ico`.
