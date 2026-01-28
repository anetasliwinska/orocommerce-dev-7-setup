# OroCommerce Frontend SCSS Cheat Sheet

Ten dokument jest przewodnikiem dla frontend developera pracującego z OroCommerce. Pokazuje strukturę SCSS w CustomThemeBundle oraz elementy, które można zmieniać.

---

## Struktura SCSS w CustomThemeBundle

```
scss/
├── components/     ← FrontendBundle (implicit)
├── layout/         ← FrontendBundle
├── settings/       ← FrontendBundle
└── oro/
    ├── form/       ← OroFormBundle
    ├── checkout/   ← OroCheckoutBundle
```

---

## 1. settings/ – Design System (fundament)

### Co zmieniasz:
- Kolory (palety, semantic colors)
- Fonty
- Spacing (margins, paddings)
- Border-radius
- Breakpointy
- Light/Dark tokens

### Przykłady:
```scss
$theme-colors
$body-bg
$text-color
$font-family-base
$border-radius-base
$grid-gutter-width
```

Docs: [Theme structure & SCSS override](https://doc.oroinc.com/frontend/storefront/css/#dev-doc-frontend-css-theme-structure)

---

## 2. components/ – Elementy UI

### Co:
- Buttony, linki
- Cards, badges
- Modale, dropdowny, tooltips
- Breadcrumbs, pagination, tabs
- Alerts, loaders

### Przykłady:
```
components/
├── _buttons.scss
├── _card.scss
├── _modal.scss
├── _dropdown.scss
├── _pagination.scss
├── _tabs.scss
```

Docs: [Frontend components](https://doc.oroinc.com/frontend/storefront/)

---

## 3. layout/ – Struktura strony

### Co:
- Grid system
- Header, footer layout
- Sekcje (hero, content, sidebar)
- Container widths
- Sticky header/footer

### Przykłady:
```scss
.header { height: 88px; }
.page-content { max-width: 1440px; }
```

Docs: [Layouts overview](https://doc.oroinc.com/frontend/layouts/)

---

## 4. oro/form/ – Formularze

### Co:
- Inputy, textarea, select
- Checkboxy, radio
- Label, error states, disabled/readonly
- Help text

### Przykłady:
```scss
.input
.input--error
.form-label
.form-error
```

### Pozycja pliku:
```
storefront/scss/oro/form/_form.scss
```

Docs: [Forms customization](https://doc.oroinc.com/frontend/forms/)

---

## 5. oro/checkout/ – Checkout

### Co:
- Układ stepów
- Summary box
- Shipping/payment cards
- CTA buttons
- Order review
- Mobile checkout UX

### Przykłady:
```scss
.checkout-steps
.checkout-summary
.checkout-payment-method
```

Docs: [Checkout customization](https://doc.oroinc.com/frontend/storefront/checkout/)

---

## 6. Dodatkowe bundle’e (opcjonalnie)

### Co jeszcze może się pojawić (często pomijane)

#### oro/product/
- PDP
- PLP
- gallery
- price block
- variants

Docs: [Product customization](https://doc.oroinc.com/frontend/storefront/product/)

#### oro/customer/
- login
- register
- account pages

Docs: [Customer pages](https://doc.oroinc.com/frontend/storefront/customer/)

#### oro/cms/
- landing pages
- CMS blocks

Docs: [CMS customization](https://doc.oroinc.com/frontend/storefront/cms/)

Dodajesz tylko jeśli faktycznie robisz override.

---

## 7. Zasady dla Frontend Developera

- Zawsze pytaj: „Z którego bundle’a pochodzi element HTML?”
- components/ → FrontendBundle (UI)
- layout/ → FrontendBundle (strukturę strony)
- settings/ → FrontendBundle (design system)
- oro/form/ → OroFormBundle (formularze)
- oro/checkout/ → OroCheckoutBundle (checkout)

### Częste błędy:
- Wrzucone wszystko do components/
- Formularze stylowane globalnie
- Checkout stylowany jak zwykły layout
- Brak podziału → chaos po 3 miesiącach

### Typowa proporcja w realnym projekcie:
- 70% zmian → settings/
- 20% zmian → components/
- 10% zmian → oro/*

---

## 8. Build SCSS

Po zmianach w SCSS zawsze uruchamiaj:

```bash
bin/console oro:assets:build
```

- Theme → SCSS = gdzie decydujesz o wyglądzie
- Assets → Build = narzędzie do generowania CSS/JS, nie do zmian wyglądu

