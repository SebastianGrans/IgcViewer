# Development instructions

## VS Code setup

To make the the Qt Core/Qt Qml extension work properly, you need to install some Qt compnents. You
need the "Additional Libraries" for Qt 6.11.1

https://doc.qt.io/qt-6/get-and-install-qt.html



## Linting etc.

The code should be checked with `ty`, `ruff`, and `qmllint`. The `Makefile` makes that easier.

```
> make     
lint     - run ruff check --fix and ruff format
check    - run ruff check and ty (read-only)
stubs    - regenerate QML type stubs from bridge.py
qmllint  - lint all QML files (regenerates stubs first if needed)
run      - launch the app
```

