"""Standalone dev harness: load an IGC file and show a single QML component."""

import argparse
import sys
from pathlib import Path

from PySide6.QtWidgets import QApplication
from PySide6.QtQml import QQmlApplicationEngine

from igcviewer.bridge import FlightBridge
from igcviewer.paths import Paths
from igcviewer.main import maptiler_key

COMPONENTS = ["AltitudeChart", "FlightMap", "StatsPanel"]


def main() -> None:
    parser = argparse.ArgumentParser(description="Launch a QML component in isolation.")
    parser.add_argument("component", choices=COMPONENTS)
    parser.add_argument("igc_file", nargs="?", type=Path, metavar="file.igc")
    args = parser.parse_args()

    if args.igc_file and not args.igc_file.exists():
        parser.error(f"File not found: {args.igc_file}")

    component: str = args.component
    igc_file: Path = args.igc_file

    app = QApplication([sys.argv[0]])
    app.setApplicationName("IGC Flight Viewer")
    app.setOrganizationName("igcviewer")

    src_dir = Paths().root

    engine = QQmlApplicationEngine()
    engine.addImportPath(str(src_dir))
    engine.loadFromModule("qml", f"{component}Harness")

    if not engine.rootObjects():
        sys.exit(1)

    FlightBridge._maptiler_key = maptiler_key()

    if igc_file:
        FlightBridge.instance().loadFile(str(igc_file))

    ret = app.exec()
    del engine
    sys.exit(ret)


if __name__ == "__main__":
    main()
