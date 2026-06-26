# TODOs

## Make the stats labels equal height

Currently, the `Flight Distance` and `Max Speed` labels are taller than the others.

This is because those two labels have a `note` (see `statsJson` in `bridge.py`)

## Add "Maximize" button to the map

title

## Drag along the height profile

Now you can click on the profile and it will show the location on the map.

If I click and drag, the selected point should move along the profile and the map should update
accordingly.

## Fix map redrawing

If the flight path is outside the map area, and then you maximize the map (or the window), the path
is not redraw, and the path outside the original map area is not shown.

## QML Linting and other linting

`FlightBridge` is a singleton, but the QML linter doesn't know that. You can fix this by generating
a `.qmltypes` file.

```
pyside6-metaobjectdump ../bridge.py --out-file bridge.json
pyside6-qmltyperegistrar --generate-qmltypes igcviewer.qmltypes \
    --import-name igcviewer --major-version 1 --minor-version 0 bridge.json
```

I also want to run `ty` and `ruff` on this project, so I need a tool that can do this for me.
