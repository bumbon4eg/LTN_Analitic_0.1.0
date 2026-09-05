import asyncio
import json
from pathlib import Path

from core.db.client import DBClient
from core.db.models.order import OrderModel
from core.db.models.order_event import OrderEventModel
from core.schemas.game_snapshot import GameSnapshotSchema
from core.schemas.station import StationSchema
from core.schemas.train import TrainSchema
from core.services.container import ServiceContainer
from shared.logging.logger import logger
from tools.data_formatter import to_snapshot_obj


BATCH_SIZE = 500
raw_snapshot_path = (
    Path.home()
    / "AppData/Roaming/Factorio/script-output/LTN_Analitic/data.jsonl"
)

async def main():
    db = DBClient()
    service_container = ServiceContainer(db)
    order_service = service_container.order_service
    order_event_service = service_container.order_event_service

    try:
        await db.init()

        with open(raw_snapshot_path, "r", encoding="utf-8") as file:
            raw_data_list: list[dict] = [json.loads(line) for line in file if line.strip()]

        logger.info("[MAIN] - Starting data processing...")
        logger.info(f"[MAIN] - Found {len(raw_data_list)} snapshots to process.")

        all_orders: list[OrderModel] = []
        all_events: list[OrderEventModel] = []

        for raw_data in raw_data_list:
            snapshot: GameSnapshotSchema = to_snapshot_obj(raw_data)

            all_orders.extend([
                OrderModel(
                    order_id=f"{snapshot.world_id}:{order.id}",
                    train_data=order.train_data.model_dump(),
                    created_tick=order.created_tick,
                    network_id=order.network_id,
                    current_cargo=order.current_cargo,
                    requested_cargo=order.requested_cargo,
                )
                for order in snapshot.active_orders
            ])

            all_events.extend([
                OrderEventModel(
                    event_id=event.id,
                    order_id=f"{snapshot.world_id}:{event.order_id}",
                    type=event.type,
                    tick=event.tick,
                    from_station=event.from_station.model_dump() if hasattr(event.from_station, "model_dump") else event.from_station,
                    to_station=event.to_station.model_dump() if hasattr(event.to_station, "model_dump") else event.to_station,
                    train_data=event.train_data.model_dump() if hasattr(event.train_data, "model_dump") else event.train_data,
                    is_cargo_empty=event.is_cargo_empty,
                )
                for event in snapshot.order_events
            ])

        for i in range(0, len(all_orders), BATCH_SIZE):
            chunk_orders = all_orders[i : i + BATCH_SIZE]
            await order_service.add_order(
                raw_data=chunk_orders
            )

        for i in range(0, len(all_events), BATCH_SIZE):
            chunk_events = all_events[i : i + BATCH_SIZE]
            await order_event_service.add_order_events(
                events=chunk_events,
            )

    finally:
        await db.close()

if __name__ == "__main__":
    asyncio.run(main())