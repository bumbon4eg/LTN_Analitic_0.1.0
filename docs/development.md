# Разработка

Этот документ предназначен для разработчиков проекта. Пользовательскую установку см. в [installation.md](installation.md).

---

## Рабочее окружение

Рекомендуемый стек:

- VS Code;
- Lua Language Server / EmmyLua;
- Factorio Modding Tool Kit;
- Factorio 2.0;
- Logistic Train Network 2.0.0 или новее.

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

## Внешний Gateway

Gateway — отдельный companion-проект и не входит в runtime мода. Его исходники,
инструкция установки и проверки публикуются отдельно:

[LTN Analytics Gateway](https://github.com/bumbon4eg/LTN-Analytics-Gateway/tree/master)

---

## Изменение JSONL-контракта

Изменение формата требует согласованной работы сразу в нескольких местах:

```text
Factorio Lua
    ↕
JSON Schema
    ↕
внешний Gateway
    ↕
совместимая документация
```

Порядок работы:

1. изменить producer в `code/`;
2. обновить нужные схемы в `schemas/`;
3. согласовать обновление внешнего Gateway;
4. проверить обратную совместимость;
5. обновить `docs/data-contract.md`;
6. проверить существующие JSONL-файлы на совместимость;
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
locale\
```

Это именно **runtime-копия мода**, а не build artifact. Исходный проект мода
содержит `code/`, `locale/`, `schemas/` и документацию; Gateway поставляется
отдельно.

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

## Сборка и проверка релиза

Соберите проверенный runtime-архив командой из корня репозитория:

```powershell
.\build-release.ps1
```

ZIP появится в `_release/` и будет назван по `name` и `version` из `info.json`.
Скрипт проверит обязательные поля манифеста и runtime-файлы. Архив содержит внутреннюю
папку мода с `info.json` в корне, как описано в [официальной спецификации структуры мода](https://lua-api.factorio.com/latest/auxiliary/mod-structure.html).
Не загружайте на Mod Portal исходный архив GitHub или ZIP каталога проекта.

## Перед релизом

Проверьте:

- версия в `info.json`;
- Mod Portal description/homepage;
- `thumbnail.png`;
- Factorio 2.0 + LTN;
- новый мир и существующий save;
- JSONL output;
- runtime-переключатель записи в настройках мода;
- локализации setting prototype в каталоге `locale/`;
- отсутствие секретов в Git;
- документацию и installation flow.
