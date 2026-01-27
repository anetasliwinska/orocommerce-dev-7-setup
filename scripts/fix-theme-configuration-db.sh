#!/usr/bin/env bash
#
# Skrypt serwisowy dla custom storefront theme w OroCommerce.
# ------------------------------------------------------------
# DO CZEGO SŁUŻY:
# - Czyta z bazy tabelę konfiguracji (`oro_config` i `oro_config_value`), żebyś widziała:
#   - jakie są scope'y konfiguracji (kolumny: entity, record_id, config_id),
#   - jakie wartości mają wpisy `oro_theme.theme_configuration`.
# - Ustawia `oro_theme.theme_configuration = 2` dla `config_id = 1`,
#   czyli dla globalnego scope'u (zwykle `entity = 'app', record_id = 0`),
#   gdzie 2 to ID Twojej Theme Configuration „Custom Storefront (dev)”.
# - Czyści cache Symfony (`cache:clear`), żeby nowa wartość zaczęła działać w aplikacji.
#
# KIEDY UŻYWAĆ:
# - Gdy po imporcie danych / migracjach / zmianach w konfiguracji
#   storefront znowu zacznie ładować theme `default` zamiast `custom_storefront`,
#   mimo że w panelu wybrałaś Custom Storefront.
# - Gdy chcesz szybko zdiagnozować, jakie scope'y (entity/record_id) masz w `oro_config`
#   i jaką wartość ma tam `oro_theme.theme_configuration`.
#
# JAK URUCHOMIĆ:
# - Z katalogu `orocommerce-dev` (tam, gdzie jest `docker-compose.yml`):
#     ./scripts/fix-theme-configuration-db.sh
#   Skrypt sam:
#   - połączy się z bazą przez `docker compose exec pgsql ...`,
#   - pokaże diagnostykę configów,
#   - ustawi wartość 2 dla `config_id = 1` (INSERT lub UPDATE),
#   - wywoła `cache:clear` w kontenerze PHP.
#
# UWAGI:
# - Jeśli w przyszłości okaże się, że Twój storefront używa innego `config_id`
#   (np. dla website lub customer), możesz dostosować sekcję UPDATE/INSERT
#   zmieniając `config_id = 1` na odpowiedni identyfikator.
# - Skrypt niczego nie usuwa – tylko ustawia/uzupełnia konkretny wpis konfiguracyjny.
#
# Uruchom z katalogu orocommerce-dev (tam gdzie jest docker-compose.yml):
#   ./scripts/fix-theme-configuration-db.sh
set -e
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

echo "=== 1. Diagnostyka: oro_config (scope -> config_id) ==="
docker compose exec -T pgsql psql -U oro_db_user -d oro_db -c "
  SELECT c.id AS config_id, c.entity, c.record_id
  FROM oro_config c
  ORDER BY c.id;
"

echo ""
echo "=== 2. Diagnostyka: theme_configuration w oro_config_value ==="
docker compose exec -T pgsql psql -U oro_db_user -d oro_db -c "
  SELECT cv.config_id, cv.section, cv.name, cv.text_value
  FROM oro_config_value cv
  WHERE cv.section = 'oro_theme' AND cv.name = 'theme_configuration'
  ORDER BY cv.config_id;
"

echo ""
echo "=== 3. Ustawienie theme_configuration = 2 (Custom Storefront) dla config_id=1 ==="
docker compose exec -T pgsql psql -U oro_db_user -d oro_db -c "
  UPDATE oro_config_value
  SET text_value = '2'
  WHERE section = 'oro_theme' AND name = 'theme_configuration' AND config_id = 1;
"

# Jeśli nie było wiersza dla config_id=1, wstaw
ROWS=$(docker compose exec -T pgsql psql -U oro_db_user -d oro_db -t -A -c "
  SELECT COUNT(*) FROM oro_config_value WHERE section = 'oro_theme' AND name = 'theme_configuration' AND config_id = 1;
" 2>/dev/null | tr -d ' ' || echo "0")
if [ "$ROWS" = "0" ]; then
  echo "Wstawiam nowy wiersz dla config_id=1..."
  docker compose exec -T pgsql psql -U oro_db_user -d oro_db -c "
    INSERT INTO oro_config_value (config_id, section, name, text_value)
    VALUES (1, 'oro_theme', 'theme_configuration', '2');
  "
fi

echo ""
echo "=== 4. Cache clear ==="
docker compose exec php php bin/console cache:clear --env=dev

echo ""
echo "Gotowe. Odśwież storefront (Ctrl+F5 / incognito) i sprawdź czy CSS to /build/custom_storefront/..."
