#  Metal Renderer

Simple game engine was written with Swift and Metal in just fun purposes.
Heavy inspired Id-Tech and Valve engines.

Features:
- ✅ Forward rendering
- ✅ Internal assets format for scenes
- ✅ Internal assets format for skinned meshes
- ✅ Importer from Quake 3 .bsp
- ✅ Importer from GoldSrc .mdl
- ✅ Skeletal animation
- ✅ Brush based collision detection
- ✅ Quake-style player movement
- ✅ AI navigation with waypoints and A\*\
- ✅ Ambient lightning for skeletal meshes (light grid)
- ✅ Sandbox editor based on ImGUI
- ✅ Simple particles (CPU driven)
- ✅ Decals on static geometry
- ✅ Hit detection with entities

## PREVIEW
![sandbox run mode](https://github.com/tanelxen/MetalRenderer/assets/14359330/dec91dfb-033d-4dfd-b9f7-3e746d3f30c1)

## NOTE
At this moment the code doesn't look good because I'm experimenting with some techniques and trying to find out better way.
Don't take it as production ready game engine. It's just my playground. However, I seek to stay code quite straightforward and understandable.
Later I'm going to refactor all of that. And then perhaps it will be useful for someone.

Better to run Sandbox first time. While first running Sandbox asks you to locate 'Working Dir'. In this case you'll have to choose directory 'WorkingDir' at directory with project. After that Game should work fine. You always can change 'Working Dir' via Settings menu in the toolbar.

Keep in mind that paths to skeletal mesh assets are hardcoded in the code. Sandbox just able you to import GoldSrc .mdl into internal format. After that you have to use imported mesh manually in the code. However .bsp files you can just drag-n-drop in the folder in the Assets panel and run it after converting.

## IN PRORESS
- 🚧 Integration with Bullet physics
- 🚧 Improving navigation system with navmesh

## TODO
- [ ] Brush creation inside Sandbox
- [ ] Animation system
- [ ] Player and AI controllers
- [ ] Integrate Recast for navmesh generating
- [ ] Support Half-Life 2 models and maps
- [ ] GPU driven particle system
- [ ] Material system
- [ ] Rendering UI (besides crosshair)
- [ ] Improve audio engine
- [ ] Rewrite Sandbox in Qt
- [ ] ⚠️ Refactoring all this stuff ⚠️
