import json

from PySide6.QtCore import Property, QObject, QUrl, Signal, Slot
from PySide6.QtPositioning import QGeoCoordinate

from .models import FlightData
from .parser import parse_igc


class FlightBridge(QObject):
    flightLoaded = Signal()
    flightError = Signal(str)
    highlightChanged = Signal(int)

    def __init__(self, parent: QObject | None = None) -> None:
        super().__init__(parent)
        self._flight = FlightData()
        self._highlighted_index = -1

    # ------------------------------------------------------------------ slots

    @Slot(str)
    def loadFile(self, path: str) -> None:
        local = QUrl(path).toLocalFile() or path
        flight = parse_igc(local)
        if not flight.valid:
            self.flightError.emit("File does not contain enough valid GPS records.")
            return
        self._flight = flight
        self._highlighted_index = -1
        self.flightLoaded.emit()

    @Slot(int)
    def setHighlight(self, index: int) -> None:
        self._highlighted_index = index
        self.highlightChanged.emit(index)

    # --------------------------------------------------------------- properties

    @Property(bool, notify=flightLoaded)
    def hasData(self) -> bool:
        return self._flight.valid

    @Property(str, notify=flightLoaded)
    def statusText(self) -> str:
        if not self._flight.valid:
            return "Select an .igc file to start analysis."
        return f"✓ Loaded {self._flight.stats.point_count} GPS points"

    @Property(str, notify=flightLoaded)
    def statsJson(self) -> str:
        s = self._flight.stats
        return json.dumps(
            [
                {
                    "title": "Flight Distance",
                    "value": f"{s.flight_dist:.1f}",
                    "unit": "km",
                    "note": "including thermal circling",
                },
                {"title": "Max Altitude", "value": str(s.max_alt), "unit": "m", "note": ""},
                {"title": "Altitude Gain", "value": str(s.gain), "unit": "m", "note": ""},
                {"title": "Max Speed", "value": f"{s.max_speed:.1f}", "unit": "km/h", "note": "GPS · estimated"},
                {"title": "Max Climb", "value": f"{s.max_climb:.1f}", "unit": "m/s", "note": ""},
                {"title": "Avg Thermal", "value": f"{s.avg_thermal_climb:.1f}", "unit": "m/s", "note": ""},
            ]
        )

    @Property(str, notify=flightLoaded)
    def chartJson(self) -> str:
        if not self._flight.valid:
            return json.dumps({"distances": [], "altitudes": []})
        return json.dumps(
            {
                "distances": self._flight.distances,
                "altitudes": [p.alt for p in self._flight.points],
            }
        )

    @Property(int, notify=highlightChanged)
    def highlightedIndex(self) -> int:
        return self._highlighted_index

    # ---------------------------------------------------------- map coordinates

    @Property(list, notify=flightLoaded)
    def trackCoordinates(self) -> list:
        return [QGeoCoordinate(p.lat, p.lon) for p in self._flight.points]

    @Property(QGeoCoordinate, notify=flightLoaded)
    def startCoordinate(self) -> QGeoCoordinate:
        if not self._flight.valid:
            return QGeoCoordinate()
        p = self._flight.points[0]
        return QGeoCoordinate(p.lat, p.lon)

    @Property(QGeoCoordinate, notify=flightLoaded)
    def endCoordinate(self) -> QGeoCoordinate:
        if not self._flight.valid:
            return QGeoCoordinate()
        p = self._flight.points[-1]
        return QGeoCoordinate(p.lat, p.lon)

    @Property(QGeoCoordinate, notify=highlightChanged)
    def highlightCoordinate(self) -> QGeoCoordinate:
        if self._highlighted_index < 0 or not self._flight.valid:
            return QGeoCoordinate()
        p = self._flight.points[self._highlighted_index]
        return QGeoCoordinate(p.lat, p.lon)
