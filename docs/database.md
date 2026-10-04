# База данных и Factorio-мод

Factorio-мод не подключается к PostgreSQL, не создаёт таблицы и не хранит DB credentials. Его ответственность заканчивается на JSONL-файле в `script-output`.

Для импорта данных используйте отдельное приложение [LTN Analytics Gateway](https://github.com/Zorngeist-Qual/LTN-Analytics-Gateway). Реквизиты, требования к PostgreSQL, SSL/TLS и необходимые права описываются в README этого проекта.

Формат данных на границе двух проектов описан в [JSONL-контракте](data-contract.md). Внутри этого репозитория нет инструкций по настройке конкретной БД, поскольку это часть Gateway, а не мода.
