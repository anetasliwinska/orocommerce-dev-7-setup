# Custom theme storefrontu — co zostało zrobione, co nie (stan na podstawie chatu)

Skrót: które kroki z instrukcji `CUSTOM_THEME_STOREFRONT.md` są wykonane, a które opcjonalnie można dodać później. Przydatne przy kolejnych chatach / wdrożeniach.

---

## Wykonane

| Krok | Opis |
|------|------|
| **1** | **Bundle** — utworzony `CustomStorefrontThemeBundle.php` i struktura w `src/Custom/Bundle/StorefrontThemeBundle/` |
| **1.2** | **Rejestracja** — bundle dodany w `AppKernel.php` |
| **2** | **theme.yml** — utworzony w `Resources/views/layouts/custom_storefront/theme.yml` (parent: default, label: Custom Storefront) |
| **3.1** | **SCSS** — plik `Resources/public/custom_storefront/scss/styles.scss` z własnymi stylami |
| **3.2** | **assets.yml** — wpis do `styles.inputs` z ścieżką `bundles/customstorefronttheme/custom_storefront/scss/styles.scss` |
| **3.3** | **Instalacja assetów** — `oro:assets:install --symlink --env=dev` |
| **3.3** | **Build** — `php bin/console oro:assets:build custom_storefront` |
| **7.1** | **config.yml** — `oro_layout.enabled_themes`: default, custom_storefront |
| **7.1** | **config.yml** — `oro_layout.active_theme: custom_storefront` (dla Community bez menu Websites) |
| **7.2** | **Theme Configuration** — utworzona konfiguracja „Custom Storefront (dev)” w System → Theme Configurations |
| **7.2** | **Theme w konfiguracji** — w System → Configuration → Commerce → Design → Theme ustawione „Custom Storefront (dev)” |
| **9.0.1** | **Skrypt** — utworzony `scripts/use-custom-storefront-css.sh`, uruchomiony (symlink default → custom_storefront), style działają na stronie |

---

## Niewykonane / opcjonalne

| Krok | Opis |
|------|------|
| **4** | **Własny JS (opcjonalnie)** — brak `config/jsmodules.yml` i plików JS w theme (można dodać później) |
| **5** | **Override layout (YAML)** — brak lub niepełny `Resources/views/layouts/custom_storefront/oro_frontend_root/layout.yml` (wcześniej błąd przy pustych plikach; jeśli chcesz zmieniać bloki/klasy, dopisz tam poprawne `actions`) |
| **6** | **Override Twig (block themes)** — brak własnego `layout.html.twig` i `@setBlockTheme` w layout.yml (opcjonalne) |
| **7** | **Scope per Website** — w Community nie ma menu Websites; theme wymuszona przez `active_theme` w config.yml |

---

## Podsumowanie

- **Zrobione:** bundle, theme, SCSS, assets, build, włączenie theme w config i w panelu, obejście symlinkiem — na stronie są Twoje style.
- **Na później (opcjonalnie):** własny JS (krok 4), zmiany layoutu YAML (krok 5), override Twiga (krok 6).

---

## Dwa typowe problemy i rozwiązania

### 1. Strona ładuje style z theme „default” zamiast „custom_storefront”
- **Skrypt (z katalogu orocommerce-dev):** `./scripts/fix-theme-configuration-db.sh` — ustawia `theme_configuration = 2` w bazie i czyści cache.
- **Obejście bez zmiany theme w panelu:** `orocommerce-application/scripts/use-custom-storefront-css.sh` — symlink `build/default/css/styles.css` → `custom_storefront`, wtedy adres w HTML zostaje „default”, ale treść to Twoje style.

### 2. Moje style z pliku SCSS nie trafiają do wynikowego CSS
- **Przyczyna:** Build SCSS szuka plików w `public/bundles/customstorefronttheme/...`. Jeśli nie ma tam katalogu (bo nie uruchomiono instalacji assetów), import Twojego `styles.scss` się nie ładuje i końcowy `styles.css` nie zawiera Twoich reguł.
- **Rozwiązanie — prawidłowa kolejność:**
  1. Zainstaluj assety: `php bin/console oro:assets:install --symlink --env=dev` (z katalogu `orocommerce-application` albo w kontenerze PHP).
  2. Dopiero potem: `php bin/console oro:assets:build custom_storefront` (lub z `--watch`).

---

## Ważne ścieżki i pliki

- Instrukcja krok po kroku: `CUSTOM_THEME_STOREFRONT.md`
- Skrypt: ustawienie theme w bazie: `scripts/fix-theme-configuration-db.sh`
- Theme: `custom_storefront`, bundle: `CustomStorefrontThemeBundle`, alias: `customstorefronttheme`
