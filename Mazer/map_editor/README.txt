Lines are used to show the borders
Red - left, bottom limits (static)
Green - represents the default screen size of mobile device (HD resolution)
Blue - represents in-game camera limits


Controls:
Q - open items menu
LMB/RMB - place/remove item
W,A,S,D - move camera around
Mouse Wheel - zoom in/out

Esc - open menu



Map editor saves the tiles info into scene's meta data.
So please don't edit the TileMap using the Godot's editor (although correctly adding/modifying things different from TileMaps should work fine).
^ This won't corrupt the file, but changes probably wont be loaded by the map editor later on.
Map editor will most likely load the maps using that meta data instead of TileMaps themself.

Items menu will contain some useful tips about the items later on (just mouse-hover over some element).