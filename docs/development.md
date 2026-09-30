# Разработка и установка

## Требования

- Factorio 2.0.
- Logistic Train Network 2.0.0 или новее; дополнительные совместимые моды перечислены в `info.json`.
- Gateway: Python 3.10+ и PostgreSQL. Пакеты Python указаны в `gateway/requirements.txt`.

Используй Factorio 2.0 API и проверяй LTN remote API перед добавлением вызовов. Factorio runtime — модифицированный Lua 5.2.

## Установка мода

В репозитории Lua-исходники расположены в `code/`, но Factorio ожидает `info.json` и файлы мода в корне каталога мода. В текущем репозитории нет `build.ps1` и другого автоматического сборщика.

Для локальной упаковки в PowerShell из корня репозитория:

```powershell
$stage = Join-Path $env:TEMP ("LTN_Analitic_" + [guid]::NewGuid().ToString())
$dist = Join-Path $PWD "dist"
New-Item -ItemType Directory -Path $stage | Out-Null
New-Item -ItemType Directory -Path $dist -Force | Out-Null
Copy-Item .\info.json $stage
Copy-Item .\code\*.lua $stage
Compress-Archive -Path (Join-Path $stage "*") -DestinationPath (Join-Path $dist "LTN_Analitic_0.1.1.zip") -Force
Remove-Item $stage -Recurse -Force
```

ZIP содержит `info.json` и Lua-файлы прямо в корне архива. Установи ZIP в каталог `mods` Factorio. Не добавляй в архив `gateway/`, `schemas/` или `docs/`.

После загрузки мира JSONL создаётся в `script-output/LTN_Analitic/data.jsonl`.

## Запуск gateway для разработки

```powershell
Set-Location .\gateway
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
python main.py
```

На первом запуске настрой источник и PostgreSQL через GUI. Конфигурация расположена в `%APPDATA%\LTN_Analitics_gateway\config.conf`. Подробности приведены в [gateway.md](gateway.md).

## Изменение JSONL-контракта

`schemas/` — контракт между Factorio-модом и gateway. При изменении пакета:

1. обнови DTO и сериализацию в `code/`;
2. обнови соответствующие JSON Schema;
3. обнови преобразование и Pydantic-модели gateway;
4. проверь обратную совместимость и версионирование;
5. обнови [описание контракта](data-contract.md).

`protocol_version` относится к JSONL, а не к версии мода в `info.json`. Изменение имён/типов/семантики полей требует новой major-версии.

## Проверки

- Проверь Lua-синтаксис и вручную протестируй callbacks в Factorio с LTN.
- Проверяй JSONL-пакеты по схемам из `schemas/`.
- Для gateway запускай проверки из каталога `gateway/` с активным `.venv`.
- Проверь повторный импорт одного файла: дублирующие orders/events должны пропускаться.
- Проверяй подключение к PostgreSQL отдельно с SSL выключенным и включённым, если целевой сервер поддерживает оба режима.

См. [обзор архитектуры](architecture.md) и [архитектуру Lua-мода](factorio-mod.md).
