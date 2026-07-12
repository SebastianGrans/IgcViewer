from __future__ import annotations
import logging

import json
from typing import ClassVar, TypeVar

from PySide6.QtCore import Property, QObject, QUrl, Signal, Slot
from PySide6.QtPositioning import QGeoCoordinate, QGeoRectangle
from PySide6.QtQml import QmlElement as _QmlElement
from PySide6.QtQml import QmlSingleton as _QmlSingleton

from .models import FlightData
from .parser import parse_igc

log = logging.getLogger(__name__)


# The type stubs for QmlElement and QmlSingleton are
# def QmlElement(arg__1: object, /) -> object: ...
# They should have been something like this:
_T = TypeVar("_T")


def QmlElement(cls: type[_T]) -> type[_T]:
    return _QmlElement(cls)  # ty: ignore[invalid-return-type]


def QmlSingleton(cls: type[_T]) -> type[_T]:
    return _QmlSingleton(cls)  # ty: ignore[invalid-return-type]


QML_IMPORT_NAME = "igcviewer"
QML_IMPORT_MAJOR_VERSION = 1


@QmlElement
@QmlSingleton
class FlightBridge(QObject):
    flightLoaded = Signal()
    flightError = Signal(str)
    highlightChanged = Signal(int)

    _instance: ClassVar[FlightBridge | None] = None
    _maptiler_key: ClassVar[str] = ""

    def __init__(self, parent: QObject | None = None) -> None:
        super().__init__(parent)
        FlightBridge._instance = self
        self._flight = FlightData()
        self._highlighted_index = -1

    @classmethod
    def instance(cls) -> FlightBridge:
        if cls._instance is None:
            raise RuntimeError("FlightBridge singleton not yet created")
        return cls._instance

    @Property(str, constant=True)
    def maptilerKey(self) -> str:
        log.debug("Maptiler API key loaded.")
        return FlightBridge._maptiler_key

    # ------------------------------------------------------------------ slots

    @Slot(str)
    def loadFile(self, path: str) -> None:
        log.debug(f"Loading IGC file: {path}")
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
                {
                    "title": "Max Altitude",
                    "value": str(s.max_alt),
                    "unit": "m",
                    "note": "",
                },
                {
                    "title": "Altitude Gain",
                    "value": str(s.gain),
                    "unit": "m",
                    "note": "altitude gain from takeoff",
                },
                {
                    "title": "Max Speed",
                    "value": f"{s.max_speed:.1f}",
                    "unit": "km/h",
                    "note": "estimated",
                },
                {
                    "title": "Max Climb",
                    "value": f"{s.max_climb:.1f}",
                    "unit": "m/s",
                    "note": "",
                },
                {
                    "title": "Avg. Thermal",
                    "value": f"{s.avg_thermal_climb:.1f}",
                    "unit": "m/s",
                    "note": "",
                },
                {
                    "title": "Takeoff Altitude",
                    "value": str(self._flight.points[0].alt),
                    "unit": "m",
                    "note": "",
                },
                {
                    "title": "Max Sink",
                    "value": f"{s.max_sink:.1f}",
                    "unit": "m/s",
                    "note": "",
                },
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

    @Property("QVariantList", notify=flightLoaded)  # ty: ignore[invalid-argument-type]
    def trackCoordinates(self) -> list:
        return [QGeoCoordinate(p.lat, p.lon) for p in self._flight.points]

    @Property(QGeoRectangle, notify=flightLoaded)
    def trackBounds(self) -> QGeoRectangle:
        if not self._flight.valid:
            return QGeoRectangle()
        lats = [p.lat for p in self._flight.points]
        lons = [p.lon for p in self._flight.points]
        return QGeoRectangle(
            QGeoCoordinate(max(lats), min(lons)), QGeoCoordinate(min(lats), max(lons))
        )

    def getCoordinate(self, index: int) -> QGeoCoordinate:
        if not self._flight.valid:
            return QGeoCoordinate()

        p = self._flight.points[index]
        return QGeoCoordinate(p.lat, p.lon)

    @Property(QGeoCoordinate, notify=flightLoaded)
    def startCoordinate(self) -> QGeoCoordinate:
        return self.getCoordinate(0)

    @Property(QGeoCoordinate, notify=flightLoaded)
    def endCoordinate(self) -> QGeoCoordinate:
        return self.getCoordinate(-1)

    @Property(QGeoCoordinate, notify=highlightChanged)
    def highlightCoordinate(self) -> QGeoCoordinate:
        if self._highlighted_index < 0 or not self._flight.valid:
            return QGeoCoordinate()
        return self.getCoordinate(self._highlighted_index)
