# DevOps MediaWiki Project

Навчальний DevOps-проєкт із розгортання MediaWiki за допомогою Docker та Docker Compose.

## Використані технології

- Docker — контейнеризація застосунку.
- Docker Compose — керування контейнерами.
- MediaWiki 1.42.7 — програмне забезпечення Wiki.
- MariaDB 10.11 — система керування базами даних.
- Bash — автоматизація резервного копіювання.
- Cron — планування автоматичного виконання завдань.

## Архітектура проєкту

Проєкт складається з двох основних сервісів:

1. **wiki** — вебзастосунок MediaWiki.
2. **wiki-db** — база даних MariaDB.

Для збереження даних використовуються Docker volumes:
- `wiki_db_data` — дані бази даних.
- `wiki_images` — завантажені зображення MediaWiki.

## Структура проєкту

```text
mywiki-devops/
├── backup/
│   └── backup-mywiki.sh
├── config/
│   └── .gitkeep
├── Dockerfile
├── docker-compose.yml
├── .dockerignore
├── .gitignore
├── .env.example
└── README.md
