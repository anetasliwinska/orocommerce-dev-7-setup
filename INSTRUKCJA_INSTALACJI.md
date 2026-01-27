# Instrukcja instalacji i uruchamiania OroCommerce ze Storefrontem w środowisku WSL na Windows

---

## Spis Treści

1. [Wymagania wstępne](#wymagania-wstępne)
2. [Struktura projektu](#struktura-projektu)
3. [Instalacja WSL2 i Ubuntu](#instalacja-wsl2-i-ubuntu)
4. [Integracja Ubuntu z Cursorem](#integracja-ubuntu-z-cursorem-opcjonalne-ale-zalecane)
5. [Instalacja Docker](#instalacja-docker)
6. [Instalacja Node.js i npm](#instalacja-nodejs-i-npm)
7. [Pobranie projektu](#pobranie-projektu)
8. [Konfiguracja projektu](#konfiguracja-projektu)
9. [Uruchomienie projektu](#uruchomienie-projektu)
10. [Instalacja OroCommerce](#instalacja-orocommerce)
11. [Budowa storefrontu](#budowa-storefrontu)
12. [Dostęp do aplikacji](#dostęp-do-aplikacji)
13. [Rozwiązywanie problemów](#rozwiązywanie-problemów)
14. [Przydatne komendy](#przydatne-komendy)
15. [Gratulacje](#gratulacje)

**Numeracja:** Rozdziały mają numery **1.–15.** W sekcjach 3, 5, 6, 7, 8, 9, 10, 11, 12 kroki wykonawcze mają formę **Krok X.Y** — X odpowiada numerowi sekcji (3, 5, 6, 7, 8, 9, 10, 11, 12), Y to podkrok. Sekcja 4 (Integracja Cursor) nie ma numeracji „Krok”.

---

## 1. Wymagania wstępne

Przed rozpoczęciem upewnij się, że masz:

- System Windows 10 (wersja 2004 lub nowsza) lub Windows 11
- Co najmniej 8 GB RAM (zalecane 16 GB)
- Co najmniej 20 GB wolnego miejsca na dysku
- Połączenie z internetem
- Konto administratora w systemie Windows

---

## 2. Struktura projektu

Przed rozpoczęciem instalacji, upewnij się, że masz następującą strukturę projektu.

W tym podejściu trzymamy **dwa repozytoria**:
- **repo setup** (to repo): Docker/WSL/Nginx/PHP + pliki w `env/`
- **repo aplikacji** (osobne): pełny kod `orocommerce-application` (OroCommerce) + Twoje modyfikacje

Katalog `orocommerce-application/` jest więc **klonowany jako osobne repo** (np. z Twojego repo `orocommerce-application-custom`) i leży obok plików dockerowych.

```
orocommerce-dev/
├── env/
│   └── orocommerce-application/
│       └── .env-app.local
├── docker/
│   └── php/
│       └── Dockerfile
├── nginx/
│   └── conf.d/
│       └── default.conf
├── php/
│   └── conf.d/
│       └── memory-limit.ini
└── docker-compose.yml
```

### Pliki konfiguracyjne

Jeśli klonujesz repo setup, te pliki konfiguracyjne są już w projekcie. Poniżej ich zawartość jest podana jako referencja (albo na wypadek, gdybyś odtwarzał konfigurację ręcznie):

#### 1. `docker-compose.yml` (główny katalog projektu)

```yaml
services:
  php:
    build:
      context: .
      dockerfile: docker/php/Dockerfile
    container_name: orocommerce-php
    volumes:
      - ./orocommerce-application:/var/www/orocommerce
      - ./php/conf.d/memory-limit.ini:/usr/local/etc/php/conf.d/memory-limit.ini
    networks:
      - orocommerce-net
    environment:
      ORO_ENV: dev
      ORO_DEBUG: "1"

  nginx:
    image: nginx:1.25
    container_name: orocommerce-nginx
    ports:
      - "8080:80"
    volumes:
      - ./orocommerce-application:/var/www/orocommerce
      - ./nginx/conf.d:/etc/nginx/conf.d
    depends_on:
      - php
    networks:
      - orocommerce-net

  pgsql:
    image: oroinc/pgsql:17.4-alpine
    environment:
      POSTGRES_USER: oro_db_user
      POSTGRES_DB: oro_db
      POSTGRES_PASSWORD: oro_db_pass
      POSTGRES_ROOT_PASSWORD: oro_db_pass
    volumes:
      - postgres:/var/lib/postgresql/data
    networks:
      - orocommerce-net

  redis:
    image: redis:7
    ports:
      - "6379:6379"
    networks:
      - orocommerce-net

  gotenberg:
    image: gotenberg/gotenberg:8
    ports:
      - "3000:3000"
    networks:
      - orocommerce-net

networks:
  orocommerce-net:

volumes:
  db_data:
  postgres:
```

#### 2. `docker/php/Dockerfile`

```dockerfile
FROM php:8.4-fpm

# systemowe biblioteki
RUN apt-get update && apt-get install -y \
    libpq-dev \
    libzip-dev \
    libicu-dev \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    git \
    unzip \
    curl

# PHP extensions wymagane przez Oro
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install \
        pdo_pgsql \
        pgsql \
        intl \
        zip \
        gd \
        pcntl \
        opcache

# Node.js 22 + npm (wymagane do budowy assetów Oro 6.1)
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && node -v \
    && npm -v

# Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/orocommerce
```

#### 3. `nginx/conf.d/default.conf`

```nginx
server {
    listen 80;

    server_name localhost;

    root /var/www/orocommerce/public;
    index index.php index.html;

    location / {
        try_files $uri /index.php$is_args$args;
    }

    location ~ \.php$ {
        fastcgi_pass php:9000;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param APP_ENV dev;
    }
}
```

#### 4. `php/conf.d/memory-limit.ini`

```ini
memory_limit = 1024M
```

> **Uwaga:** Katalog `orocommerce-application` zostanie pobrany z repozytorium Git w późniejszym kroku (patrz sekcja "Pobranie projektu").

---

## 3. Instalacja WSL2 i Ubuntu

### Krok 3.1: Włączenie WSL w Windows

1. **Otwórz PowerShell jako Administrator:**

   - Kliknij prawym przyciskiem myszy na przycisk Start
   - Wybierz "Windows PowerShell (Administrator)" lub "Terminal (Administrator)"
   - Jeśli pojawi się okno UAC (Kontrola konta użytkownika), kliknij "Tak"

2. **Włącz funkcję WSL:**
   Skopiuj i wklej poniższą komendę do PowerShell, a następnie naciśnij Enter:

   ```powershell
   wsl --install
   ```

3. **Jeśli komenda nie działa, wykonaj ręcznie:**

   ```powershell
   dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
   dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
   ```

4. **Zrestartuj komputer** (będzie to wymagane)

### Krok 3.2: Instalacja Ubuntu

1. **Po restarcie, otwórz PowerShell jako Administrator** (jeśli jeszcze nie jest otwarty):

   - Kliknij prawym przyciskiem myszy na przycisk Start
   - Wybierz "Windows PowerShell (Administrator)" lub "Terminal (Administrator)"

2. **Zainstaluj Ubuntu używając komendy WSL:**

   ```powershell
   wsl --install -d Ubuntu
   ```

   Ta komenda zainstaluje najnowszą dostępną wersję Ubuntu LTS (Long Term Support), która jest zalecana do użytku.

3. **Poczekaj na zakończenie instalacji:**

   - Instalacja może potrwać kilka minut
   - Zostaniesz poproszony o utworzenie konta użytkownika

4. **Skonfiguruj Ubuntu:**

   - Po zakończeniu instalacji Ubuntu uruchomi się automatycznie
   - Utwórz nazwę użytkownika (może być małymi literami, bez spacji)
   - Utwórz hasło (wpisz je dwukrotnie - nie zobaczysz znaków podczas wpisywania, to normalne)

5. **Sprawdź czy Ubuntu jest zainstalowane:**

   ```powershell
   wsl --list --verbose
   ```

   Powinieneś zobaczyć Ubuntu na liście z wersją WSL (powinno być 2).

### Krok 3.3: Pierwsze uruchomienie Ubuntu

Po zakończeniu instalacji, musisz uruchomić Ubuntu. Masz kilka opcji:

**Opcja A: Uruchomienie z PowerShell (zalecane):**

1. **Otwórz PowerShell** (może być zwykły, nie musi być jako administrator)

2. **Uruchom Ubuntu używając komendy:**

   ```powershell
   wsl -d Ubuntu
   ```

   Lub jeśli Ubuntu jest domyślną dystrybucją, możesz użyć:

   ```powershell
   wsl
   ```

**Opcja B: Uruchomienie przez Windows Terminal:**

1. **Otwórz Windows Terminal** (lub PowerShell/Terminal)

2. **Kliknij strzałkę obok przycisku "+" w górnej części okna**

3. **Wybierz "Ubuntu" z listy dostępnych dystrybucji**

4. **Ubuntu otworzy się w nowej zakładce**

**Opcja C: Uruchomienie z menu Start:**

1. **Naciśnij klawisz Windows**

2. **Wpisz "Ubuntu" w wyszukiwarce**

3. **Kliknij na aplikację "Ubuntu"**

**Po uruchomieniu Ubuntu:**

- Jeśli to pierwsze uruchomienie, zostaniesz poproszony o utworzenie konta użytkownika i hasła
- Utwórz nazwę użytkownika (może być małymi literami, bez spacji)
- Utwórz hasło (wpisz je dwukrotnie - nie zobaczysz znaków podczas wpisywania, to normalne)

### Krok 3.4: Aktualizacja Ubuntu

Po pierwszym uruchomieniu Ubuntu, wykonaj aktualizację systemu:

```bash
sudo apt update
sudo apt upgrade -y
```

---

## 4. Integracja Ubuntu z Cursorem (opcjonalne, ale zalecane)

Jeśli używasz edytora Cursor (lub VS Code), możesz zintegrować go z Ubuntu (WSL), co znacznie ułatwi pracę z projektem.

### Instalacja rozszerzenia WSL (zalecane)

1. **Otwórz Cursor**

2. **Zainstaluj rozszerzenie WSL:**

   - Naciśnij `Ctrl + Shift + X` aby otworzyć panel rozszerzeń
   - Wyszukaj "WSL" lub "Remote - WSL"
   - Zainstaluj rozszerzenie "Remote - WSL" (autor: Microsoft)

3. **Po instalacji zrestartuj Cursor** (jeśli zostaniesz o to poproszony)

> **Uwaga:** Rozszerzenie WSL ułatwia pracę z plikami w WSL i automatycznie konfiguruje terminal oraz integrację z systemem plików Ubuntu.

### Połączenie z WSL przez Remote (jedyny zalecany sposób)

To jest **jedyna zalecana metoda**, bo utrzymuje jeden spójny kontekst workspaca (i historii rozmów z AI).

1. **Otwórz Cursor**
2. **Kliknij ikonę Remote/WSL w lewym dolnym rogu** (np. `><` / „Remote”).
3. Wybierz: **WSL: Ubuntu** (lub Twoją dystrybucję).
4. Gdy otworzy się okno połączone z WSL:
   - Wejdź w `File` → `Open Folder`
   - Wybierz folder domowy: `/home/TWOJA_NAZWA_UŻYTKOWNIKA`
   - Następnie otwórz projekt, np. `/home/TWOJA_NAZWA_UŻYTKOWNIKA/orocommerce-dev`

> **Wskazówka:** Po połączeniu z WSL w pasku statusu (lewym dolnym rogu) zwykle widać informację, że jesteś w trybie WSL/Remote.

### Terminal w Cursorze (w sesji WSL)

1. **Otwórz Cursor**

2. **Otwórz terminal w Cursorze:**

   - Naciśnij `Ctrl + ~` (tylda) lub
   - Przejdź do menu: `Terminal` → `New Terminal`

3. **Upewnij się, że terminal działa w WSL:**

   - Kliknij strzałkę obok ikony `+` w terminalu
   - Wybierz "Ubuntu" z listy (jeśli nie wybrało się automatycznie)

4. **Sprawdź czy terminal używa Ubuntu:**
   ```bash
   pwd
   ```
   Powinien wyświetlić się katalog domowy Ubuntu (np. `/home/TWOJA_NAZWA_UŻYTKOWNIKA`)

### Korzyści z integracji

- **Bezpośredni dostęp do plików** - możesz edytować pliki projektu bezpośrednio w Cursorze
- **Terminal zintegrowany** - możesz wykonywać komendy Docker, Git, npm bezpośrednio w terminalu Cursora
- **IntelliSense i autouzupełnianie** - lepsze wsparcie dla kodu PHP, JavaScript, YAML
- **Debugowanie** - możliwość debugowania aplikacji bezpośrednio z Cursora
- **Git integration** - łatwiejsze zarządzanie repozytorium Git

### Sprawdzenie integracji

Po otwarciu projektu w Cursorze, sprawdź czy:

1. **Terminal używa Ubuntu:**

   - Otwórz terminal (`Ctrl + ~`)
   - Sprawdź czy widzisz prompt Ubuntu (np. `user@hostname:~/orocommerce-dev$`)

2. **Pliki są dostępne:**

   - Sprawdź czy widzisz strukturę projektu w eksploratorze plików
   - Spróbuj otworzyć plik `docker-compose.yml`

3. **Komendy działają:**
   ```bash
   docker compose ps
   ```
   Powinna wyświetlić się lista kontenerów (jeśli są uruchomione)

### Ważne: Zachowanie historii konwersacji z AI

**Aby zachować historię konwersacji z AI w Cursorze, zawsze:**

1. **Zawsze łącz się z WSL przez Remote** (lewym dolnym rogu → **WSL: Ubuntu**) i dopiero wtedy otwieraj foldery przez `File` → `Open Folder` (ścieżki linuksowe typu `/home/...`).
2. **Nie mieszaj metod otwierania tego samego projektu**, bo Cursor może utworzyć **inny workspace** i rozdzielić historię rozmów:
   - Nie używaj `File` → `Open Folder` z użyciem ścieżek Windows/UNC typu `\\wsl.localhost\...` lub `\\wsl$\...`
   - Nie uruchamiaj edytora z terminala w sposób, który tworzy nowy kontekst (np. różne skróty/komendy)
3. **Po restarcie komputera**: ponownie wybierz Remote → WSL → otwórz ten sam folder projektu w WSL.
4. **Jeśli historia zaginęła**: historia jest przechowywana na Windows w `%APPDATA%\Cursor\User\` (m.in. `globalStorage` / `workspaceStorage`) — warto robić kopie zapasowe tego katalogu.

> **Uwaga:** Historia konwersacji jest powiązana z identyfikatorem workspaca. Zmiana sposobu otwierania (UNC vs Remote WSL) może utworzyć drugi, „równoległy” workspace.

---

## 5. Instalacja Docker

### Krok 5.1: Instalacja Docker w Ubuntu (WSL)

1. **Otwórz Ubuntu (WSL)** - użyj jednej z metod opisanych w Kroku 1.3

2. **Zaktualizuj listę pakietów:**

   ```bash
   sudo apt update
   ```

3. **Zainstaluj wymagane pakiety:**

   ```bash
   sudo apt install -y ca-certificates curl gnupg lsb-release
   ```

4. **Dodaj oficjalny klucz GPG Dockera:**

   ```bash
   sudo mkdir -p /etc/apt/keyrings
   curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
   ```

5. **Dodaj repozytorium Dockera:**

   ```bash
   echo \
     "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
     $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
   ```

6. **Zaktualizuj listę pakietów ponownie:**

   ```bash
   sudo apt update
   ```

7. **Zainstaluj Docker Engine i Docker Compose:**

   ```bash
   sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
   ```

8. **Dodaj swojego użytkownika do grupy docker (aby móc używać Dockera bez sudo):**

   ```bash
   sudo usermod -aG docker $USER
   ```

9. **Zrestartuj sesję WSL:**
   - Zamknij Ubuntu
   - Otwórz Ubuntu ponownie

### Krok 5.2: Konfiguracja Dockera w WSL

1. **Uruchom usługę Docker:**

   ```bash
   sudo service docker start
   ```

2. **Ustaw automatyczne uruchamianie Dockera przy starcie WSL (opcjonalne):**

   > **Uwaga:** Ten krok jest opcjonalny. Jeśli go pominiesz, będziesz musiał ręcznie uruchamiać Dockera za każdym razem komendą `sudo service docker start`. Jeśli chcesz, aby Docker uruchamiał się automatycznie przy starcie WSL, wykonaj poniższe kroki.

   Dodaj następującą linię do pliku `~/.bashrc`:

   ```bash
   vim ~/.bashrc
   ```

   Na końcu pliku dodaj:

   ```bash
   # Automatyczne uruchamianie Dockera
   if service docker status 2>&1 | grep -q "is not running"; then
       sudo service docker start > /dev/null 2>&1
   fi
   ```

   Zapisz plik:

   - Naciśnij `Esc`
   - Wpisz `:wq` i naciśnij `Enter`

3. **Zastosuj zmiany (tylko jeśli wykonałeś krok 2):**
   ```bash
   source ~/.bashrc
   ```

### Krok 5.3: Weryfikacja instalacji Docker

Sprawdź czy Docker działa:

```bash
docker --version
docker compose version
```

Powinny wyświetlić się numery wersji. Jeśli pojawi się błąd uprawnień, upewnij się, że:

- Dodałeś użytkownika do grupy docker
- Zrestartowałeś sesję WSL
- Uruchomiłeś usługę Docker (`sudo service docker start`)

---

## 6. Instalacja Node.js i npm

### Krok 6.1: Instalacja Node.js przez nvm (zalecane)

> **Uwaga:** Budowa storefrontu w tej instrukcji jest wykonywana **w kontenerze PHP** (sekcja 11). Kontener ma Node.js dzięki Dockerfile (sekcja „Struktura projektu”). Instalacja Node.js i npm na hoście (poniżej) jest **opcjonalna** — przydatna m.in. gdy chcesz uruchamiać polecenia npm poza kontenerem.

1. **Otwórz Ubuntu (WSL)**

2. **Zainstaluj nvm (Node Version Manager):**

   ```bash
   curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
   ```

3. **Zamknij i ponownie otwórz Ubuntu** (lub wykonaj):

   ```bash
   source ~/.bashrc
   ```

4. **Zainstaluj Node.js w wersji 22.x (najnowsza z zakresu 22):**

   ```bash
   nvm install 22
   nvm use 22
   nvm alias default 22
   ```

   > **Uwaga:** Projekt wymaga Node.js w wersji >=22.9.0 <23. Instalacja `nvm install 22` zainstaluje najnowszą dostępną wersję 22.x, która spełnia te wymagania.

5. **Zainstaluj npm w wersji 10.x (najnowsza z zakresu 10):**

   ```bash
   npm install -g npm@10
   ```

   > **Uwaga:** Projekt wymaga npm w wersji >=10.8.3 <11. Instalacja `npm@10` zainstaluje najnowszą dostępną wersję 10.x, która spełnia te wymagania.

6. **Sprawdź wersje:**

   ```bash
   node --version
   npm --version
   ```

   Powinny wyświetlić się:

   - Node.js: v22.x.x (gdzie x.x to najnowsza wersja z zakresu 22)
   - npm: 10.x.x (gdzie x.x to najnowsza wersja z zakresu 10)

---

## 7. Pobranie projektu

### Krok 7.1: Klonowanie repo setup (Docker/konfiguracja)

1. **Przejdź do katalogu domowego (zalecane):**

   ```bash
   cd ~
   ```

   > **Zalecenie:** Najlepiej utworzyć projekt bezpośrednio w folderze domowym (`~`), co ułatwia dostęp i zarządzanie projektem.

2. **Sklonuj repo setup:**

   ```bash
   git clone <URL_REPO_SETUP> orocommerce-dev
   cd ~/orocommerce-dev
   ```

   > **Uwaga:** Zastąp `<URL_REPO_SETUP>` adresem do repo z dockerem i instrukcjami (np. `orocommerce-dev-setup`).

### Krok 7.2: Klonowanie repo aplikacji (`orocommerce-application`)

1. **Sklonuj Twoje repo aplikacji do katalogu projektu:**

   ```bash
   cd ~/orocommerce-dev
   git clone <URL_TWOJEGO_REPO_APLIKACJI> orocommerce-application
   ```

   > **Uwaga:** Zastąp `<URL_TWOJEGO_REPO_APLIKACJI>` adresem do Twojego repo z pełnym kodem OroCommerce + zmianami (np. `orocommerce-application-custom`).

2. **(Opcjonalnie) Dodaj `upstream` do oficjalnego Oro, żeby łatwiej aktualizować bazę kodu:**

   ```bash
   cd ~/orocommerce-dev/orocommerce-application
   git remote add upstream https://github.com/oroinc/orocommerce-application.git
   git fetch upstream --tags
   ```

   > **Uwaga:** Szczegóły podejścia `origin` (Twoje repo) + `upstream` (Oro) są opisane w `GIT_PODEJSCIE_OROCOMMERCE.md`.

3. **Sprawdź strukturę projektu:**

   ```bash
   ls -la
   ```

   Powinieneś zobaczyć:

   - `docker/`
   - `nginx/`
   - `php/`
   - `docker-compose.yml`
   - `orocommerce-application/` (nowo sklonowany katalog)

> **Uwaga:** Projekt znajduje się w katalogu domowym: `~/orocommerce-dev`. W dalszych krokach będziemy używać tej lokalizacji.

---

## 8. Konfiguracja projektu

### Krok 8.1: Przejście do katalogu projektu

Upewnij się, że jesteś w katalogu projektu:

```bash
cd ~/orocommerce-dev
```

### Krok 8.2: Sprawdzenie struktury projektu

Sprawdź czy masz poprawną strukturę projektu (patrz sekcja "Struktura projektu" na początku instrukcji):

```bash
ls -la
```

Powinieneś zobaczyć:

- `docker/` - katalog z Dockerfile dla PHP
- `nginx/` - katalog z konfiguracją nginx
- `php/` - katalog z konfiguracją PHP
- `docker-compose.yml` - główny plik konfiguracyjny Docker Compose
- `orocommerce-application/` - katalog z aplikacją OroCommerce (sklonowany z Git)

### Krok 8.3: Konfiguracja pliku .env-app.local

Plik `.env-app.local` trzymamy w repo setup w katalogu `env/` jako template, a potem kopiujemy go do repo aplikacji.
Tego pliku **nie commitujemy** (to konfiguracja lokalna, często zawiera dane dostępowe).

1. **W głównym katalogu projektu skopiuj plik do aplikacji:**

   ```bash
   cd ~/orocommerce-dev
   cp env/orocommerce-application/.env-app.local orocommerce-application/.env-app.local
   ```

2. **(Opcjonalnie) Podejrzyj zawartość i dostosuj pod siebie:**

   ```bash
   nano orocommerce-application/.env-app.local
   ```

---

## 9. Uruchomienie projektu

### Krok 9.1: Budowa kontenerów Docker

1. **Upewnij się, że jesteś w głównym katalogu projektu:**

   ```bash
   cd ~/orocommerce-dev
   pwd
   ```

   Powinien wyświetlić się: `/home/TWOJA_NAZWA_UŻYTKOWNIKA/orocommerce-dev`

2. **Zbuduj obrazy Docker:**

   ```bash
   docker compose build
   ```

   > **Uwaga:** To może potrwać 10-20 minut przy pierwszym uruchomieniu, ponieważ Docker pobiera i buduje wszystkie potrzebne komponenty.

### Krok 9.2: Uruchomienie kontenerów

1. **Uruchom wszystkie kontenery:**

   ```bash
   docker compose up -d
   ```

2. **Sprawdź status kontenerów:**

   ```bash
   docker compose ps
   ```

   Powinny być uruchomione następujące kontenery:

   - `orocommerce-php`
   - `orocommerce-nginx`
   - `pgsql` (PostgreSQL)
   - `redis`
   - `gotenberg`

3. **Jeśli któryś kontener nie działa, sprawdź logi:**
   ```bash
   docker compose logs [nazwa_kontenera]
   ```

---

## 10. Instalacja OroCommerce

### Krok 10.1: Instalacja zależności PHP (Composer)

1. **Wejdź do kontenera PHP:**

   ```bash
   docker compose exec php bash
   ```

2. **Przejdź do katalogu aplikacji:**

   ```bash
   cd /var/www/orocommerce
   ```

3. **Zainstaluj zależności Composer:**

   ```bash
   composer install --no-interaction --prefer-dist
   ```

   > **Uwaga:** To może potrwać 15-30 minut, ponieważ pobiera wszystkie pakiety PHP wymagane przez OroCommerce.

4. **Poczekaj na zakończenie instalacji**

### Krok 10.2: Konfiguracja uprawnień

1. **Nadal w kontenerze PHP, sprawdź aktualne uprawnienia:**

   ```bash
   ls -ld var/ public/
   ```

   Możesz zobaczyć uprawnienia inne niż 777 (np. 755, 775), co może powodować problemy z zapisem plików przez aplikację.

2. **Ustaw uprawnienia na 777 (pełny dostęp dla wszystkich):**

   ```bash
   chmod -R 777 var/
   chmod -R 777 public/
   ```

   > **Uwaga:** Uprawnienia 777 dają pełny dostęp do zapisu i odczytu dla wszystkich użytkowników. Jest to wymagane, aby aplikacja OroCommerce mogła zapisywać pliki cache, logi i inne dane w katalogach `var/` i `public/`.

3. **Sprawdź czy uprawnienia zostały zmienione:**

   ```bash
   ls -ld var/ public/
   ```

   Powinieneś zobaczyć `drwxrwxrwx` (777) dla obu katalogów.

4. **Wyjdź z kontenera:**

   ```bash
   exit
   ```

### Krok 10.3: Instalacja aplikacji OroCommerce

1. **Wejdź ponownie do kontenera PHP:**

   ```bash
   docker compose exec php bash
   ```

2. **Przejdź do katalogu aplikacji:**

   ```bash
   cd /var/www/orocommerce
   ```

3. **Uruchom instalator OroCommerce:**

   ```bash
   php bin/console oro:install --env=dev --timeout=0 --no-interaction \
     --application-url=http://localhost:8080 \
     --organization-name="Moja Firma" \
     --user-name=admin \
     --user-email=admin@example.com \
     --user-firstname=Admin \
     --user-lastname=User \
     --user-password=admin123 \
     --language=en \
     --formatting-code=en_US \
     --currency=USD \
     --no-sample-data
   ```

   > **Uwaga:** Instalacja może potrwać 10-20 minut. Nie zamykaj terminala podczas instalacji.

   **Parametry do zmiany (opcjonalnie):**

   - `--organization-name` - nazwa Twojej organizacji
   - `--user-name` - nazwa użytkownika administratora
   - `--user-email` - email administratora
   - `--user-password` - hasło administratora (zmień na bezpieczne!)
   - `--language` - język interfejsu (pl dla polskiego)
   - `--formatting-code` - kod formatowania (pl_PL dla polskiego)
   - `--currency` - waluta (PLN dla polskich złotych)

4. **Poczekaj na zakończenie instalacji**

5. **Wyjdź z kontenera:**
   ```bash
   exit
   ```

### Krok 10.4: Weryfikacja instalacji

1. **Sprawdź czy baza danych została utworzona:**

   ```bash
   docker compose exec pgsql psql -U oro_db_user -d oro_db -c "\dt" | head -20
   ```

2. **Sprawdź logi aplikacji:**
   ```bash
   docker compose logs php | tail -50
   ```

---

## 11. Budowa storefrontu

**Wymaganie:** Kontener PHP musi zawierać Node.js i npm (z Dockerfile – patrz sekcja „Struktura projektu”). Jeśli dopiero dodałeś Node do Dockerfile, przebuduj obraz i uruchom ponownie kontenery:

```bash
   docker compose build php
   docker compose up -d
```

### Krok 11.1: Instalacja zależności Node.js

1. **Wejdź do kontenera PHP:**

   ```bash
   docker compose exec php bash
   ```

2. **Przejdź do katalogu aplikacji:**

   ```bash
   cd /var/www/orocommerce
   ```

3. **Zainstaluj zależności npm:**

   ```bash
   npm install
   ```

   > **Uwaga:** To może potrwać 5-10 minut.

### Krok 11.2: Budowa zasobów frontendowych

1. **Nadal w kontenerze PHP, zbuduj zasoby frontendowe:**

   ```bash
   php bin/console oro:assets:build
   ```

   > **Uwaga:** To może potrwać 5–10 minut.

2. **Lub w trybie deweloperskim (z automatycznym odświeżaniem, np. tylko dla storefrontu):**

   ```bash
   php bin/console oro:assets:build custom_storefront --watch
   ```

   > **Uwaga:** To polecenie działa w tle i automatycznie odbudowuje zasoby przy zmianach. Możesz je uruchomić w osobnym oknie terminala.

3. **Wyjdź z kontenera:**
   ```bash
   exit
   ```

### Krok 11.3: Instalacja zasobów OroCommerce

1. **Wejdź do kontenera PHP:**

   ```bash
   docker compose exec php bash
   ```

2. **Przejdź do katalogu aplikacji:**

   ```bash
   cd /var/www/orocommerce
   ```

3. **Zainstaluj zasoby:**

   ```bash
   php bin/console oro:assets:install --symlink --env=dev
   ```

   > **Uwaga:** Ta komenda publikuje assety (symlink) i uruchamia budowę assetów; wymaga Node.js i npm w kontenerze (z Dockerfile). W razie błędu „Js engine path is not found” zobacz sekcję „Rozwiązywanie problemów”.

4. **Wyczyść cache:**

   ```bash
   php bin/console cache:clear --env=dev
   ```

5. **Wyjdź z kontenera:**
   ```bash
   exit
   ```

---

## 12. Dostęp do aplikacji

### Krok 12.1: Otwarcie aplikacji w przeglądarce

1. **Otwórz przeglądarkę internetową** (Chrome, Firefox, Edge)

2. **Przejdź pod adres:**

   ```
   http://localhost:8080
   ```

3. **Powinieneś zobaczyć stronę logowania OroCommerce**

### Krok 12.2: Logowanie do panelu administracyjnego

1. **Użyj danych logowania podanych podczas instalacji:**

   - **Nazwa użytkownika:** `admin` (lub ta, którą podałeś)
   - **Hasło:** `admin123` (lub to, które podałeś)

2. **Kliknij "Zaloguj się"**

3. **Powinieneś zobaczyć panel administracyjny OroCommerce**

### Krok 12.3: Dostęp do storefrontu

Storefront OroCommerce jest dostępny pod tym samym adresem. W zależności od konfiguracji, możesz potrzebować:

1. **Utworzyć sklep w panelu administracyjnym**
2. **Skonfigurować stronę główną**
3. **Przejść do sekcji Storefront w menu**

---

## 13. Rozwiązywanie problemów

### Problem: Kontenery nie działają po restarcie komputera

**Przyczyna:**
Po restarcie komputera Windows, WSL i Docker są zatrzymywane, co powoduje zatrzymanie wszystkich kontenerów.

> **Uwaga:** Zamknięcie terminala Ubuntu NIE zatrzymuje kontenerów. Kontenery działają w tle i są niezależne od sesji terminala. Zatrzymują się dopiero po restarcie komputera lub po wykonaniu komendy `docker compose down`.

**Rozwiązanie - gdy aplikacja jest już zainstalowana:**

Jeśli OroCommerce i storefront były już wcześniej zainstalowane i działały, po restarcie komputera wykonaj tylko te kroki:

1. **Otwórz Ubuntu (WSL):**

   ```bash
   wsl -d Ubuntu
   ```

2. **Uruchom Docker:**

   ```bash
   sudo service docker start
   ```

   Lub jeśli masz skonfigurowane automatyczne uruchamianie Dockera w `.bashrc`, Docker uruchomi się automatycznie przy starcie WSL.

3. **Przejdź do katalogu projektu i uruchom kontenery:**

   ```bash
   cd ~/orocommerce-dev
   docker compose up -d
   ```

4. **Sprawdź status kontenerów:**

   ```bash
   docker compose ps
   ```

   Wszystkie kontenery powinny być w stanie "Up" (uruchomione).

5. **Sprawdź czy aplikacja działa:**

   - Otwórz przeglądarkę i przejdź do: `http://localhost:8080`
   - Powinieneś zobaczyć działające OroCommerce ze storefrontem

6. **Jeśli chcesz automatyczne odświeżanie storefrontu przy zmianach (tryb deweloperski):**

   Uruchom tryb watch, który będzie automatycznie przebudowywał zasoby frontendowe przy każdej zmianie w plikach:

   ```bash
   docker compose exec php bash
   cd /var/www/orocommerce
   php bin/console oro:assets:build custom_storefront --watch
   ```

   > **Uwaga:**
   >
   > - To polecenie działa w tle i automatycznie odbudowuje zasoby przy zmianach w plikach JavaScript/CSS
   > - Możesz zostawić to polecenie uruchomione w osobnym terminalu
   > - Aby zatrzymać watch, naciśnij `Ctrl + C` w terminalu, gdzie działa komenda z `--watch`
   > - Jeśli nie potrzebujesz automatycznego odświeżania, możesz pominąć ten krok - aplikacja będzie działać z ostatnio zbudowanymi zasobami

> **Dlaczego to wystarczy?**
>
> - Aplikacja OroCommerce jest już zainstalowana w bazie danych (dane są w volume Docker)
> - Storefront jest już zbudowany (pliki są w katalogu `orocommerce-application/public/build`)
> - Wystarczy tylko uruchomić kontenery Docker, które udostępnią aplikację
> - Tryb `watch` jest opcjonalny - potrzebny tylko jeśli chcesz automatyczne odświeżanie podczas rozwoju

**Jeśli aplikacja nie działa po uruchomieniu kontenerów:**

- Sprawdź logi: `docker compose logs`
- Sprawdź czy baza danych działa: `docker compose ps pgsql`
- Sprawdź czy nginx działa: `docker compose ps nginx`
- Jeśli potrzebujesz przebudować storefront, wykonaj kroki z sekcji "Budowa storefrontu"

**Automatyczne uruchamianie kontenerów po restarcie (opcjonalne):**

Jeśli chcesz, aby kontenery uruchamiały się automatycznie po starcie WSL, możesz dodać do `~/.bashrc`:

```bash
vim ~/.bashrc
```

Dodaj na końcu pliku:

```bash
# Automatyczne uruchamianie kontenerów OroCommerce po starcie WSL
if [ -f ~/orocommerce-dev/docker-compose.yml ]; then
    cd ~/orocommerce-dev
    docker compose up -d > /dev/null 2>&1
fi
```

Zapisz plik (`Esc`, potem `:wq`) i zastosuj zmiany:

```bash
source ~/.bashrc
```

> **Uwaga:** Ta opcja jest opcjonalna. Jeśli nie chcesz automatycznego uruchamiania, możesz zawsze uruchomić kontenery ręcznie komendą `docker compose up -d`.

**Automatyczne uruchamianie trybu watch dla storefrontu (opcjonalne, tylko dla trybu deweloperskiego):**

Jeśli chcesz, aby tryb `watch` uruchamiał się automatycznie po starcie WSL (dla automatycznego odświeżania storefrontu), możesz dodać do `~/.bashrc`:

```bash
vim ~/.bashrc
```

Dodaj na końcu pliku (po sekcji z kontenerami):

```bash
# Automatyczne uruchamianie trybu watch dla storefrontu (opcjonalne)
# Uwaga: To uruchomi watch w tle - zmiany będą widoczne w logach kontenera PHP
if [ -f ~/orocommerce-dev/docker-compose.yml ]; then
    # Poczekaj chwilę na uruchomienie kontenerów
    sleep 5
    # Uruchom watch w tle w kontenerze PHP
    docker compose -f ~/orocommerce-dev/docker-compose.yml exec -d php bash -c "cd /var/www/orocommerce && php bin/console oro:assets:build custom_storefront --watch"
fi
```

Zapisz plik (`Esc`, potem `:wq`) i zastosuj zmiany:

```bash
source ~/.bashrc
```

> **Uwaga:**
>
> - Ta opcja jest przydatna tylko podczas rozwoju aplikacji
> - Watch będzie działał w tle - możesz sprawdzić logi: `docker compose logs php | grep -i oro:assets:build`
> - Aby zatrzymać watch, wykonaj: `docker compose exec php pkill -f "oro:assets:build custom_storefront --watch"`
> - Jeśli nie potrzebujesz automatycznego odświeżania, możesz pominąć tę konfigurację

### Problem: Docker nie uruchamia się

**Rozwiązanie:**

1. Uruchom usługę Docker:
   ```bash
   sudo service docker start
   ```
2. Sprawdź status Dockera:
   ```bash
   sudo service docker status
   ```
3. Jeśli problem nadal występuje, sprawdź logi:
   ```bash
   sudo journalctl -u docker
   ```
4. Upewnij się, że dodałeś użytkownika do grupy docker i zrestartowałeś sesję WSL

### Problem: Kontenery nie startują

**Rozwiązanie:**

1. Sprawdź logi:
   ```bash
   docker compose logs
   ```
2. Sprawdź czy porty 8080, 6379, 3000 nie są zajęte przez inne aplikacje
3. Zatrzymaj wszystkie kontenery i uruchom ponownie:
   ```bash
   docker compose down
   docker compose up -d
   ```

### Problem: Błąd podczas instalacji Composer

**Rozwiązanie:**

1. Sprawdź połączenie z internetem
2. Sprawdź czy masz wystarczająco miejsca na dysku
3. Zwiększ limit pamięci PHP (już ustawiony na 1024M w konfiguracji)
4. Spróbuj ponownie:
   ```bash
   docker compose exec php composer install --no-interaction --prefer-dist
   ```

### Problem: Błąd podczas instalacji npm

**Rozwiązanie:**

1. Sprawdź wersję Node.js i npm:
   ```bash
   docker compose exec php node --version
   docker compose exec php npm --version
   ```
2. Jeśli wersje są nieprawidłowe, zainstaluj Node.js w kontenerze lub użyj lokalnej instalacji w WSL

### Problem: „Js engine path is not found” przy `oro:assets:install`

**Przyczyna:** Komenda `oro:assets:install` uruchamia także budowę assetów (`oro:assets:build`), która wymaga Node.js i npm w kontenerze. Błąd oznacza, że w kontenerze nie ma Node/npm albo cache aplikacji trzyma pustą ścieżkę.

**Rozwiązanie:**

1. Upewnij się, że w `docker/php/Dockerfile` jest blok instalacji Node.js 22 (sekcja „Struktura projektu”).
2. Przebuduj obraz i uruchom kontenery:
   ```bash
   docker compose build php
   docker compose up -d
   ```
3. W kontenerze wyczyść cache, a potem ponów instalację assetów:
   ```bash
      docker compose exec php php bin/console cache:clear --env=dev
      docker compose exec php php bin/console oro:assets:install --symlink --env=dev
   ```
4. Sprawdź, że w kontenerze jest Node: `docker compose exec php node -v` i `docker compose exec php npm -v`
   

### Problem: Błąd połączenia z bazą danych

**Rozwiązanie:**

1. Sprawdź czy kontener PostgreSQL działa:
   ```bash
   docker compose ps pgsql
   ```
2. Sprawdź logi PostgreSQL:
   ```bash
   docker compose logs pgsql
   ```
3. Sprawdź plik `.env-app.local` - upewnij się, że zawiera poprawne dane połączenia

### Problem: Strona nie ładuje się w przeglądarce

**Rozwiązanie:**

1. Sprawdź czy kontener nginx działa:
   ```bash
   docker compose ps nginx
   ```
2. Sprawdź logi nginx:
   ```bash
   docker compose logs nginx
   ```
3. Sprawdź logi PHP:
   ```bash
   docker compose logs php
   ```
4. Wyczyść cache:
   ```bash
   docker compose exec php php bin/console cache:clear --env=dev
   ```

### Problem: Błąd uprawnień

**Rozwiązanie:**

1. Ustaw uprawnienia w kontenerze:
   ```bash
   docker compose exec php chmod -R 777 /var/www/orocommerce/var/
   docker compose exec php chmod -R 777 /var/www/orocommerce/public/
   ```

### Problem: Historia konwersacji z AI w Cursorze zaginęła

**Przyczyna:**
Historia konwersacji Cursora jest przechowywana na Windows i jest powiązana ze ścieżką workspace. Jeśli otworzysz projekt przez inną ścieżkę lub nastąpi problem z plikami historii, historia może zaginąć.

**Rozwiązanie:**

1. **Sprawdź, czy otwierasz projekt przez właściwą ścieżkę:**
   - Zawsze używaj: `File` → `Open Folder` → `\\wsl.localhost\Ubuntu\home\TWOJA_NAZWA_UŻYTKOWNIKA\orocommerce-dev`
   - NIE używaj: `\\wsl$\...` lub `code .` z terminala

2. **Sprawdź lokalizację historii na Windows:**
   - Otwórz Eksplorator Windows
   - Przejdź do: `%APPDATA%\Cursor\User\workspaceStorage\`
   - Sprawdź, czy istnieją foldery z historią

3. **Odzyskiwanie historii:**
   - Zobacz szczegółową instrukcję w pliku: `ODZYSKIWANIE_HISTORII_CURSOR.md` (w katalogu projektu)
   - Plik zawiera szczegółowe kroki odzyskiwania historii i zapobiegania utracie w przyszłości

4. **Zapobieganie w przyszłości:**
   - Zawsze używaj tej samej ścieżki do otwierania projektu
   - Rozważ regularne kopie zapasowe folderu `workspaceStorage`
   - Sprawdź ustawienia synchronizacji Cursora (jeśli dostępne)

### Problem: Aplikacja działa wolno

**Rozwiązanie:**

1. Sprawdź wykorzystanie zasobów Docker Desktop (Settings → Resources)
2. Zwiększ przydział pamięci RAM dla Docker (zalecane minimum 4 GB)
3. Sprawdź czy nie masz zbyt wielu uruchomionych kontenerów

---

## 14. Przydatne komendy

> **Uwaga:** W tej instrukcji używamy `docker compose` (bez myślnika), które jest nowszą wersją wbudowaną w Docker CLI (Compose V2). Starsza wersja `docker-compose` (z myślnikiem) to osobne narzędzie, które również działa, ale zalecamy używać `docker compose`.

### Zarządzanie kontenerami

```bash
# Uruchomienie wszystkich kontenerów
docker compose up -d

# Zatrzymanie wszystkich kontenerów
docker compose down

# Restart kontenerów
docker compose restart

# Status kontenerów
docker compose ps

# Logi wszystkich kontenerów
docker compose logs -f

# Logi konkretnego kontenera
docker compose logs -f php
```

### Praca z aplikacją

```bash
# Wejście do kontenera PHP
docker compose exec php bash

# Wyczyść cache
docker compose exec php php bin/console cache:clear --env=dev

# Aktualizacja bazy danych
docker compose exec php php bin/console oro:platform:update --env=dev

# Reindeksacja wyszukiwania
docker compose exec php php bin/console oro:search:reindex --env=dev
```

### Praca z bazą danych

```bash
# Połączenie z bazą danych PostgreSQL
docker compose exec pgsql psql -U oro_db_user -d oro_db

# Backup bazy danych
docker compose exec pgsql pg_dump -U oro_db_user oro_db > backup.sql

# Przywrócenie bazy danych
docker compose exec -T pgsql psql -U oro_db_user -d oro_db < backup.sql
```

---

## 15. Gratulacje!

Jeśli dotarłeś do tego miejsca, oznacza to, że pomyślnie zainstalowałeś i uruchomiłeś OroCommerce ze storefrontem!

**Powodzenia w pracy z OroCommerce!**
