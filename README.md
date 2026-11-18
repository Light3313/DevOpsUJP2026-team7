# DevOps MediaWiki Project

Навчальний DevOps-проєкт із розгортання MediaWiki за допомогою Docker та Docker Compose.

## Використані технології

- Docker — контейнеризація застосунку.
- Docker Compose — керування контейнерами.
- MediaWiki 1.42.7 — програмне забезпечення Wiki.
- MariaDB 10.11 — система керування базами даних.
- Bash — автоматизація резервного копіювання.
- Cron — планування автоматичного виконання завдань.
- Nginx — зворотний проксі-сервер (Reverse Proxy) та термінація SSL.
- Certbot (Let's Encrypt) — автоматичний випуск та оновлення TLS/SSL-сертифікатів.
- Prometheus — збір та зберігання метрик стану системи.
- Node Exporter — експорт апаратних та ОС-метрик хоста (CPU, RAM, диск, мережа).
- Grafana — візуалізація метрик, дашборди та алертинг.

## Архітектура проєкту

Проєкт складається з двох основних сервісів:

1. **wiki** — вебзастосунок MediaWiki.
2. **wiki-db** — база даних MariaDB.

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
mywiki-devops/
├── backup/
│   └── backup-mywiki.sh
├── config/
│   └── .gitkeep
├── monitoring/
│   ├── docker-compose.yml
│   └── prometheus.yml
├── nginx/
│   └── default.conf
├── Dockerfile
├── docker-compose.yml
├── .dockerignore
├── .gitignore
├── .env.example
└── README.md
```