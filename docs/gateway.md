# Companion Gateway

Этот репозиторий содержит только Factorio-мод и его JSONL-контракт. Приложение для чтения JSONL и импорта данных распространяется отдельно:

- [Документация Gateway в этом checkout](../gateway/README.md)
- [Репозиторий LTN Analytics Gateway](https://github.com/Zorngeist-Qual/LTN-Analytics-Gateway)
- [Скачать ZIP исходного кода](https://github.com/Zorngeist-Qual/LTN-Analytics-Gateway/archive/refs/heads/master.zip)
- [Страница Releases](https://github.com/Zorngeist-Qual/LTN-Analytics-Gateway/releases)

На 4 октября 2026 года готовые бинарные Releases не опубликованы. ZIP выше содержит исходный код Gateway, а не готовый исполняемый файл; актуальную информацию о доступных пакетах см. на странице Releases.

Мод не требует Gateway для игры. Когда запись включена в настройках мода, JSONL создаётся в `script-output/LTN_Analitic/data.jsonl` и может быть обработан внешним приложением. Формат описан в [контракте JSONL](data-contract.md).
