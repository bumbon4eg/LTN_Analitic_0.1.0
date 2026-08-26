---@meta

-- Shared LuaLS annotations for the Factorio 2.0 LTN Analytic mod.
-- This file contains declarations only and must not be required at runtime.

---@alias TrainId uint
---@alias StationId uint
---@alias OrderId uint
---@alias EventId uint
---@alias Tick uint
---@alias NetworkId integer
---@alias SequenceId uint
---@alias WorldId string
---@alias UUID_V4 string
---@alias ActionName "create"|"accept"|"error"|"reassigned"|"complete"
---@alias DeliveryState "created"|"accepted"
---@alias LtnRemoteEventName "on_dispatcher_updated"|"on_delivery_pickup_complete"|"on_delivery_failed"|"on_delivery_reassigned"|"on_dispatcher_no_train_found"|"on_delivery_completed"

---@alias JsonlWriteResult boolean

---@alias ItemOrFluidName string
---@alias CargoAmount number
---@alias FuelAmount number

---@class CountData
---@field type string
---@field count number

---@class ContentData
---@field [string] number # Item or fluid name mapped to its amount.

---@class WagonSummary
---@field count number
---@field content ContentData

---@class PositionData
---@field x number
---@field y number

---@class CargoData
---@field [integer] CountData # `type` is the item or fluid name without a type prefix.

---@class TrainData
---@field id TrainId
---@field length string # Format: `N-n-N`.
---@field composition_summary table<string, WagonSummary> # Keyed by wagon prototype name.
---@field fuel CountData[] # Aggregated fuel names and counts.
---@field name string|nil # Leading locomotive name, when available.
---@field planet string|nil # Planet name or surface name.

---@class StationData
---@field id StationId
---@field name string
---@field position PositionData
---@field planet string|nil # Planet name or surface name.

---@class DeliveryData
---@field from_id StationId
---@field to_id StationId
---@field started Tick
---@field network_id NetworkId
---@field [string] any # Additional LTN fields not used by current logic.

---@class OrderData
---@field id OrderId
---@field world_id WorldId
---@field creation_time Tick # QUESTION: Confirm DB-side conversion from Factorio tick to datestamp.
---@field network_id NetworkId
---@field train_snapshot TrainData
---@field order_content CargoData # Aggregated item/fluid names and amounts.

---@class OrderEventData
---@field id EventId
---@field order_id OrderId
---@field action ActionName
---@field from_id StationId|nil
---@field to_id StationId|nil

---@class ActiveDelivery
---@field delivery DeliveryData
---@field order_id OrderId
---@field state DeliveryState

---@class ActiveDeliveries
---@field [TrainId] ActiveDelivery

---@class SendBuffer
---@field active_orders OrderData[]
---@field order_events OrderEventData[]
---@field trains table<TrainId, TrainData>
---@field stations table<StationId, StationData>

---@class SendData
---@field tick Tick
---@field active_orders OrderData[]
---@field order_events OrderEventData[]
---@field trains table<TrainId, TrainData>
---@field stations table<StationId, StationData>

---@class JsonlPacket
---@field protocol_version integer
---@field world_id WorldId
---@field sequence_number SequenceId
---@field tick Tick
---@field active_orders OrderData[]
---@field order_events OrderEventData[]
---@field trains table<TrainId, TrainData>
---@field stations table<StationId, StationData>

---@class JsonlStorage
---@field sequence_number SequenceId

---@class PersistentStorage
---@field world_id WorldId
---@field active_deliveries ActiveDeliveries
---@field send_buffer SendBuffer
---@field next_order_id OrderId
---@field next_event_id EventId
---@field jsonl JsonlStorage

---@class LtnDispatcherUpdatedEvent
---@field new_deliveries TrainId[]
---@field deliveries table<TrainId, DeliveryData>
---@field available_trains table<TrainId, LtnAvailableTrainData>|nil
---@field [string] any # Extra LTN dispatcher fields (ignored).

---@class LtnAvailableTrainData
---@field capacity number
---@field depot_priority number
---@field fluid_capacity number
---@field force LuaForce|string
---@field network_id NetworkId
---@field select_count number
---@field surface LuaSurface|string
---@field train LuaTrain|string

---@class LtnTrainDeliveryEvent
---@field train_id TrainId
---@field [string] any # LTN may include extra fields; only train_id is used.

---@class LtnDeliveryReassignedEvent
---@field old_train_id TrainId
---@field new_train_id TrainId
---@field [string] any # Extra reassignment data (unused).

---@class LtnDispatcherNoTrainFoundEvent
---@field [string] any # This event likely has no payload, but keep as any for safety.

---@class LtnEventRegistration
---@field name LtnRemoteEventName
---@field callback fun(event: table):nil

---@class LtnRemoteInterface
---@field on_dispatcher_updated fun(): defines event id
---@field on_delivery_pickup_complete fun(): defines event id
---@field on_delivery_failed fun(): defines event id
---@field on_delivery_reassigned fun(): defines event id
---@field on_dispatcher_no_train_found fun(): defines event id
---@field on_delivery_completed fun(): defines event id

---@class ActionsModule
---@field register_ltn_events fun()

---@class BufferModule
---@field buffer_active_order fun(order: OrderData)
---@field buffer_order_event fun(event: OrderEventData)
---@field buffer_train fun(train_data: TrainData|nil)
---@field buffer_station fun(station_data: StationData|nil)
---@field clear_send_buffer fun()
---@field collect_send_data fun(): SendData

---@class StorageModule
---@field ensure fun()
---@field ensure_world_id fun(force: boolean|nil): WorldId
---@field is_valid_world_id fun(world_id: string|nil): boolean

---@class UUIDModule
---@field new fun(): UUID_V4

---@class JsonlModule
---@field write fun(): JsonlWriteResult
---@field build_packet fun(): JsonlPacket
---@field register fun(): nil

---@class DebugModule
---@field show_world_id fun()
---@field regenerate_world_id fun()
---@field show_active_deliveries fun()
---@field clear_active_deliveries fun()
---@field show_send_buffer fun()
---@field show_send_data fun()
---@field clear_send_buffer fun()
---@field show_order fun(order_id: string|number|nil)
---@field write_jsonl_now fun()

---@class ToolsModule
---@field get_train_data fun(train_id: TrainId): TrainData|nil
---@field get_train_cargo fun(train_id: TrainId): CargoData|nil
---@field get_station_data fun(station_id: StationId): StationData|nil
---@field get_order_event_data fun(event_id: EventId, order_id: OrderId, action: ActionName, from_id: StationId|nil, to_id: StationId|nil): OrderEventData
---@field get_order_data fun(order_id: OrderId, world_id: WorldId, creation_time: Tick, network_id: NetworkId, train_snapshot: TrainData, order_content: CargoData): OrderData