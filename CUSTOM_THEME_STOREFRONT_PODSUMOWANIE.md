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
| **3.3** | **Build** — `npm run build` (w kontenerze z Node/npm w Dockerze) |
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

## Ważne ścieżki i pliki

- Instrukcja krok po kroku: `CUSTOM_THEME_STOREFRONT.md`
- Skrypt obejścia (gdy strona ładuje default zamiast custom_storefront): `orocommerce-application/scripts/use-custom-storefront-css.sh`
- Theme: `custom_storefront`, bundle: `CustomStorefrontThemeBundle`, alias: `customstorefronttheme`
