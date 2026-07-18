"""Standalone dev harness: load an IGC file and show only the AltitudeChart.

Usage: uv run python scripts/dev_altitude_chart.py path/to/flight.igc
"""

import sys
from pathlib import Path

from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "src"))

from igcviewer.bridge import FlightBridge  # noqa: E402


def main() -> None:
    if len(sys.argv) < 2:
        print("Usage: dev_altitude_chart.py <file.igc>")
        sys.exit(1)

    igc_file = sys.argv[1]
    if not Path(igc_file).exists():
        print(f"File not found: {igc_file}")
        sys.exit(1)

    app = QGuiApplication([sys.argv[0]])
    app.setApplicationName("IGC Flight Viewer")
    app.setOrganizationName("igcviewer")

    src_dir = Path(__file__).resolve().parent.parent / "src" / "igcviewer"

    engine = QQmlApplicationEngine()
    engine.addImportPath(str(src_dir))
    engine.loadFromModule("qml", "AltitudeChartHarness")

    if not engine.rootObjects():
        sys.exit(1)

    FlightBridge.instance().loadFile(igc_file)

    ret = app.exec()
    del engine
    sys.exit(ret)


if __name__ == "__main__":
    main()
