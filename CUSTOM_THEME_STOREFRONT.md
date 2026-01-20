## Customowa theme storefrontu w OroCommerce 6.1 (LTS) — instrukcja praktyczna

Ten dokument opisuje **najprostszy i najbardziej utrzymywalny** sposób zbudowania własnej theme dla storefrontu w OroCommerce 6.1:

- jako **child theme** dziedziczący po `default` (czyli po domyślnej theme “Refreshing Teal”),
- trzymany w **własnym bundle** (bez dotykania `vendor/`),
- z możliwością override: **layout (YAML)**, **Twig (block themes)**, **SCSS/CSS**, **JS (jsmodules)**.

> W OroCommerce storefront to nie tylko CSS. Theme wpływa na layout updates, twig block themes i asset pipeline.

---

## 0) Założenia i konwencje

- **Nazwa theme** w Oro to nazwa katalogu pod `Resources/views/layouts/<theme_name>/...`, np. `hy_storefront`.
- **Parent theme** dla OroCommerce 6.1 to zazwyczaj `default`.
- Pliki z `Resources/public` po `oro:assets:install` lądują (symlink/kopia) pod:
  - `public/bundles/<bundle_alias>/...`
  - np. dla bundle `HyStorefrontThemeBundle` alias zwykle będzie `hystorefronttheme`.

---

## 1) Utwórz własny bundle na theme (najważniejsze: nie edytuj `vendor/`)

W aplikacji (`orocommerce-application`) masz autoload PSR-4 na `src/`, więc najprościej trzymać bundle w `src/Hy/Bundle/...`.

### Co znaczy „autoload PSR-4”

To znaczy, że Composer ma skonfigurowane **automatyczne ładowanie klas PHP** wg standardu **PSR‑4**: gdy w kodzie używasz klasy (np. `Hy\Bundle\StorefrontThemeBundle\HyStorefrontThemeBundle`), to Composer potrafi znaleźć jej plik na dysku na podstawie **namespace** i reguły mapowania. W tej aplikacji mapowanie prowadzi do katalogu `src/` (masz to w `orocommerce-application/composer.json` w sekcji `autoload`), więc możesz trzymać własne klasy/bundle w `orocommerce-application/src/...` bez ręcznego `require`.

### Co znaczy „trzymany we własnym bundle”

W OroCommerce/Symfony **bundle** to moduł aplikacji (pakiet kodu i zasobów). „Trzymany we własnym bundle” znaczy, że Twoją theme (pliki `theme.yml`, layout YAML, Twig, SCSS/JS, obrazki) umieszczasz **w katalogu własnego bundle**, np. w `orocommerce-application/src/Hy/Bundle/StorefrontThemeBundle/...`, zamiast edytować pliki w `vendor/`.

To daje:

- **bezpieczne aktualizacje** (update Oro nie nadpisze Twoich zmian),
- **czytelną strukturę** (wszystko od theme w jednym miejscu),
- **łatwiejsze wdrożenia** (bundle jest częścią Twojej aplikacji/projektu).

### 1.1. Minimalny szkielet bundle

Przykładowa struktura:

```text
orocommerce-application/
└── src/
    └── Hy/
        └── Bundle/
            └── StorefrontThemeBundle/
                ├── HyStorefrontThemeBundle.php
                └── Resources/
                    ├── public/
                    └── views/
                        └── layouts/
                            └── hy_storefront/
                                ├── theme.yml
                                ├── layout.yml
                                ├── config/
                                │   ├── assets.yml
                                │   └── jsmodules.yml
                                └── oro_frontend_root/
                                    └── layout.yml
```

Minimalna klasa bundle (utwórz plik):

`orocommerce-application/src/Hy/Bundle/StorefrontThemeBundle/HyStorefrontThemeBundle.php`

```php
<?php

namespace Hy\Bundle\StorefrontThemeBundle;

use Symfony\Component\HttpKernel\Bundle\Bundle;

class HyStorefrontThemeBundle extends Bundle
{
}
```

### 1.2. Zarejestruj bundle w `src/AppKernel.php`

W Twoim skeletonie jest sekcja `// bundles` w `src/AppKernel.php` — dodaj tam instancję:

```php
$bundles[] = new Hy\Bundle\StorefrontThemeBundle\HyStorefrontThemeBundle();
```

Po tym standardowo:

```bash
php bin/console cache:clear --env=dev
```

---

## 2) Zdefiniuj theme: `theme.yml` (child theme)

Utwórz:

`src/Hy/Bundle/StorefrontThemeBundle/Resources/views/layouts/hy_storefront/theme.yml`

Minimalny przykład:

```yaml
parent: default
label: Hy Storefront
description: 'Custom child theme dla storefrontu (OroCommerce 6.1)'
groups: [ commerce ]
```

Opcjonalnie (jeśli potrzebujesz):

- `rtl_support: true`
- `svg_icons_support: true`
- `logo`, `icon`, `favicons_path`
- `configuration:` (żeby wystawić opcje do konfiguracji theme w panelu)

Podgląd referencji pól:

```bash
php bin/console oro:layout:config:dump-reference
```

---

## 3) Dołóż własne style (SCSS/CSS) przez `assets.yml`

### 3.1. Plik SCSS w `Resources/public`

Utwórz np.:

`src/Hy/Bundle/StorefrontThemeBundle/Resources/public/hy_storefront/scss/styles.scss`

Przykład:

```scss
/* Najprostszy wariant: override CSS selektorami */
.home-page-body {
  outline: 2px dashed #ff2e88;
}
```

### 3.2. Podłącz SCSS do pipeline przez `Resources/views/layouts/<theme>/config/assets.yml`

Utwórz:

`src/Hy/Bundle/StorefrontThemeBundle/Resources/views/layouts/hy_storefront/config/assets.yml`

