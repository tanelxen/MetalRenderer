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
- ✅ Bullet physics
- ✅ Navmesh building and pathfinding with Recast
- ✅ Ambient lightning for skeletal meshes (light grid)
- ✅ Sandbox editor based on ImGUI
- ✅ Simple particles (CPU driven)
- ✅ Decals on static geometry
- ✅ Hit detection with entities

## PREVIEW
![sandbox run mode](https://github.com/tanelxen/MetalRenderer/assets/14359330/a250ff78-26f6-4284-a62f-20dbdd3feaa2)

## THIS REPOSITORY IS ABANDONED
It was funny to try make it all with Swift. But I constantly encountered the difficulties this language bring. I got tired of struggling with Swift and decided to continue developing in C++ and OpenGL.

## NOTE
At this moment the code doesn't look good because I'm experimenting with some techniques and trying to find out better way.
Don't take it as production ready game engine. It's just my playground. However, I seek to stay code quite straightforward and understandable.

Better to run Sandbox first time. While first running Sandbox asks you to locate 'Working Dir'. In this case you'll have to choose directory 'WorkingDir' at directory with project. After that Game should work fine. You always can change 'Working Dir' via Settings menu in the toolbar.

NPCs react to shooting at them and try to run away. It's a simple example of pathfinding with navmesh.

Use 'E' for grab or drop pink cube. You also can find code to add ramp with hinge.

Keep in mind that paths to skeletal mesh assets are hardcoded in the code. Sandbox just able you to import GoldSrc .mdl into internal format. After that you have to use imported mesh manually in the code. However .bsp files you can just drag-n-drop in the folder in the Assets panel and run it after converting.

Repository uses Git LFS.

## ANOTHER BRANCHES
- spatial-partition branch contains structures and algorithms for collision detection: aabb-tree, octree and spation hash grid. And the last one works much faster than bsp.
- brush-drawing brunch contains some code for half-edge mesh editing.
- csg branch contains level editing code: drawing brushes, csg-operations, applying textures.
