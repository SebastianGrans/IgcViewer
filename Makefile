QML_DIR = src/igcviewer/qml
BRIDGE_PY = src/igcviewer/bridge.py

.PHONY: help lint check stubs qmllint run

help:
	@echo "lint     - run ruff check --fix and ruff format"
	@echo "check    - run ruff check and ty (read-only)"
	@echo "stubs    - regenerate QML type stubs from bridge.py"
	@echo "qmllint  - lint all QML files (regenerates stubs first if needed)"
	@echo "run      - launch the app"

lint:
	@echo "### Running ruff check --fix and format... ###"
	uv run ruff check --fix src/
	uv run ruff format src/
	@echo "### DONE! ###"

check:
	@echo "### Running `ruff check` and `ty check`... ###"
	uv run ruff check src/
	uv run ty check
	@echo "### DONE! ###"

$(QML_DIR)/igcviewer.qmltypes: $(BRIDGE_PY)
	@echo "### `bridge.py` has changed. Rebuilding `.qmltypes`... ###"
	uv run pyside6-metaobjectdump $(BRIDGE_PY) --out-file $(QML_DIR)/bridge.json
	uv run pyside6-qmltyperegistrar \
		--generate-qmltypes $(QML_DIR)/igcviewer.qmltypes \
		--import-name igcviewer --major-version 1 --minor-version 0 \
		$(QML_DIR)/bridge.json
	
	rm -f $(QML_DIR)/bridge.json
	@echo ""
	@echo "### DONE! ###"

stubs: $(QML_DIR)/igcviewer.qmltypes

qmllint: stubs
	@echo "### Running linter on qml files... ###"
	uv run pyside6-qmllint -I $(QML_DIR) $(QML_DIR)/*.qml
	@echo "### Done! ###"
lintall: qmllint lint check

run:
	uv run igcviewer
