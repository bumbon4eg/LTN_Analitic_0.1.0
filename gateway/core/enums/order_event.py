from enum import Enum


class OrderEventType(Enum):
    CREATE = "create"
    ACCEPT = "accept"
    ERROR = "error"
    REASSIGNED = "reassigned"
    COMPLETE = "complete"