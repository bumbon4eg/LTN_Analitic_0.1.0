# Устранение проблем Factorio-мода

## Мод не появляется в списке

Проверьте каталог мода: в его корне должны находиться `info.json`, `control.lua`, `settings.lua`, остальные runtime Lua-файлы и `locale/`. Lua-исходники из репозитория лежат в `code/`; не оставляйте их внутри `code/` в установленной папке мода.

Проверьте версию Factorio 2.0 и наличие Logistic Train Network. Дополнительные optional dependencies перечислены в `info.json`.

## JSONL не записывается

1. Убедитесь, что мир загружен без ошибок мода.
2. Откройте **Настройки → Настройки мода → LTN Analitic** и проверьте переключатель **«Записывать JSONL-снимки в script-output»**.
3. Выполните `/ltn_debug_jsonl`: команда покажет состояние записи и ожидающий буфер.
4. Если запись включена, вызовите `/ltn_write_jsonl` для немедленного пакета.

Если запись выключена, JSONL не пишется, а очередь очищается при переключении. Возобновление записи не выгружает события, накопленные во время паузы.

## Файл не найден

По умолчанию JSONL расположен здесь:

```text
%APPDATA%\Factorio\script-output\LTN_Analitic\data.jsonl
```

Каталог пользовательских данных Factorio может быть изменён настройками запуска. Проверьте фактический `script-output` в используемой установке.

## Некорректный train/world snapshot

Проверьте `factorio-current.log` на ошибки выполнения LTN callbacks. Команды `/ltn_debug_world_id`, `/ltn_debug_orders`, `/ltn_debug_buffer` и `/ltn_debug_send_data` помогают проверить persistent state и собранные данные.

Для существующего save обратите внимание на `storage.ensure()` и `script.on_configuration_changed`: они инициализируют отсутствующие поля storage при обновлении.

## Ошибки внешнего Gateway

Factorio-мод не подключается к PostgreSQL. Для JSONL parsing/import, SSL/TLS или database errors обратитесь к документации [отдельного LTN Analytics Gateway](https://github.com/Zorngeist-Qual/LTN-Analytics-Gateway).
