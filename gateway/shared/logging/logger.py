import logging
import inspect
import os

# ====== Logger Config ======

LOGGER_LVL = 10

# Кастомный уровень
VIOLET = 5
logging.addLevelName(VIOLET, "VIOLET")

# ANSI цвета
RESET = "\033[0m"
MAGENTA = "\033[95m"

COLORS = {
    "DEBUG":    ("\033[94m", "\033[96m"),
    "INFO":     ("\033[32m", "\033[92m"),
    "WARNING":  ("\033[93m", "\033[93m"),
    "ERROR":    ("\033[91m", "\033[91m"),
    "CRITICAL": ("\033[91m", "\033[91m"),
    "VIOLET":   ("\033[35m", "\033[35m"),
}

# === V1 ===
# class ColoredFormatter(logging.Formatter):
#     def format(self, record) -> str:
#         level_color, msg_color = COLORS.get(record.levelname, ("", ""))
#
#         levelname_colored = f"{level_color}{record.levelname}{RESET}"
#         msg_colored = f"{msg_color}{record.getMessage()}{RESET}"
#         name_colored = f"{MAGENTA}{record.name}{RESET}"
#
#         timestamp = self.formatTime(record, self.datefmt)
#         line = record.lineno
#
#         return f"{levelname_colored} - {timestamp} - [{name_colored}:{line}] - {msg_colored}"


# === V2 ===
class ColoredFormatter(logging.Formatter):
    def format(self, record) -> str:
        level_color, msg_color = COLORS.get(record.levelname, ("", ""))

        levelname_colored = f"{level_color}{record.levelname}{RESET}"
        msg_colored = f"{msg_color}{record.getMessage()}{RESET}"

        try:
            rel_path = os.path.relpath(record.pathname)
        except Exception:
            rel_path = record.filename

        name_colored = f"[{MAGENTA}File \"{RESET}{rel_path}{MAGENTA}\", line {record.lineno}{RESET}]"

        timestamp = self.formatTime(record, self.datefmt)

        return f"{levelname_colored} - {timestamp} - {name_colored} - {msg_colored}"


console_handler = logging.StreamHandler()
console_handler.setFormatter(
    ColoredFormatter("%(levelname)s - %(asctime)s - [%(name)s:%(lineno)d] - %(message)s")
)


root_logger = logging.getLogger()
root_logger.setLevel(LOGGER_LVL)
root_logger.addHandler(console_handler)

# Снижение шума aiogram
logging.getLogger("aiogram").setLevel(logging.WARNING)
logging.getLogger("aiogram.dispatcher").setLevel(logging.WARNING)
logging.getLogger("aiogram.event").setLevel(logging.WARNING)


def log_violet(self, msg, *args, **kwargs):
    if self.isEnabledFor(VIOLET):
        self._log(VIOLET, msg, args, **kwargs)


setattr(logging.Logger, "violet", log_violet)


class ProxyLogger:
    """Автоматически выбирает имя логгера по модулю, из которого был вызван."""

    _cache = {}

    def __getattr__(self, attr):
        frame = inspect.currentframe().f_back
        module = inspect.getmodule(frame)
        module_name = module.__name__ if module else "__main__"

        if module_name not in self._cache:
            self._cache[module_name] = logging.getLogger(module_name)

        logger = self._cache[module_name]
        return getattr(logger, attr)


logger = ProxyLogger()

__all__ = ["logger"]
