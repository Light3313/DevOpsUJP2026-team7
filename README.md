# DevOps MediaWiki Project

Навчальний DevOps-проєкт із розгортання MediaWiki за допомогою Docker та Docker Compose.

## Використані технології

- Docker — контейнеризація застосунку.
- Docker Compose — керування контейнерами.
- MediaWiki 1.42.1 — програмне забезпечення Wiki.
- MariaDB 10.11 — система керування базами даних.
- Bash — автоматизація резервного копіювання.
- Cron — планування автоматичного виконання завдань.
- Nginx — зворотний проксі-сервер (Reverse Proxy) та термінація SSL.
- Certbot (Let's Encrypt) — автоматичний випуск та оновлення TLS/SSL-сертифікатів.
- Prometheus — збір та зберігання метрик стану системи.
- Node Exporter — експорт апаратних та ОС-метрик хоста (CPU, RAM, диск, мережа).
- Grafana — візуалізація метрик, дашборди та алертинг.
- GitHub Actions — CI: лінтинг, збірка образу та smoke-тест.

## Архітектура проєкту

Проєкт складається з двох основних сервісів:

1. **wiki** — вебзастосунок MediaWiki (образ `php:8.2-apache`, код із `mywiki/`), порт `127.0.0.1:${WIKI_PORT}` (за замовчуванням `9000`).
2. **wiki-db** — база даних MariaDB із healthcheck; `wiki` стартує лише після того, як БД готова.

Для збереження даних використовуються Docker volumes:
- `wiki_db_data` — дані бази даних.
- `wiki_images` — завантажені зображення MediaWiki.

Додатково підключено стек моніторингу (`monitoring/docker-compose.yml`), інтегрований через директиву `include`:
3. **prometheus** — сервер збору метрик (порт `127.0.0.1:9090`).
4. **node-exporter** — агент збору метрик Linux-хоста (порт `9100` у внутрішній мережі).
5. **grafana** — вебпанель моніторингу (порт `127.0.0.1:3000`).

Для збереження даних моніторингу використовуються Docker volumes:
- `prometheus_data` — історія часових рядів метрик.
- `grafana_data` — налаштування користувачів, джерела даних та дашборди.

На продакшн-сервері перед контейнерами працює системний **Nginx** із сертифікатами **Let's Encrypt**, який забезпечує примусовий редирект `HTTP -> HTTPS` та маршрутизацію за доменами:
- `https://devopswiki.pp.ua` — застосунок MediaWiki.
- `https://grafana.devopswiki.pp.ua` — панель моніторингу Grafana.

## Структура проєкту

```text
DevOpsUJP2026-team7/
├── .github/workflows/ci.yml       # CI-пайплайн
├── backup/
│   └── backup-mywiki.sh           # бекап БД і LocalSettings.php
├── config/
│   └── .gitkeep                   # сюди кладеться LocalSettings.php (не в git)
├── monitoring/
│   ├── docker-compose.yml
│   ├── prometheus.yml
│   └── grafana/provisioning/datasources/prometheus.yml
├── mywiki/                        # вихідний код MediaWiki 1.42.1
├── nginx/
│   └── default.conf               # конфіг nginx на хості (довідково)
├── Dockerfile
├── docker-compose.yml
├── .dockerignore
├── .gitignore
├── .env.example
└── README.md
```

## Конфігурація

Секрети в репозиторії не зберігаються. Поруч із `docker-compose.yml` мають лежати:

| Файл | Звідки взяти |
|---|---|
| `.env` | копія `.env.example` з власними паролями |
| `config/LocalSettings.php` | з бекапу (`config_*.tar.gz`) або з інсталятора MediaWiki |

`$wgDBpassword` у `LocalSettings.php` має збігатися з `MYSQL_PASSWORD` у `.env`. Змінні `MYSQL_*` MariaDB застосовує лише при першому запуску на порожньому volume.

## Розгортання

```bash
git clone https://github.com/Light3313/DevOpsUJP2026-team7.git ~/app && cd ~/app
cp .env.example .env    # задати паролі
# покласти LocalSettings.php у config/
docker compose up -d --build
```

Відновлення БД з бекапу:

```bash
set -a; . ./.env; set +a
gunzip -c database_<дата>.sql.gz | docker compose exec -T -e MYSQL_PWD="$MYSQL_PASSWORD" wiki-db mariadb -u"$MYSQL_USER" "$MYSQL_DATABASE"
```

Для чистої установки використовується `maintenance/install.php` (приклад виклику в CI). Nginx і сертифікати налаштовуються на хості окремо, приклад конфігу в `nginx/default.conf`.

## Резервне копіювання

`backup/backup-mywiki.sh` робить дамп БД і копію `LocalSettings.php`, зберігає їх 14 днів. Запуск через cron:

```cron
0 2 * * * $HOME/app/backup/backup-mywiki.sh >> $HOME/backups/mywiki/cron.log 2>&1
```

## CI

`.github/workflows/ci.yml` запускається на push і pull request у `main`: перевірка compose-конфігу, Hadolint і ShellCheck, збірка образу та smoke-тест (установка MediaWiki на чисту БД і перевірка, що wiki відповідає).
