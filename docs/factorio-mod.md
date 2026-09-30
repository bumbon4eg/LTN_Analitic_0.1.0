# Factorio-мод

Мод рассчитан на Factorio 2.0 и Logistic Train Network. Lua runtime в Factorio основан на модифицированном Lua 5.2; не следует предполагать доступность произвольных стандартных библиотек.

## Модули

| Файл | Назначение |
| --- | --- |
| `code/control.lua` | Регистрация lifecycle callbacks, LTN событий, JSONL timer и команд отладки |
| `code/actions.lua` | Жизненный цикл доставок и создание orders/events |
| `code/tools.lua` | Чтение данных train, cargo и station через Factorio API |
| `code/buffer.lua` | Накопление и сбор данных на отправку |
| `code/storage.lua` | Инициализация persistent state и UUID мира |
| `code/jsonl.lua` | Формирование и запись JSONL-пакетов |
| `code/debug.lua` | Просмотр и очистка состояния, ручная запись пакета |
| `code/UUID_V4.lua` | Генерация UUID v4 |
| `code/types.lua` | LuaLS-типы; файл аннотаций, не используется в runtime |

Основные зависимости:

```text
control -> actions, debug, jsonl, storage
actions -> tools, buffer, storage, UUID_V4
buffer -> storage
debug -> buffer, storage, jsonl
jsonl -> buffer, storage
```

## Factorio lifecycle

- `script.on_init`: `storage.ensure()`, регистрация LTN events и периодической JSONL-записи.
- `script.on_configuration_changed`: обеспечение структуры storage и повторная регистрация событий.
- `script.on_load`: только регистрация callbacks и timer; изменение persistent state при загрузке не выполняется.

LTN подключается через remote interface `logistic-train-network`. Перед `remote.call()` проверяются наличие интерфейса и метода. Поддерживаются `on_dispatcher_updated`, `on_delivery_pickup_complete`, `on_delivery_failed`, `on_delivery_reassigned`, `on_dispatcher_no_train_found` и `on_delivery_completed`.

`on_dispatcher_updated` обрабатывает только `new_deliveries`: повторный обход всех доставок создал бы дубли заказов.

## Состояние доставки

Активная доставка хранится в `storage.active_deliveries[train_id]` со ссылками на исходные delivery data, `order_id` и состоянием:

```text
new delivery -> created -> accepted -> removed (completed)
                     \-> removed (failed)
```

Событие `on_delivery_pickup_complete` создаёт `accept`, получает фактический cargo, обновляет `current_content` заказа в буфере и обновляет train snapshot после загрузки. `on_delivery_reassigned` переносит запись со старого `train_id` на новый без смены состояния. Действия имеют значения `create`, `accept`, `error`, `reassigned`, `complete`; `error` является частью текущего JSONL-контракта.

## Persistent state

Основные поля Factorio `storage`:

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

`world_id` — UUID v4, который создаётся при старте мира и восстанавливается, если значение отсутствует или невалидно. Ручная регенерация UUID создаёт новую логическую серию пакетов.

`storage.ensure()` дополняет отсутствующие поля, не перезаписывая существующее состояние. Старые поля `send_buffer.orders` и `send_buffer.actions` удаляются при миграции к `active_orders` и `order_events`.

В буфере orders и events лежат в массивах. Trains и stations индексированы по ID; новый train snapshot заменяет предыдущий snapshot этого поезда. Запись буфера очищается после JSONL-записи.

## Снимки поездов и станций

`tools.get_train_data()` формирует `length` в формате `передние локомотивы-вагоны-задние локомотивы`, например `1-3-1`, имя ведущего локомотива, планету/поверхность, топливо и `composition_summary`.

`composition_summary` группирует cargo-, fluid- и artillery-вагоны по имени прототипа. Каждая запись содержит `count` и `content` — агрегированные имена предметов или жидкостей и количества. Локомотивы не включаются; их топливо агрегируется отдельно в `fuel`. `tools.get_train_cargo()` возвращает список `{type, count}` без префиксов `item,`/`fluid,`.

Station snapshot содержит unit ID, имя, позицию и планету либо имя поверхности.

## Запись и отладка

`code/jsonl.lua` добавляет пакет в `script-output/LTN_Analitic/data.jsonl` каждые 360 игровых тиков (6 секунд). Пакет записывается даже при пустом буфере; `sequence_number` увеличивается при каждой записи.

| Команда | Назначение |
| --- | --- |
| `/ltn_debug_world_id` | Показать UUID мира |
| `/ltn_regenerate_world_id` | Принудительно создать UUID |
| `/ltn_debug_orders` | Показать активные доставки |
| `/ltn_clear_active` | Очистить активные доставки |
| `/ltn_debug_buffer` | Показать send buffer |
| `/ltn_debug_send_data` | Показать собранный snapshot |
| `/ltn_clear_buffer` | Очистить send buffer |
| `/ltn_debug_order <id>` | Показать order и связанные events из буфера |
| `/ltn_write_jsonl` | Немедленно записать пакет |

См. также [обзор архитектуры](architecture.md) и [контракт данных](data-contract.md).
