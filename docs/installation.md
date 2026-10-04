# Установка Factorio-мода

## Требования

- Factorio 2.0;
- Logistic Train Network 2.0.0 или новее;
- optional dependencies перечислены в `info.json`.

Для импорта JSONL в базу данных используется отдельное приложение [LTN Analytics Gateway](https://github.com/Zorngeist-Qual/LTN-Analytics-Gateway). Оно не требуется для запуска мода.

## Установка опубликованной версии

Установите мод через Mod Portal либо распакуйте предоставленный архив в каталог `mods` Factorio. Проверьте, что LTN и нужные дополнительные моды включены.

## Установка из исходников

Исходный Lua-код находится в `code/`, settings prototype — в `code/settings.lua`, локализации — в `locale/`. Factorio ожидает runtime-файлы и `info.json` в корне каталога мода.

Для локальной разработки создайте отдельный каталог, например:

```text
%APPDATA%\Factorio\mods\LTN_Analitic_0.1.1\
```

Скопируйте в него:

```text
info.json
thumbnail.png
code\*.lua
locale\
```

Результирующая структура должна включать `control.lua`, `settings.lua`, остальные Lua-файлы и `locale/en/locale.cfg` с `locale/ru/locale.cfg` в корне мода. Каталоги `gateway/`, `schemas/` и `docs/` в пакет Factorio не включаются.

В репозитории нет автоматического build-скрипта. Для Mod Portal создайте ZIP из содержимого runtime-каталога, не добавляя сам родительский каталог уровнем выше.

## Запись JSONL

Runtime-global настройка **«Записывать JSONL-снимки в script-output»** находится в **Настройки → Настройки мода → LTN Analitic**. Она включена по умолчанию.

При выключении ожидающий буфер очищается и новые пакеты не записываются. Данные, появившиеся во время паузы, не выгружаются после повторного включения. Проверить режим можно командой `/ltn_debug_jsonl`; принудительная запись доступна через `/ltn_write_jsonl`, если настройка включена.

По умолчанию файл располагается в:

```text
%APPDATA%\Factorio\script-output\LTN_Analitic\data.jsonl
```

Настраиваемый Factorio user-data directory может изменить этот путь.
