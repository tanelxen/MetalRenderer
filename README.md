#  Metal Renderer

Simple game engine was written with Swift and Metal in just fun purposes.
Heavy inspired Id-Tech and Valve engines.

Features:
- Forward rendering
- Loading Quake 3 .bsp
- Loading Half-Life .mdl
- Skeletal animation
- Brush based collision detection
- Quake-style player movement
- AI navigation with waypoints and A\*\.

## PREVIEW
![screenshot1](https://user-images.githubusercontent.com/14359330/227791248-d1f2995d-838a-46ef-83df-00717d90c687.jpg)

Controls:
- `WASD`: Move
- `RMB`: Look around
- `Q`: Place new waypoint
- `E`: Remove waypoint
- `R`: Rebuild navigation graph
- `N`: Move bot at player position

## NOTE
At this moment the code doesn't look good because I'm experimenting with some techniques and trying to find out better way.
Don't take it as production ready game engine. It's just my playground. However, I seek to stay code quite straightforward and understandable.
Later I'm going to refactor all of that. And then perhaps it wll be useful for someone.

## TODO
- [ ] Support Half-Life 2 models and maps
- [ ] Material system
- [ ] Rendering text
- [ ] Lightning for skeletal meshes
- [ ] Blending skeletal animations
- [ ] Improve navigation system
- [ ] Scene editor with ImGUI
- [ ] Refactoring all this stuff
