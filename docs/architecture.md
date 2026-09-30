# Архитектура LTN Analytic

## Назначение

Проект состоит из двух взаимодействующих частей:

1. **Factorio-мод** хранится исходниками в `code/`, собирает данные Logistic
   Train Network и записывает их в JSON Lines.
2. **`gateway/`** — отдельное Python-приложение с Tkinter-интерфейсом. Оно
   читает JSONL, преобразует пакеты и загружает заказы и события в PostgreSQL.

Такое разделение позволяет менять способ хранения данных, не встраивая
подключение к базе данных в Factorio-мод.

Мод предназначен для продвинутых пользователей, исследующих игру и работу LTN.
Он не предоставляет полноценный интерфейс аналитики внутри Factorio. Для полной
работы требуется собственная база данных и отдельный `gateway`, который читает
JSONL-файл из `script-output/LTN_Analitic/` и загружает данные в БД.

Перед установкой прочитайте [README.md](../README.md), затем выберите нужный
тематический документ из списка в конце этой страницы. `info.json` содержит
метаданные и зависимости Factorio-мода.

## Структура репозитория

```text
.
├── code/                    # Исходный Lua-код Factorio-мода
│   ├── control.lua          # Точка входа мода
│   ├── actions.lua          # Обработка событий LTN
│   ├── buffer.lua           # Накопление данных
│   ├── jsonl.lua            # Формирование JSONL-пакетов
│   ├── storage.lua          # Persistent state Factorio
│   ├── debug.lua            # Команды диагностики
│   ├── tools.lua            # Чтение данных из Factorio API
│   ├── types.lua            # LuaLS-аннотации
│   └── UUID_V4.lua           # UUID игрового мира
├── info.json                # Метаданные и зависимости Factorio-мода
├── schemas/                 # JSON Schema внешнего контракта данных
├── gateway/                 # Отдельный загрузчик JSONL в БД
├── docs/                    # Документация проекта
└── .dev/                    # Локальные материалы разработки
```

Исходный Lua-код находится в `code/`. Скрипт `build.ps1` удалён; его больше нет
в репозитории. Для локальной упаковки нужно создать staging-каталог, скопировать
в него `info.json` и Lua-файлы из `code/` в корень, затем упаковать содержимое в
ZIP для Factorio.

## Поток данных

```text
LTN event
   -> code/actions.lua
   -> code/buffer.lua
   -> code/jsonl.lua (каждые 360 тиков)
    -> script-output/LTN_Analitic/data.jsonl
    -> gateway
    -> database
```

### Сбор данных

`code/control.lua` связывает Factorio lifecycle, LTN callbacks, диагностику и
JSONL timer. `code/actions.lua` обрабатывает delivery lifecycle; `code/tools.lua`
читает train/station snapshots; `code/buffer.lua` накапливает orders, events,
trains и stations в persistent `storage`. Подробности — в
[описании Factorio-мода](factorio-mod.md).

### Формат экспорта

Каждая строка `script-output/LTN_Analitic/data.jsonl` — самостоятельный пакет.
Состав полей, вложенные schemas, правила sequence/world и протокол описаны в
[контракте данных](data-contract.md).

## Версионирование протокола

`protocol_version` описывает JSONL-контракт и не равен версии мода в `info.json`.
Совместимое необязательное поле обычно не требует смены версии; изменение имени,
типа, обязательности или смысла поля требует новой major-версии. Подробные правила
согласованных изменений приведены в [контракте данных](data-contract.md).

## Lifecycle

Factorio lifecycle и периодическая отправка JSONL описаны на странице
[Factorio-мода](factorio-mod.md); пакет и event lifecycle — в
[контракте данных](data-contract.md).

## Границы компонентов

- Factorio-мод собирает snapshots и пишет JSONL; он не открывает соединение с БД.
- Gateway отвечает за GUI, чтение JSONL и импорт; он не запускается в Factorio.
- `schemas/` описывает общий формат данных и поддерживается вместе с обоими
   компонентами.
- Изменения мода и gateway проверяются каждый в собственном runtime.

## Документация по темам

- [Factorio-мод](factorio-mod.md): модули, lifecycle, storage и диагностика.
- [Контракт данных](data-contract.md): JSONL-пакет, схемы и версионирование.
- [Gateway](gateway.md): GUI, конфигурация, PostgreSQL, SSL и импорт.
- [Разработка и установка](development.md): локальный запуск, упаковка и проверки.

