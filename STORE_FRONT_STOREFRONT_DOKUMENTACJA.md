# Storefront w OroCommerce (6.1) — przepływ od URL do HTML + debug

## Cel tej dokumentacji
Chcesz rozumieć storefront w OroCommerce tak, żeby zawsze umieć odpowiedzieć:

- co renderuje dany fragment strony (jaki blok),
- gdzie to jest złożone (jakie layout updates),
- czym jest wyrenderowane (który Twig),
- skąd bierze styl (który CSS/SCSS i dlaczego),
- oraz jak to zdebugować krok po kroku.

Poniżej masz spójny opis „od URL do HTML” + praktyczny debug.

---

## Podstawy działania (kluczowe założenia)
Storefront w OroCommerce **nie jest jednym wielkim plikiem `page.html.twig` dla każdej strony**.

Zamiast tego:

- strona jest budowana z **bloków** (klocków UI),
- a „przepis” na to, jakie bloki mają być na stronie i jak są ułożone, jest zapisany w **layout updates** (YAML),
- Twig jest używany głównie do tego, żeby powiedzieć **jak renderuje się dany typ bloku** (jak zamienia się w HTML).

W skrócie:

**URL → route → kontekst → layout updates → drzewo bloków → render Twig bloków → HTML + CSS/JS z theme**

