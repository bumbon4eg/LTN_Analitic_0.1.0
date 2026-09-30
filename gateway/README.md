# LTN Analitic Gateway

Внешний компонент LTN Analitic, который читает JSONL-файлы, созданные Factorio-модом, и импортирует orders/events в PostgreSQL.

Полная пользовательская документация находится в корне проекта:

- [Установка](../docs/installation.md)
- [Настройка Gateway](../docs/gateway.md)
- [Подготовка PostgreSQL](../docs/database.md)
- [Устранение проблем](../docs/troubleshooting.md)
- [Архитектура](../docs/architecture.md)

## Быстрый запуск для разработчика

```powershell
py -3.12 -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
python main.py
```

При первом запуске откроется мастер настройки JSONL и PostgreSQL.

## Важно

Этот каталог является внешним приложением и **не входит в Factorio-мод**.

Не храните в `gateway/` реальные `.env` или иные секреты. Пользовательская конфигурация Gateway находится вне репозитория, в `%APPDATA%\LTN_Analitics_gateway\config.conf`.

Текущая реализация — Python/Tkinter. Целевой release-вариант проекта предусматривает самостоятельный `gateway.exe` без установки Python пользователем.
