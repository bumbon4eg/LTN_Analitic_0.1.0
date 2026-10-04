# Архитектура LTN Analitic

Этот репозиторий распространяет самостоятельный мод Factorio 2.0. Мод наблюдает за событиями Logistic Train Network (LTN), собирает данные и дописывает JSONL-пакеты в `script-output`. Он не подключается к базе данных и не содержит пользовательского Gateway.

```text
Factorio 2.0 + LTN Analitic
           │
           ▼
script-output/LTN_Analitic/data.jsonl
           │
           └──► внешний потребитель (например, LTN Analytics Gateway)
```

[LTN Analytics Gateway](https://github.com/Zorngeist-Qual/LTN-Analytics-Gateway) — отдельное приложение для импорта JSONL. Оно не входит в архив Factorio-мода.

## Сбор и запись

`control.lua` регистрирует Factorio lifecycle callbacks, LTN callbacks, JSONL timer и debug-команды. `actions.lua` управляет жизненным циклом deliveries и формирует orders/events. `tools.lua` читает данные train/station/cargo. `buffer.lua` накапливает данные в persistent `storage`; `jsonl.lua` сериализует пакет и записывает его в файл.

Запись запускается каждые 360 игровых тиков (6 секунд). Runtime-global setting **«Записывать JSONL-снимки в script-output»** включена по умолчанию. При её выключении буфер очищается, запись прекращается и `sequence_number` не увеличивается; повторное включение начинает сбор для последующих пакетов без выгрузки событий периода паузы.

## Исходники мода

| Путь | Назначение |
| --- | --- |
| `code/control.lua` | Lifecycle, event/timer registration, debug commands |
| `code/actions.lua` | LTN delivery lifecycle, orders и events |
| `code/tools.lua` | Снимки train, station и cargo |
| `code/buffer.lua` | Буферизация четырёх типов данных |
| `code/storage.lua` | Persistent state и UUID мира |
| `code/jsonl.lua` | JSONL packet creation/writing и runtime-setting gate |
| `code/debug.lua` | Диагностические команды, включая состояние записи |
| `code/UUID_V4.lua` | Генератор UUID v4 |
| `code/types.lua` | LuaLS-аннотации |
| `code/settings.lua` | Runtime-global bool setting |
| `locale/` | Названия setting на английском и русском |

## Данные

Каждый JSONL-пакет содержит `protocol_version`, `world_id`, `sequence_number`, `tick`, `active_orders`, `order_events`, `trains` и `stations`. Версия протокола сейчас `1.0`, отдельно от версии мода в `info.json`.

Пакет и вложенные структуры описаны в [контракте JSONL](data-contract.md). Внутренние правила и lifecycle описаны в [архитектуре Factorio-мода](factorio-mod.md).