**Dokumentacja Oro:**
- [Layouts i layout updates (storefront)](https://doc.oroinc.com/frontend/storefront/layouts/)
- [Theming storefrontu (theme.yml, struktura theme)](https://doc.oroinc.com/frontend/storefront/theming/)

---

## Bundles (skąd biorą się elementy storefrontu)
W OroCommerce większość funkcjonalności jest dostarczana jako **bundle** (moduł Symfony). Bundle może wnosić jednocześnie:

- **logikę backendową** (kontrolery, serwisy, konfigurację),
- **elementy storefrontu** (layout updates, Twig, assety, konfigurację theme),
- **integrację z istniejącymi elementami** (np. dodanie bloku w konkretnym miejscu strony produktu lub checkoutu).

W praktyce oznacza to, że jedna strona storefrontu jest „składana” z wkładu wielu bundle’i (core Oro + bundle’e funkcjonalne + Twoje custom bundle’e + aktywny theme).

Typowe miejsca w bundle dla storefrontu (najczęściej spotykane w projektach Oro):

- **Layout/theme**: `Resources/views/layouts/<theme_name>/...`
  - definicja theme (`theme.yml`),
  - konfiguracja assetów (`config/assets.yml`),
  - layout updates (YAML) zmieniające drzewo bloków.
- **Twig (render bloków)**: `Resources/views/layouts/<theme_name>/.../*.twig` lub `Resources/views/...` (zależnie od elementu).
- **Assety (SCSS/JS/obrazy)**: `Resources/public/...` (a potem instalowane do `public/` aplikacji).

Najważniejsza zasada utrzymaniowa: nie edytujesz plików w `vendor/`; zmiany robisz przez własne bundle’e i/lub własny theme (często jako child theme).

**Dokumentacja Oro:**
- [Theming storefrontu (struktura katalogów, theme w bundle)](https://doc.oroinc.com/frontend/storefront/theming/)
- [Layouts i layout updates (gdzie trzymać pliki i jak działają)](https://doc.oroinc.com/frontend/storefront/layouts/)

---

## 1) Jak wygląda przepływ żądania (od URL do HTML)

### 1.1. URL trafia do Symfony (routing)
- Przeglądarka wysyła request, np. wejście na stronę produktu, kategorię, koszyk.
- Symfony wybiera **route** i uruchamia kontroler (albo akcję), która obsługuje tę stronę.

W tym miejscu w klasycznym Symfony często byłoby: „renderuję `template.html.twig`”.
W OroCommerce zwykle dzieje się coś innego: kontroler przygotowuje kontekst/dane i przekazuje sterowanie do warstwy **layout**.

### 1.2. Oro buduje „kontekst layoutu” (Layout Context)
Oro tworzy zestaw informacji, które wpływają na to **co** i **jak** ma się wyrenderować. Typowo w storefront to m.in.:

- **website / storefront** (Oro jest multi-website),
- **język (locale) i waluta**,
- **customer / customer group** (B2B),
- **aktywny theme storefrontu** (ważne: theme dla back-office i storefront to nie zawsze to samo),
- czasem dodatkowe flagi zależne od strony (np. „to jest strona listingu”, „to jest checkout” itd.).

To jest kluczowe, bo Oro potrafi zrenderować „tę samą” stronę w innym układzie dla innej witryny, grupy klientów czy języka.

### 1.3. Oro zbiera layout updates (YAML) pasujące do route + kontekst
To jest najważniejszy mechanizm „systemowy”.

**Layout updates** to małe pliki YAML rozsiane po bundle’ach i theme’ach, które mówią:

- dodaj blok,
- usuń blok,
- przenieś blok,
- ustaw opcję bloku (np. atrybuty HTML, klasy CSS, dane wejściowe).

I tu jest sedno: jedna strona zwykle nie ma jednego „źródła prawdy” w jednym pliku.
Oro zbiera i scala wiele layout updates:

- z core OroCommerce,
- z bundle’i funkcjonalnych (koszyk, checkout, katalog),
- z Twoich custom bundle’i,
- z aktywnego theme i jego parent theme.

**Dokumentacja Oro:**
- [Layouts i layout updates (actions, conditions, struktura plików)](https://doc.oroinc.com/frontend/storefront/layouts/)

### 1.4. Powstaje drzewo bloków (layout tree)
Na podstawie zebranych update’ów Oro buduje strukturę strony jako **drzewo**:

- rodzic: np. `page`,
- dzieci: `header`, `content`, `footer`,
- w `content`: `breadcrumbs`, `product_view`, `product_listing`, itd.,
- w `product_view`: `title`, `price`, `add_to_cart`, `gallery`, itd.

Każdy blok ma:

- **id** (nazwa/identyfikator w layoucie),
- **typ** (block type, np. „container”, „link”, „menu”, itd. + typy specyficzne dla OroCommerce),
- **opcje** (np. `attr.class`, `attr.data-*`, parametry dla renderowania),
- miejsce w drzewie (parent/children).

To drzewo jest „prawdziwym układem strony” w Oro.

### 1.5. Render: Twig renderuje bloki, nie „całą stronę”
Dopiero mając drzewo bloków Oro przechodzi do renderowania HTML.

Twig w tym modelu działa bardziej jak:

- „dla bloku typu X użyj Twig block-a Y”

a nie:

- „oto cały szablon strony”.

Czyli:

- layout mówi **jakie klocki są i gdzie stoją**,
- Twig mówi **jak wygląda pojedynczy klocek w HTML**.

W praktyce: zmiana układu często nie wymaga kopiowania wielkich template’ów — wystarcza layout update, który np. przestawia blok albo zmienia mu opcje.

**Dokumentacja Oro:**
- [Templates (Twig) w storefront (konwencje renderowania bloków)](https://doc.oroinc.com/frontend/storefront/templates/)

### 1.6. Theme decyduje o finalnym „opakowaniu” (layout + twig + assety)
Theme storefrontu to pakiet trzech rzeczy naraz:

- **layout** (czyli które layout updates są aktywne / jakie warianty layoutów obowiązują),
- **twig block themes** (jak renderują się bloki),
- **asset pipeline** (jakie CSS/JS są budowane i ładowane).

Dlatego w Oro theme to nie tylko „skórka CSS”, tylko realnie część mechaniki składania strony.

**Dokumentacja Oro:**
- [Theming storefrontu (theme.yml, parent theme, aktywacja theme)](https://doc.oroinc.com/frontend/storefront/theming/)
- [Theme configuration (opcje konfigurowalne z poziomu UI)](https://doc.oroinc.com/frontend/storefront/theme-configuration/)

### 1.7. CSS/JS są dołączane zgodnie z konfiguracją assetów theme i buildem
W Oro 6.1 build assetów jest spięty przez webpack (z builderem Oro, m.in. `.enableLayoutThemes()`), a typowy workflow to:

- `php bin/console oro:assets:build` (build wszystkich theme),
- `php bin/console oro:assets:build custom_storefront --watch` (dev‑watch tylko dla Twojej theme).

Po stronie Oro często dochodzi jeszcze instalacja assetów bundle’i do publicznego katalogu (np. `oro:assets:install --symlink`).

Finalnie przeglądarka dostaje HTML, który linkuje do plików w `public/build/...`.

**Dokumentacja Oro:**
- [AssetBundle (jak działa budowanie assetów)](https://doc.oroinc.com/bundles/platform/AssetBundle/)
- [AssetBundle: commands (oro:assets:build, watch, opcje)](https://doc.oroinc.com/bundles/platform/AssetBundle/commands/)

### 1.8. Cache (dlaczego czasem „nie widzisz zmian”)
W tym modelu cache może pojawić się w kilku miejscach:

- cache Symfony (np. `var/cache`),
- cache layoutów (wyniki scalenia konfiguracji),
- cache HTTP (zależnie od ustawień),
- cache przeglądarki dla CSS/JS.

Dlatego po zmianach konfiguracyjnych/layout/theme często robi się `cache:clear`, a po zmianach w assetach — rebuild/watch.

---

## 2) Co dokładnie możesz zmieniać: 3 poziomy zmian (żeby nie mieszać pojęć)

### 2.1. Zmiana tylko wyglądu (CSS) bez zmiany HTML
To jest najczęstsze i najtańsze:

- zmieniasz zmienne/SCSS w theme,
- ewentualnie dodajesz override selektorami.

W idealnym świecie: parent theme używa zmiennych z `!default`, a Ty nadpisujesz wartości w child theme.

**Dokumentacja Oro:**
- [CSS w storefront (organizacja SCSS, zmienne, komponenty)](https://doc.oroinc.com/frontend/storefront/css/)
- [assets.yml dla CSS (inputs/output, kolejność plików)](https://doc.oroinc.com/frontend/storefront/css/assets-css/)
- [Override / remove files (nadpisywanie lub wyłączanie plików w theme)](https://doc.oroinc.com/frontend/storefront/how-to/how-to-override-remove-files/)

### 2.2. Zmiana atrybutów HTML (np. dodanie klasy), ale bez przebudowy struktury
Gdy CSS ma być „systemowy”, często potrzebujesz „haka” w HTML:

- dodajesz klasę,
- dodajesz `data-*`,
- zmieniasz atrybuty.

To robisz layout update: ustawiasz opcje bloku, np. `attr.class`.

### 2.3. Zmiana struktury HTML / ułożenia elementów
Gdy trzeba:

- przenieść element w inne miejsce,
- usunąć element,
- zmienić kolejność,
- dołożyć wrappery/kolumny/sekcje,

to robisz to w layout updates (operacje typu „add/move/remove”) i czasem dodatkowo Twig (gdy sam HTML danego bloku musi wyglądać inaczej).

---

## 3) Jak to debugować, żeby przestać „wierzyć na słowo”
Poniżej masz praktyczny, powtarzalny proces. Celem jest zawsze dojść do 3 odpowiedzi:

1) jaki to blok / skąd jest na stronie,  
2) czym jest renderowany,  
3) skąd jest styl.

### 3.1. Start w przeglądarce: znajdź element i jego „ślady”
1. Otwórz DevTools → **Elements**.
2. Kliknij element (np. przycisk, karta produktu, nagłówek).
3. Zobacz:
   - klasy CSS (`class="..."`),
   - atrybuty `data-*`,
   - strukturę HTML (czy jest wrapper, jaki jest parent).

To mówi Ci, czy problem jest:
- stricte w CSS (złe style / specificity),
- czy w HTML (brakuje klasy/wrappera),
- czy w układzie (element jest w złym miejscu).

### 3.2. DevTools → „skąd przychodzi CSS”
1. W DevTools → zakładka **Styles / Computed** zobacz, które reguły wygrywają.
2. Sprawdź, z jakich plików pochodzą reguły (często będą to pliki z `public/build/...`).
3. Jeśli sourcemapy są aktywne w dev, często zobaczysz odniesienie do SCSS.

W praktyce:
- jeśli widzisz regułę z `build`, a nie wiesz skąd — to znaczy, że musisz znaleźć źródłowy SCSS w theme lub w vendor (ale nie edytujesz vendor, tylko override w swoim theme).

### 3.3. Zidentyfikuj „kto wyrenderował HTML” (Twig/layout)
Masz dwie główne drogi:

- **Twig Inspector (frontend)**  
  W dev potrafi bardzo szybko wskazać, które Twig bloki / szablony biorą udział w renderowaniu fragmentu.

- **Podejście layoutowe**  
  Gdy potrzebujesz zrozumieć „skąd się wziął ten element” (czyli układ, a nie tylko HTML renderera) — idziesz przez debug layoutu.

**Dokumentacja Oro:**
- [Debugging storefrontu (profiler Layout, debug info w HTML, Twig Inspector)](https://doc.oroinc.com/frontend/storefront/debugging/)
- [TwigInspectorBundle (opis narzędzia)](https://doc.oroinc.com/bundles/platform/TwigInspectorBundle/)
- [Templates (Twig) w storefront](https://doc.oroinc.com/frontend/storefront/templates/)

### 3.4. Debug layoutu z konsoli (twarde informacje „co istnieje” w systemie)
W OroCommerce 6.1 (Symfony 6.4) masz dostępne m.in. te komendy:

- Ogólny obraz layoutu (kontekst, konfiguratory, block types, data providers):

```bash
php bin/console oro:debug:layout
```

- Lista typów bloków (jakie „klocki” system w ogóle zna):

```bash
php bin/console oro:debug:layout:block-types
```

- Szczegóły pojedynczego typu bloku (gdy już wiesz, czego szukasz):

```bash
php bin/console oro:debug:layout --type=NAZWA_TYPU
```

- Szczegóły data providera (gdy chcesz zrozumieć skąd layout bierze dane):

```bash
php bin/console oro:debug:layout --provider=NAZWA_PROVIDER
```

- Referencja konfiguracji `theme.yml` (jakie pola theme rozumie):

```bash
php bin/console oro:layout:config:dump-reference
```

Te komendy nie „naprawiają” strony, ale dają Ci fakty o systemie layoutu: jakie bloki istnieją, jakie mają opcje, jakie providery danych są dostępne.

### 3.5. Debug krok po kroku: jak dojść do właściwego miejsca do zmiany
Gdy masz element na stronie i chcesz go zmienić, idziesz tą ścieżką:

- **Krok A: Czy to tylko styl?**
  - Tak → szukasz SCSS/zmiennych w theme i override’ujesz.
  - Nie → idziesz dalej.

- **Krok B: Czy brakuje klasy/atrybutu?**
  - Tak → robisz layout update: ustawiasz `attr.class` (albo `data-*`) na konkretnym bloku.

- **Krok C: Czy HTML jest „zły” (struktura)?**
  - Tak → albo przestawiasz bloki w layout update (move/add/remove),
  - albo nadpisujesz Twig dla danego bloku (jeśli sam renderer bloku musi się zmienić).

- **Krok D: Czemu zmiany nie wchodzą?**
  - sprawdzasz cache (`cache:clear`),
  - sprawdzasz build (`php bin/console oro:assets:build` / `--watch`),
  - sprawdzasz instalację assetów (`oro:assets:install --symlink`),
  - sprawdzasz, czy edytujesz właściwy theme (aktywny dla storefrontu, nie tylko back-office).

### 3.6. Najczęstsze „pułapki”, które psują debug
- **Mylenie theme back-office z theme storefrontu**: w konfiguracji możesz widzieć `oro_theme.active_theme`, ale storefront theme bywa ustawiany per website w UI.
- **Zmiany w SCSS bez rebuild/watch**: edytujesz plik, ale `build` nie został przeliczony.
- **Cache**: po zmianach w layout/theme konfiguracji potrafi być potrzebny `cache:clear`.
- **Specificity w CSS**: reguła jest, ale przegrywa z inną (DevTools pokaże dokładnie z czym).

