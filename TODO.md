# TODOs


## Handle maptiler API key somehow

Currently not part of the repo. Maybe github secrets + CI build with nuitka?

## Add ability to store light/dark mode preference

title

## Change hight profile x axis

E.g. time instead of distance.

## Enable clicking on the flight path on the map

and tooltips?

## Add ability to replay flight

With a "play" button and a slider to scrub through the flight  
Should also have an input for replay multiplier

### Extension: Add ability to replay flight in 3D view

With "follow" mode, where the camera follows the glider

The follow mode could either be POV, or just external view where the user can change the camera
angle during the replay.

### Use `libigc` to parse IGC files

https://github.com/surajmandalcell/libigc

The parser that was ported from the original C code is very basic, and probably not very robust.
