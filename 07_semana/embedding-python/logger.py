import logging
import os
import sys
from typing import Optional


class AppLogger:
    _instance: Optional["AppLogger"] = None
    _logger: Optional[logging.Logger] = None

    def __new__(cls) -> "AppLogger":
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance._setup()
        return cls._instance

    def _setup(self) -> None:
        self._logger = logging.getLogger("embeddings_loader")
        if not self._logger.handlers:
            handler = logging.StreamHandler(sys.stdout)
            formatter = logging.Formatter(
                "%(asctime)s %(levelname)s %(name)s %(message)s"
            )
            handler.setFormatter(formatter)
            self._logger.addHandler(handler)
            level = os.environ.get("LOG_LEVEL", "INFO").upper()
            self._logger.setLevel(getattr(logging, level, logging.INFO))

    @property
    def logger(self) -> logging.Logger:
        return self._logger


def get_logger() -> logging.Logger:
    return AppLogger().logger