# Development instructions

The code should be checked with `ty`, `ruff`, and `qmllint`. The `Makefile` makes that easier.

```
> make     
lint     - run ruff check --fix and ruff format
check    - run ruff check and ty (read-only)
stubs    - regenerate QML type stubs from bridge.py
qmllint  - lint all QML files (regenerates stubs first if needed)
run      - launch the app
```

