# Установка Factorio-мода

## Требования

- Factorio 2.0;
- Logistic Train Network 2.0.0 или новее;
- optional dependencies перечислены в `info.json`.

Для импорта JSONL в базу данных используется отдельное приложение [LTN Analytics Gateway](https://github.com/bumbon4eg/LTN-Analytics-Gateway/tree/master). Оно не требуется для запуска мода.

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

## Сборка ZIP для релиза

Из корня репозитория запустите в Windows PowerShell:

```powershell
.\build-release.ps1
```

Скрипт проверяет обязательные поля `info.json`, формат версии и имя мода,
наличие runtime Lua-файлов, локализаций, миниатюры и лицензии. Он собирает
`_release\<name>_<version>.zip`; имя и версия берутся из `info.json`. Исходные
`code/`, `docs/`, `schemas/` и настройки разработки в архив не попадают.

По официальной структуре Factorio имя ZIP должно иметь формат
`<имя-мода>_<версия>.zip`, а внутри должна быть папка мода с `info.json`,
runtime Lua-файлами в корне, `locale/`, `thumbnail.png` и `LICENSE`. Скрипт
создаёт эту внутреннюю папку с именем `<имя-мода>_<версия>`.

См. официальную [спецификацию структуры мода и `info.json`](https://lua-api.factorio.com/latest/auxiliary/mod-structure.html)
и [API публикации релизов Mod Portal](https://wiki.factorio.com/Mod_upload_API).

## Запись JSONL

Runtime-global настройка **«Записывать JSONL-снимки в script-output»** находится в **Настройки → Настройки мода → LTN Analitic**. Она включена по умолчанию.

При выключении ожидающий буфер очищается и новые пакеты не записываются. Данные, появившиеся во время паузы, не выгружаются после повторного включения. Проверить режим можно командой `/ltn_debug_jsonl`; принудительная запись доступна через `/ltn_write_jsonl`, если настройка включена.

По умолчанию файл располагается в:

```text
%APPDATA%\Factorio\script-output\LTN_Analitic\data.jsonl
```

Настраиваемый Factorio user-data directory может изменить этот путь.
