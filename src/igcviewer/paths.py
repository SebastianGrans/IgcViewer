from dataclasses import dataclass
from pathlib import Path


@dataclass
class Paths:
    root: Path = Path(__file__).resolve().parent
