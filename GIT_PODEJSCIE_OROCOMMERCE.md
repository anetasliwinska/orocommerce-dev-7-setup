# Podejście do Gita dla OroCommerce: setup vs pełny kod aplikacji

Ten plik zapisuje **zmianę podejścia**, gdy dochodzisz do wniosku, że długofalowo chcesz utrzymywać **cały kod `orocommerce-application`** w swoim repo (a nie tylko instrukcje/overlay).

## TL;DR

- **Repo 1 (setup)**: `orocommerce-dev-setup` – Docker/WSL/Nginx/PHP, instrukcje, pliki w `env/`, bez commitowania `orocommerce-application/`.
- **Repo 2 (application)**: np. `orocommerce-application-hy` – **pełny kod OroCommerce** + Twoje customizacje (bundle/theme w `src/...`).
- W `orocommerce-application/` **nie rób `git init`**, bo to już jest repo. Najczyściej: **push istniejącego repo do Twojego GitHuba**.

---

## Dlaczego 2 repo (polecane)

- **Utrzymywalność**: customizacje żyją obok kodu aplikacji, normalny workflow (branche, PR-y, konflikty).
- **Aktualizacje Oro**: masz `upstream` (Oro) i `origin` (Twoje repo) – aktualizujesz przez merge tagów/releasów.
- **Setup nie miesza się z kodem**: pliki dockerowe i instrukcje nie “zaśmiecają” historii aplikacji.

---

## Stan startowy (typowe)

Często jest tak, że `orocommerce-application/`:
- jest checkoutowany na tagu (np. `6.1.6`) → **detached HEAD**
- ma lokalne modyfikacje w `public/` i `var/` (efekt uruchomień/instalacji) – **tego zwykle nie chcesz commitować**

Sprawdź:

```bash
cd /home/anetk/orocommerce-dev/orocommerce-application
git status -sb
git show -s --format='%H %D' HEAD
git remote -v
```

---

## Krok po kroku: utworzenie własnego repo z pełnym `orocommerce-application`

### 0) Załóż puste repo na GitHubie

Na GitHubie utwórz nowe (najlepiej private) repo, np.:
- `orocommerce-application-hy`

Nie dodawaj README/.gitignore/licencji (ma być puste).

### 1) Wyczyść przypadkowe zmiany runtime (jeśli są)

W katalogu aplikacji:

```bash
cd /home/anetk/orocommerce-dev/orocommerce-application
git restore .
```

Jeśli masz dodatkowe “śmieci” (nowe pliki po instalacji) i wiesz co robisz:

```bash
git clean -fd
```

### 2) Wyjdź z detached HEAD i utwórz branch od taga

Jeśli bazujesz na tagu (np. `6.1.6`):

```bash
git switch -c main 6.1.6
```

*(Jeśli chcesz inny branch bazowy, np. `develop`, zmień nazwę odpowiednio.)*

### 3) Ustaw remotes: upstream (Oro) + origin (Twoje repo)

Zwykle masz `origin` ustawione na `oroinc/orocommerce-application`. Zmieniamy to tak:

```bash
git remote rename origin upstream
git remote add origin https://github.com/TWOJ_LOGIN/orocommerce-application-hy.git
```

Sprawdź:

```bash
git remote -v
```

### 4) Push do Twojego repo

```bash
git push -u origin main
```

Od teraz pracujesz normalnie: tworzysz branche pod feature’y, commitujesz Twoje bundle/theme w `src/...`.

---

## Jak aktualizować Oro (upstream)

### Wariant A: merge konkretnego taga (prosto i czytelnie)

```bash
cd /home/anetk/orocommerce-dev/orocommerce-application
git fetch upstream --tags
git merge 6.1.7
git push
```

### Wariant B: merge gałęzi upstream (jeśli pracujesz na branchach upstream)

```bash
git fetch upstream
git merge upstream/master   # albo upstream/main – zależnie jak jest w upstream
git push
```

W praktyce przy Oro najczęściej wygodniej jest **merge tagów wersji** (LTS), bo masz “kamienie milowe” aktualizacji.

---

## Co commitować / czego unikać

- **Commituj**:
  - `src/...` (Twoje bundle/theme)
  - pliki konfiguracyjne, które są częścią aplikacji i mają sens w repo
- **Zazwyczaj NIE commituj**:
  - `var/` (cache, logi, sesje)
  - rzeczy generowane w `public/` (chyba że masz konkretny powód i rozumiesz konsekwencje)
  - sekrety (`*.local`, tokeny, hasła do zewnętrznych usług)

W repo “setup” trzymaj bezpieczne domyślne konfiguracje (jak `env/orocommerce-application/.env-app.local`) oraz instrukcje, a sekrety trzymaj lokalnie.

---

## Co z repo `orocommerce-dev-setup`?

Zostaje jako:
- instrukcja uruchomienia (WSL/Docker),
- pliki dockerowe,
- `env/...` jako “template” konfiguracji,
- krok w instrukcji: klonujesz **Twoje repo aplikacji** do `orocommerce-application/`.

