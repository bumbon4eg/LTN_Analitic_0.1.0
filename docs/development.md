# Разработка

Этот документ предназначен для разработчиков проекта. Пользовательскую установку см. в [installation.md](installation.md).

---

## Рабочее окружение

Рекомендуемый стек:

- VS Code;
- Lua Language Server / EmmyLua;
- Factorio Modding Tool Kit;
- Factorio 2.0;
- Logistic Train Network;
- Python 3.12 для Gateway;
- PostgreSQL.

Для AI-помощника в репозитории предусмотрены:

```text
.github/copilot-instructions.md
.github/agents/factorio-mod-developer.agent.md
```

Инструкции должны быть в Git, а не в пользовательском `.gitignore`, если они предназначены для всей команды.

---

## Проверка Factorio-мода

Lua runtime Factorio основан на модифицированном Lua 5.2. Не следует предполагать наличие произвольных библиотек стандартного Lua.

Проверяйте:

- `control.lua` и регистрацию lifecycle callbacks;
- LTN remote events;
- изменения persistent state в `storage`;
- JSONL serialization;
- миграцию старых полей storage;
- соответствие `schemas/*.schema.json` фактическому JSON.

Официальный источник API:

[Factorio Lua API](https://lua-api.factorio.com/)

---

## Проверка Gateway

```powershell
Set-Location .\gateway
py -3.12 -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
python main.py
```

Перед commit рекомендуется как минимум импортировать проект в IDE и убедиться, что отсутствуют очевидные import/type errors.

---

## Изменение JSONL-контракта

Изменение формата требует согласованной работы сразу в нескольких местах:

```text
Factorio Lua
    ↕
JSON Schema
    ↕
Gateway parser / Pydantic
    ↕
Database models
    ↕
Documentation
```

Порядок работы:

1. изменить producer в `code/`;
2. обновить нужные схемы в `schemas/`;
3. обновить Gateway-схемы/formatter;
4. проверить обратную совместимость;
5. обновить `docs/data-contract.md`;
6. проверить существующие JSONL-файлы;
7. только после этого менять `protocol_version`, если это действительно требуется.

---

## Правила для изменений

- не выдумывать Factorio API;
- не выдумывать LTN remote API;
- сохранять разделение runtime-мода и Gateway;
- использовать `storage` для persistent state Factorio;
- не менять несвязанный код без необходимости;
- сохранять существующие имена и публичные контракты;
- при изменении JSON сначала смотреть на схему и потребителей.

---

## Локальная установка мода без ZIP-сборщика

Для быстрой разработки удобно поддерживать отдельную runtime-папку:

```text
%APPDATA%\Factorio\mods\LTN_Analitic_0.1.1\
```

В неё синхронизируются:

```text
info.json
thumbnail.png
code\*.lua
```

Это именно **runtime-копия мода**, а не build artifact. Репозиторий остаётся в удобной для разработки структуре `code/ + gateway/ + schemas/ + docs/`.

---

## Что не должно попадать в Git

Никогда не публикуйте:

```text
.env
config.conf
.venv/
__pycache__/
*.pyc
runtime logs
local database dumps
```

Также не должны попадать в публичную историю реальные пароли, токены и connection strings.

---

## Перед релизом

Проверьте:

- версия в `info.json`;
- Mod Portal description/homepage;
- `thumbnail.png`;
- Factorio 2.0 + LTN;
- новый мир и существующий save;
- JSONL output;
- повторный импорт JSONL;
- PostgreSQL SSL и non-SSL сценарии, если оба поддерживаются окружением;
- отсутствие секретов в Git;
- документацию и installation flow.
