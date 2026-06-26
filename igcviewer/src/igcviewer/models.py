from dataclasses import dataclass, field


@dataclass
class FlightPoint:
    lat: float
    lon: float
    alt: int
    time: str
    seconds: int


@dataclass
class FlightStats:
    flight_dist: float = 0.0
    max_alt: int = -9999
    min_alt: int = 9999
    gain: int = 0
    max_climb: float = 0.0
    max_sink: float = 0.0
    avg_thermal_climb: float = 0.0
    max_speed: float = 0.0
    point_count: int = 0


@dataclass
class FlightData:
    points: list[FlightPoint] = field(default_factory=list)
    distances: list[float] = field(default_factory=list)  # cumulative km per point
    stats: FlightStats = field(default_factory=FlightStats)
    valid: bool = False