Przykład (dodanie na końcu głównego bundla CSS, żeby mieć najwyższy priorytet):

```yaml
styles:
    inputs:
        - 'bundles/hystorefronttheme/hy_storefront/scss/styles.scss'
```

Ważne:

- Ścieżka w `inputs` wskazuje na plik w `public/bundles/...` (czyli po `oro:assets:install`).
- Jeśli chcesz **nadpisywać zmienne SCSS** (a nie tylko pisać selektory), to taki plik musisz wpiąć **wcześniej** w listę `inputs` (przed plikami, które tych zmiennych używają).

---

## 4) Dołóż własny JS (opcjonalnie) przez `jsmodules.yml`

Jeśli chcesz dodać moduły JS zgodne z mechaniką Oro (requirejs/dynamic-imports), dodaj plik:

`src/Hy/Bundle/StorefrontThemeBundle/Resources/views/layouts/hy_storefront/config/jsmodules.yml`

Minimalny przykład (alias + dynamic import w grupie `commons`):

```yaml
aliases:
    hy/js/app/components/hello-component$: hystorefronttheme/hy_storefront/js/app/components/hello-component

dynamic-imports:
    commons:
        - hy/js/app/components/hello-component
```

I plik JS:

`src/Hy/Bundle/StorefrontThemeBundle/Resources/public/hy_storefront/js/app/components/hello-component.js`

```javascript
define(function(require) {
    'use strict';

    return function initHello() {
        // eslint-disable-next-line no-console
        console.log('Hello from Hy storefront theme');
    };
});
```

> W praktyce najczęściej podpinasz komponenty przez `data-page-component-module`/`data-page-component-options` w layoucie/Twigu, a sam `jsmodules.yml` służy do mapowania i dynamicznych importów.

---

## 5) Override layout (YAML): dodanie klasy / przenoszenie / usuwanie bloków

Layout updates trzymasz w katalogach typu:

`Resources/views/layouts/<theme>/<layout_update_id>/layout.yml`

Przykład: domyślna strona główna korzysta z `oro_frontend_root`, więc tworzysz:

`src/Hy/Bundle/StorefrontThemeBundle/Resources/views/layouts/hy_storefront/oro_frontend_root/layout.yml`

Minimalny przykład (ustawienie `class` na `body` i ukrycie `page_title`):

```yaml
layout:
    actions:
        - '@setOption':
            id: page_title
            optionName: visible
            optionValue: false
        - '@setOption':
            id: body
            optionName: attr
            optionValue:
                class: 'home-page-body'
```

Typowe operacje:

- `@setOption` — zmiana opcji bloku (np. `visible`, `attr`, `text`, `value`, itd.)
- `@add` / `@addTree` — dodanie bloków
- `@move` — przeniesienie bloku
- `@remove` — usunięcie bloku
- `imports:` — wpięcie gotowych “klocków” z `imports/`

Debug “co jest czym”:

```bash
php bin/console oro:debug:layout
php bin/console oro:debug:layout:block-types
```

---

## 6) Override Twig (block themes): własne renderowanie bloków

W Oro storefront Twig najczęściej działa jako “renderer bloków layoutu” (block theme).

### 6.1. Dodaj własny plik Twig z blockami

Np.:

`src/Hy/Bundle/StorefrontThemeBundle/Resources/views/layouts/hy_storefront/layout.html.twig`

I zdefiniuj/override’uj konkretne bloki Twig (po nazwie bloku w systemie layoutu).

### 6.2. Podłącz block theme przez `@setBlockTheme`

Utwórz (lub dodaj do) plik:

`src/Hy/Bundle/StorefrontThemeBundle/Resources/views/layouts/hy_storefront/layout.yml`

```yaml
layout:
    actions:
        - '@setBlockTheme':
            themes: '@HyStorefrontTheme/layouts/hy_storefront/layout.html.twig'
```

Ważne:

- Jeśli zdefiniujesz blok o tej samej nazwie co w parent theme, to **Twoja definicja wygra**, jeśli Twój block theme jest wczytany “później”.
- Do szybkiej identyfikacji Twiga użyj `OroTwigInspectorBundle` (masz go w `require-dev`).

---

## 7) Aktywacja theme w panelu admina (storefront)

W OroCommerce storefront theme ustawiasz zwykle **per Website** (scope).

Najczęstsza ścieżka w UI:

- **System → Websites → (Twoja witryna) → Configuration → Commerce → Design → Theme**

Wybierz `Hy Storefront` i zapisz konfigurację (pamiętaj o właściwym scope: Website/Organization/Global).

Po zmianie theme często potrzebujesz:

```bash
php bin/console cache:clear --env=dev
```

---

## 8) Build i instalacja assetów (Twoje komendy z Docker/WSL)

Po dodaniu/zmianie plików w `Resources/public` uruchom (w kontenerze `php`):

```bash
cd /var/www/orocommerce
php bin/console oro:assets:install --symlink --env=dev
```

Następnie build:

```bash
npm run watch
# albo produkcyjnie:
# npm run build
```

I na koniec (gdy coś “nie wchodzi”):

```bash
php bin/console cache:clear --env=dev
```

---

## 9) Najczęstsze problemy (checklista)

- **Nie widzę swoich stylów**:
  - czy `oro:assets:install --symlink` było uruchomione po dodaniu plików?
  - czy działa `npm run watch` / zrobiłeś `npm run build`?
  - czy w `assets.yml` ścieżka do pliku ma poprawny `bundles/<bundle_alias>/...`?
- **Zmieniłem layout/theme.yml i nic**:
  - `php bin/console cache:clear --env=dev`
- **Edytuję nie tę theme**:
  - storefront theme jest konfigurowany per Website (nie myl z back-office).

