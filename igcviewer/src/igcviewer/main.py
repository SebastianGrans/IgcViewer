import argparse
import signal
import sys
from pathlib import Path

from PySide6.QtCore import QUrl
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine

from .bridge import FlightBridge


def main() -> None:
    signal.signal(signal.SIGINT, signal.SIG_DFL)

    parser = argparse.ArgumentParser(description="IGC Flight Viewer")
    parser.add_argument("igc_file", nargs="?", metavar="FILE", help="IGC file to open on startup")
    args, qt_args = parser.parse_known_args()

    app = QGuiApplication([sys.argv[0]] + qt_args)
    app.setApplicationName("IGC Flight Viewer")
    app.setOrganizationName("igcviewer")

    bridge = FlightBridge()

    engine = QQmlApplicationEngine()
    engine.rootContext().setContextProperty("bridge", bridge)

    qml_path = Path(__file__).parent / "qml" / "Main.qml"
    engine.load(QUrl.fromLocalFile(str(qml_path)))

    if not engine.rootObjects():
        sys.exit(1)

    if args.igc_file:
        if not Path(args.igc_file).exists():
            # Show an error message in the GUI
            bridge.flightError.emit(f"File not found: {args.igc_file}")
        else:
            bridge.loadFile(args.igc_file)

    ret = app.exec()
    # Destroy the QML engine before bridge goes out of scope. If bridge is
    # GC'd first, the engine's final binding evaluation fires with bridge=null
    # and produces a flood of TypeError messages in the terminal.
    del engine
    sys.exit(ret)


if __name__ == "__main__":
    main()
