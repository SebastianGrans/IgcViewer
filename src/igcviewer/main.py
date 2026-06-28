import argparse
import logging
import os
import signal
import sys
from pathlib import Path

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


def _maptiler_key() -> str:
    if key := os.environ.get("MAPTILER_KEY"):
        return key
    key_file = Path(".vscode/key.txt")
    if key_file.exists():
        return key_file.read_text().strip()
    return ""


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

    FlightBridge._maptiler_key = _maptiler_key()

    engine = QQmlApplicationEngine()
    engine.addImportPath(str(Path(__file__).parent))
    engine.loadFromModule("qml", "Main")

    if not engine.rootObjects():
        sys.exit(1)

    if args.igc_file:
        bridge = FlightBridge.instance()  # type: ignore[attr-defined]
        if not Path(args.igc_file).exists():
            bridge.flightError.emit(f"File not found: {args.igc_file}")
        else:
            bridge.loadFile(args.igc_file)

    ret = app.exec()
    # Destroy the QML engine before the singleton goes out of scope, otherwise
    # the engine's final binding evaluation fires with FlightBridge=null and
    # produces a flood of TypeError messages.
    del engine
    sys.exit(ret)


if __name__ == "__main__":
    main()
