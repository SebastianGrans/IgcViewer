import argparse
import logging
import signal
import sys
from pathlib import Path

from PySide6.QtCore import QUrl
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine
from rich.logging import RichHandler


from .bridge import FlightBridge

log = logging.getLogger(__name__)


def arg_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="IGC Flight Viewer")
    parser.add_argument(
        "igc_file",
        nargs="?",
        metavar="FILE",
        help="IGC file to open on startup",
    )
    parser.add_argument(
        "-v",
        "--verbose",
        action="store_true",
        help="Enable verbose logging",
    )
    return parser


def main() -> None:
    logging.basicConfig(
        level=logging.INFO,
        format="%(message)s",
        datefmt="[%X]",
        handlers=[RichHandler(rich_tracebacks=True)],
    )

    signal.signal(signal.SIGINT, signal.SIG_DFL)

    args, qt_args = arg_parser().parse_known_args()

    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)

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
