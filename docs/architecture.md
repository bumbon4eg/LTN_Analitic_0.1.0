# Архитектура проекта

LTN Analitic состоит из двух runtime-компонентов и одного общего контракта данных.

```text
                 ┌─────────────────────┐
                 │      Factorio       │
                 │     + LTN Analitic  │
                 └──────────┬──────────┘
                            │
                            │ JSONL
                            ▼
                 ┌─────────────────────┐
                 │      data.jsonl      │
                 └──────────┬──────────┘
                            │
                            │
                 ┌──────────▼──────────┐
                 │       Gateway       │
                 │ read / validate /   │
                 │ transform / import  │
                 └──────────┬──────────┘
                            │
                            ▼
                 ┌─────────────────────┐
                 │     PostgreSQL      │
                 └─────────────────────┘
```

## 1. Factorio runtime

Исходный Lua-код находится в `code/`.

| Файл | Назначение |
| --- | --- |
| `control.lua` | точка входа и регистрация callbacks |
| `actions.lua` | жизненный цикл LTN deliveries и events |
| `buffer.lua` | накопление данных перед JSONL-записью |
| `jsonl.lua` | формирование и запись пакетов |
| `storage.lua` | persistent state и `world_id` |
| `tools.lua` | чтение train/station/cargo данных |
| `debug.lua` | диагностические команды |
| `types.lua` | аннотации типов для редактора |
| `UUID_V4.lua` | генерация UUID v4 |

Мод не устанавливает DB connection и не содержит реквизитов внешней БД.

### Lifecycle

- `script.on_init` инициализирует `storage`, LTN callbacks и JSONL timer;
- `script.on_configuration_changed` поддерживает структуру state после обновления;
- `script.on_load` повторно регистрирует callbacks, не изменяя persistent state;
- каждые 360 игровых тиков JSONL-пакет дописывается в `script-output`.

### Persistent state

Ключевые поля:

```text
storage.world_id
storage.active_deliveries
storage.send_buffer.active_orders
storage.send_buffer.order_events
storage.send_buffer.trains
storage.send_buffer.stations
storage.next_order_id
storage.jsonl.sequence_number
```

---

## 2. JSONL contract

Каждая непустая строка `data.jsonl` — независимый пакет.

```text
protocol_version
world_id
sequence_number
tick
active_orders
order_events
trains
stations
```

Каноническая схема:

```text
schemas/packet.schema.json
```

Версия контракта сейчас `1.0` и независима от версии мода.

Подробнее: [data-contract.md](data-contract.md).

---

## 3. Gateway

Gateway в текущем снимке — Python-приложение с Tkinter GUI.

Слои:

```text
gateway/ui/
    Tkinter GUI
        ↓
gateway/main.py
    orchestration
        ↓
gateway/tools/
    data formatting
        ↓
gateway/core/schemas/
    validation
        ↓
gateway/core/services/
    business operations
        ↓
gateway/core/db/
    SQLAlchemy / asyncpg
        ↓
PostgreSQL
```

Gateway текущей версии сохраняет в БД orders и order_events. Train/station snapshots остаются частью JSONL-контракта, но отдельная запись этих snapshots в БД ещё не завершена.

---

## 4. Конфигурация

Factorio-мод не знает о конкретной базе.

Gateway получает свои параметры локально:

```text
%APPDATA%\LTN_Analitics_gateway\config.conf
```

Это принципиальная граница безопасности и распределения ответственности.

---

## 5. Повторная обработка

Gateway использует:

```text
world_id:order_id
```

для order key и UUID для event identity.

Повторная вставка известных сущностей пропускается на уровне БД.

При этом текущий importer перечитывает весь файл. В standalone-версии целевой механизм — хранить cursor/checkpoint и читать только новые данные.

---

## 6. Standalone target

Целевой пользовательский runtime:

```text
Factorio
   ↓
data.jsonl
   ↓
gateway.exe
   ↓
PostgreSQL / API
```

Standalone Gateway должен сохранить GUI первичной настройки и вынести все DB credentials за пределы Factorio-мода.

Дополнительно планируются:

- постоянное отслеживание файла;
- checkpoint по `world_id + sequence_number`;
- защищённое хранение секрета Windows;
- отдельная release-поставка `gateway.exe`.
