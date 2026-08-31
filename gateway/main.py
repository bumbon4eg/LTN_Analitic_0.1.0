import asyncio
import json
from typing import Sequence
from pathlib import Path

from core.db.client import DBClient
from core.db.models.order import OrderModel
from core.db.models.order_event import OrderEventModel
from core.schemas.game_snapshot import GameSnapshotSchema
from core.schemas.order import OrderSchema
from core.schemas.order_event import OrderEventSchema
from core.schemas.station import StationSchema
from core.schemas.train import TrainSchema
from shared.configs.provider import ConfigProvider
from tools.data_formatter import to_snapshot_obj
from core.db.repositories.order import OrderRepository
from core.db.repositories.order_event import OrderEventRepository
from core.services.order_service import OrderService
from core.services.order_event_service import OrderEventService


async def main():
    db = DBClient()

    order_repo = OrderRepository()
    order_service = OrderService(db, order_repo)

    order_event_repo = OrderEventRepository()
    order_event_service = OrderEventService(db, order_event_repo, order_repo)

    try:
        await db.init()

        cfg = ConfigProvider.get()
        raw_snapshot_path = (
            Path.home()
            / "AppData/Roaming/Factorio/script-output/LTN_Analitic/data.jsonl"
        )

        # raw_snapshot_path = (
        #         cfg.base_dir
        #         / ".dev/new_data.jsonl"
        #     )

        with open(raw_snapshot_path, "r", encoding="utf-8") as file:
           raw_data_list: list[dict] = [json.loads(line) for line in file if line.strip()]

        for raw_data in raw_data_list:
            snapshot: GameSnapshotSchema = to_snapshot_obj(raw_data)

            order_models = [
                OrderModel(
                    order_id=f"{snapshot.world_id}:{order.id}",
                    train_data=order.train_data.model_dump(),
                    created_tick=order.created_tick,
                    network_id=order.network_id,
                    requested_cargo=order.requested_cargo,
                )
                for order in snapshot.active_orders
            ]

            order_event_models = [
                OrderEventModel(
                    event_id=event.id,
                    order_id=f"{snapshot.world_id}:{event.order_id}",
                    type=event.type,
                    tick=event.tick,
                    from_station=event.from_station.model_dump() if isinstance(event.from_station, StationSchema) else dict({"id": int(event.from_station)}),
                    to_station=event.to_station.model_dump() if isinstance(event.to_station, StationSchema) else dict({"id": int(event.to_station)}),
                    train_data=event.train_data.model_dump() if isinstance(event.train_data, TrainSchema) else dict({"id": int(event.train_data)}),
                    is_cargo_empty=event.is_cargo_empty,
                )
                for event in snapshot.order_events
            ]

            await order_event_service.add_order_events_with_orders(
                orders=order_models,
                events=order_event_models,
            )

    finally:
        await db.close()

if __name__ == "__main__":
    asyncio.run(main())