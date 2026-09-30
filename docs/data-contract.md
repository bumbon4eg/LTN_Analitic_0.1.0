# Контракт данных

Lua-мод и gateway обмениваются JSON Lines: каждая непустая строка `data.jsonl` является самостоятельным JSON-пакетом. Каноническая схема пакета — [`schemas/packet.schema.json`](../schemas/packet.schema.json); полный список схем — [`schemas/schema-catalog.schema.json`](../schemas/schema-catalog.schema.json).

## Пакет

Текущая версия контракта — строка `1.0`. Она независима от версии Factorio-мода в `info.json`.

| Поле | Назначение |
| --- | --- |
| `protocol_version` | Версия формата пакета |
| `world_id` | Постоянный UUID v4 мира |
| `sequence_number` | Возрастающий номер пакета в рамках мира, начиная с 1 |
| `tick` | Игровой tick snapshot |
| `active_orders` | Orders, накопленные с предыдущей записи |
| `order_events` | События жизненного цикла orders |
| `trains` | Train snapshots, объект индексируется train ID |
| `stations` | Station snapshots, объект индексируется station ID |

Упрощённая структура:

```json
{
  "protocol_version": "1.0",
  "world_id": "00000000-0000-4000-8000-000000000000",
  "sequence_number": 1,
  "tick": 360,
  "active_orders": [],
  "order_events": [],
  "trains": {},
  "stations": {}
}
```

Factorio-мод пишет пакет каждые 360 игровых тиков и дописывает строку в конец файла. Пустые пакеты допустимы и тоже увеличивают `sequence_number`.

## Orders и events

Order содержит `id`, `creation_time` (игровой tick), `network_id`, `train_id`, `current_content` и `required`. Cargo представлен массивом `{type, count}`; имя предмета/жидкости указывается без префиксов типа. При создании доставки текущий груз может быть пустым; после `on_delivery_pickup_complete` мод обновляет order в буфере фактическим грузом.

Order event содержит UUID v4 `id`, `order_id`, `action`, `from_id`, `to_id`, `is_empty`, `tick` и `train_id`. `action` принимает значения `create`, `accept`, `error`, `reassigned`, `complete`. Для `reassigned` поле `train_id` относится к новому поезду.

Gateway формирует ключ order в БД как `world_id:order_id`, так как `world_id` находится на уровне пакета. Событие сохраняет ссылку на этот ключ после форматирования.

## Train и station snapshots

Train snapshot содержит:

- `id`;
- `length` в формате `N-n-N`;
- `composition_summary` — словарь по имени прототипа вагона, с `count` и `content`;
- `fuel` — агрегированное топливо локомотивов;
- `name` и `planet`, допускающие `null`.

`composition_summary` содержит cargo-, fluid- и artillery-вагоны; локомотивы в сводку не входят. `content` — словарь `{имя предмета или жидкости: количество}`.

Station snapshot содержит `id`, `name`, `position` (`x`, `y`) и `planet`.

## Основные схемы

| Схема | Описывает |
| --- | --- |
| [`packet.schema.json`](../schemas/packet.schema.json) | JSONL-пакет |
| [`order.schema.json`](../schemas/order.schema.json) | Order |
| [`order-event.schema.json`](../schemas/order-event.schema.json) | Order event |
| [`train-data.schema.json`](../schemas/train-data.schema.json) | Train snapshot |
| [`station-data.schema.json`](../schemas/station-data.schema.json) | Station snapshot |
| [`wagon-summary.schema.json`](../schemas/wagon-summary.schema.json) | Сводка вагонов |
| [`count-data.schema.json`](../schemas/count-data.schema.json) | Cargo/fuel `{type, count}` |

В `schemas/` также присутствуют схемы внутренних структур storage/send buffer и входных событий LTN. Они документируют формы данных, но не все являются верхнеуровневыми JSONL-пакетами.

## Правила эволюции

- Необязательное обратно совместимое поле может добавляться без смены версии, если gateway корректно его игнорирует или обрабатывает.
- Переименование, изменение типа, обязательности или смысла поля требует новой major-версии.
- При изменении обновляются Lua-формирование, связанные JSON Schema, преобразования gateway и документация.
- Потребители используют `world_id` для разделения миров, `sequence_number` для обнаружения пропусков/повторов и UUID event для идемпотентности.

Подробнее см. [архитектуру](architecture.md) и [руководство gateway](gateway.md).
