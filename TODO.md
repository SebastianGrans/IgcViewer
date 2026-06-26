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
