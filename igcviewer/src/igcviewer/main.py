import signal
import sys
from pathlib import Path

from PySide6.QtCore import QUrl
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine

from .bridge import FlightBridge


def main() -> None:
    # Restore the default SIGINT handler so Ctrl+C from a terminal terminates
    # the process. Qt replaces it with SIG_IGN, which causes the signal to be
    # silently swallowed while the event loop runs.
    signal.signal(signal.SIGINT, signal.SIG_DFL)

    app = QGuiApplication(sys.argv)
    app.setApplicationName("IGC Flight Viewer")
    app.setOrganizationName("igcviewer")

    bridge = FlightBridge()

    engine = QQmlApplicationEngine()
    engine.rootContext().setContextProperty("bridge", bridge)

    qml_path = Path(__file__).parent / "qml" / "Main.qml"
    engine.load(QUrl.fromLocalFile(str(qml_path)))

    if not engine.rootObjects():
        sys.exit(1)

    sys.exit(app.exec())


if __name__ == "__main__":
    main()
