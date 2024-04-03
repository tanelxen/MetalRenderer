//
//  Utils.hpp
//  
//
//  Created by Fedor Artemenkov on 03.04.2024.
//

#ifndef Utils_hpp
#define Utils_hpp

#include "stdlib.h"

struct dtNavMesh;

void saveAsJsonToFile(const char* path, const struct dtNavMesh* mesh);
size_t saveAsJsonToMemory(char** data, const struct dtNavMesh* mesh);

void saveAll(const char* path, const struct dtNavMesh* mesh);
size_t saveAllToMemory(char** data, const struct dtNavMesh* mesh);

struct dtNavMesh* loadAllFromFile(const char* path);
struct dtNavMesh* loadAllFromMemory(const void* data, size_t size);

enum SamplePolyAreas
{
    SAMPLE_POLYAREA_GROUND,
    SAMPLE_POLYAREA_WATER,
    SAMPLE_POLYAREA_ROAD,
    SAMPLE_POLYAREA_DOOR,
    SAMPLE_POLYAREA_GRASS,
    SAMPLE_POLYAREA_JUMP
};

enum SamplePolyFlags
{
    SAMPLE_POLYFLAGS_WALK       = 0x01,        // Ability to walk (ground, grass, road)
    SAMPLE_POLYFLAGS_SWIM       = 0x02,        // Ability to swim (water).
    SAMPLE_POLYFLAGS_DOOR       = 0x04,        // Ability to move through doors.
    SAMPLE_POLYFLAGS_JUMP       = 0x08,        // Ability to jump.
    SAMPLE_POLYFLAGS_DISABLED   = 0x10,        // Disabled polygon
    SAMPLE_POLYFLAGS_ALL        = 0xffff    // All abilities.
};

#endif /* Utils_hpp */
