//
//  MeshDetourSerializer.cpp
//  
//
//  Created by Fedor Artemenkov on 05.04.2024.
//

#include "Utils.h"
#include "DetourNavMesh.h"
#include <stdio.h>
#include <string>

static const int NAVMESHSET_MAGIC = 'M'<<24 | 'S'<<16 | 'E'<<8 | 'T'; //'MSET';
static const int NAVMESHSET_VERSION = 1;

struct NavMeshSetHeader
{
    int magic;
    int version;
    int numTiles;
    dtNavMeshParams params;
};

struct NavMeshTileHeader
{
    dtTileRef tileRef;
    int dataSize;
};

dtNavMesh* loadAllFromMemory(const void* data, size_t size)
{
    const char* chars = (const char*) data;
    
    FILE* fp = fmemopen((void*)data, size, "rb");
    if (!fp) return 0;
    
    // Read header.
    NavMeshSetHeader header;
    size_t readLen = fread(&header, sizeof(NavMeshSetHeader), 1, fp);
    if (readLen != 1)
    {
        fclose(fp);
        return 0;
    }
    if (header.magic != NAVMESHSET_MAGIC)
    {
        fclose(fp);
        return 0;
    }
    if (header.version != NAVMESHSET_VERSION)
    {
        fclose(fp);
        return 0;
    }

    dtNavMesh* mesh = dtAllocNavMesh();
    if (!mesh)
    {
        fclose(fp);
        return 0;
    }
    dtStatus status = mesh->init(&header.params);
    if (dtStatusFailed(status))
    {
        fclose(fp);
        return 0;
    }

    // Read tiles.
    for (int i = 0; i < header.numTiles; ++i)
    {
        NavMeshTileHeader tileHeader;
        readLen = fread(&tileHeader, sizeof(tileHeader), 1, fp);
        if (readLen != 1)
        {
            fclose(fp);
            return 0;
        }

        if (!tileHeader.tileRef || !tileHeader.dataSize)
            break;

        unsigned char* data = (unsigned char*)dtAlloc(tileHeader.dataSize, DT_ALLOC_PERM);
        if (!data) break;
        memset(data, 0, tileHeader.dataSize);
        readLen = fread(data, tileHeader.dataSize, 1, fp);
        if (readLen != 1)
        {
            dtFree(data);
            fclose(fp);
            return 0;
        }

        mesh->addTile(data, tileHeader.dataSize, DT_TILE_FREE_DATA, tileHeader.tileRef, 0);
    }

    fclose(fp);

    return mesh;
}

size_t saveAllToMemory(char** data, const dtNavMesh* mesh)
{
    size_t buffer_size = 0;

    FILE* fp = open_memstream(data, &buffer_size);

    if (!fp) {
        return 0;
    }

    // Store header.
    NavMeshSetHeader header;
    header.magic = NAVMESHSET_MAGIC;
    header.version = NAVMESHSET_VERSION;
    header.numTiles = 0;
    
    for (int i = 0; i < mesh->getMaxTiles(); ++i)
    {
        const dtMeshTile* tile = mesh->getTile(i);
        if (!tile || !tile->header || !tile->dataSize) continue;
        header.numTiles++;
    }
    
    memcpy(&header.params, mesh->getParams(), sizeof(dtNavMeshParams));
    fwrite(&header, sizeof(NavMeshSetHeader), 1, fp);

    // Store tiles.
    for (int i = 0; i < mesh->getMaxTiles(); ++i)
    {
        const dtMeshTile* tile = mesh->getTile(i);
        if (!tile || !tile->header || !tile->dataSize) continue;

        NavMeshTileHeader tileHeader;
        tileHeader.tileRef = mesh->getTileRef(tile);
        tileHeader.dataSize = tile->dataSize;
        fwrite(&tileHeader, sizeof(tileHeader), 1, fp);

        fwrite(tile->data, tile->dataSize, 1, fp);
    }

    fclose(fp);
    
    return buffer_size;
}

void saveAll(const char* path, const struct dtNavMesh* mesh)
{
    if (!mesh) return;
    
    char *buffer = NULL;
    size_t buffer_size = saveAllToMemory(&buffer, mesh);
    
    FILE *output_file = fopen(path, "wb");
    if (!output_file) return;
    
    fwrite(buffer, sizeof(char), buffer_size, output_file);
    fclose(output_file);
    
    free(buffer);
}

