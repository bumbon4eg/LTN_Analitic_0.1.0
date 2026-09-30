import asyncio
import json
from dataclasses import dataclass
from pathlib import Path

from sqlalchemy import text
from sqlalchemy.engine import URL
from sqlalchemy.ext.asyncio import create_async_engine

from core.db.client import DBClient
from core.db.models.order import OrderORM
from core.db.models.order_event import OrderEventORM
from core.services.container import ServiceContainer
from shared.configuration.provider import ConfigProvider
from shared.configuration.ssl_settings import get_database_ssl_option
from shared.configuration.user_config import DatabaseConfig
from shared.logging.logger import logger
from tools.data_formatter import to_snapshot_obj


BATCH_SIZE = 500


@dataclass(frozen=True)
class ImportResult:
    snapshots_processed: int
    orders_sent: int
    events_sent: int


async def test_connection(database: DatabaseConfig) -> None:
    database_url = URL.create(
        drivername="postgresql+asyncpg",
        username=database.db_user,
        password=database.db_password,
        host=database.db_host,
        port=database.db_port,
        database=database.db_name,
    )
    engine = create_async_engine(
        database_url,
        pool_pre_ping=True,
        connect_args={
            "command_timeout": 10,
            "ssl": get_database_ssl_option(database.db_ssl),
            "server_settings": {"jit": "off"},
        },
    )
    try:
        async with engine.connect() as connection:
            await connection.execute(text("SELECT 1"))
    finally:
        await engine.dispose()


def read_jsonl(path: Path) -> list[dict]:
    if not path.is_file():
        raise FileNotFoundError(f"Файл данных не найден: {path}")

    packets: list[dict] = []
    with path.open("r", encoding="utf-8") as source_file:
        for line_number, line in enumerate(source_file, start=1):
            if not line.strip():
                continue
            try:
                packet = json.loads(line)
            except json.JSONDecodeError as error:
                raise ValueError(
                    f"Некорректный JSON в строке {line_number}: {error.msg}"
                ) from error
            if not isinstance(packet, dict):
                raise ValueError(f"Строка {line_number}: ожидался JSON-объект.")
            packets.append(packet)
    return packets


async def import_jsonl_data() -> ImportResult:
    ConfigProvider.reset()
    config = ConfigProvider.get()
    raw_data_list = read_jsonl(Path(config.source_jsonl_path))

    logger.info("[MAIN] - Starting data processing...")
    logger.info(f"[MAIN] - Found {len(raw_data_list)} snapshots to process.")

    all_orders: list[OrderORM] = []
    all_events: list[OrderEventORM] = []

    for raw_data in raw_data_list:
        snapshot = to_snapshot_obj(raw_data)
        all_orders.extend(
            OrderORM(
                order_id=f"{snapshot.world_id}:{order.id}",
                train_data=order.train_data.model_dump(),
                created_tick=order.created_tick,
                network_id=order.network_id,
                current_cargo=order.current_cargo,
                requested_cargo=order.requested_cargo,
            )
            for order in snapshot.active_orders
        )
        all_events.extend(
            OrderEventORM(
                event_id=event.id,
                order_id=f"{snapshot.world_id}:{event.order_id}",
                type=event.type,
                tick=event.tick,
                from_station=(
                    event.from_station.model_dump()
                    if hasattr(event.from_station, "model_dump")
                    else event.from_station
                ),
                to_station=(
                    event.to_station.model_dump()
                    if hasattr(event.to_station, "model_dump")
                    else event.to_station
                ),
                train_data=(
                    event.train_data.model_dump()
                    if hasattr(event.train_data, "model_dump")
                    else event.train_data
                ),
                is_cargo_empty=event.is_cargo_empty,
            )
            for event in snapshot.order_events
        )

    db = DBClient()
    service_container = ServiceContainer(db)
    orders_sent = 0
    events_sent = 0
    try:
        await db.init()
        for start in range(0, len(all_orders), BATCH_SIZE):
            orders_sent += await service_container.order_service.add_order(
                raw_data=all_orders[start : start + BATCH_SIZE]
            )
        for start in range(0, len(all_events), BATCH_SIZE):
            events_sent += await service_container.order_event_service.add_order_events(
                events=all_events[start : start + BATCH_SIZE]
            )
    finally:
        await db.close()

    return ImportResult(
        snapshots_processed=len(raw_data_list),
        orders_sent=orders_sent,
        events_sent=events_sent,
    )


def launch_ui() -> None:
    from ui.app import GatewayApp

    GatewayApp().run()


if __name__ == "__main__":
    launch_ui()