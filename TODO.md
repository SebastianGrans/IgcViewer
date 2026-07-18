# TODOs


## Handle maptiler API key somehow

Currently not part of the repo. Maybe github secrets + CI build with nuitka?


## Change hight profile x axis

E.g. time instead of distance.

## Enable clicking on the flight path on the map

and tooltips when hovering

## Loading multiple flightlogs

Display them as a list. Clicking them should should display it. If multiple files are loaded, the
first file should be displayed by default

## "Plugin" system

Add a plugin system somehow, such that you can upload a tracklog to a website such as flightlog.org
or xcontext

## Open multiple flightlogs

Display the loaded flightlogs as a list

Clicking on it should open it

## Plugin system

For uploading a flight to various flight logging websites. E.g. `flightlog` or `xcontest`, etc.

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

## Tests

The project is getting big enough that I should set up a test suite.