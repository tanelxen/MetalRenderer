//
//  MeshDetourSerializer.cpp
//  
//
//  Created by Fedor Artemenkov on 05.04.2024.
//

#include "CDetour.h"
#include "DetourNavMesh.h"
#include <stdio.h>
#include <string>
#include <vector>

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

dtNavMesh* create_navmesh(const void* data, size_t size)
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

    return (dtNavMesh*) mesh;
}

SimpleMesh get_simple_mesh(dtNavMesh* mesh)
{
    if (!mesh) return {};
    
    std::vector<float> vertices;
    std::vector<int> indices;
    
    for (int i = 0; i < mesh->getMaxTiles(); ++i)
    {
        const dtMeshTile* tile = mesh->getTile(i);
        if (!tile || !tile->header) continue;
        
        for (int j = 0; j < tile->header->vertCount * 3; j += 3)
        {
            const float *v = &tile->verts[j * 3];
            
            vertices.push_back( tile->verts[j + 0] );
            vertices.push_back( tile->verts[j + 1] );
            vertices.push_back( tile->verts[j + 2] );
        }

        for (int j = 0; j < tile->header->polyCount; ++j)
        {
            const dtPoly* poly = &tile->polys[j];

            indices.push_back( poly->verts[0] );
            indices.push_back( poly->verts[2] );
            indices.push_back( poly->verts[1] );
        }
        
        break;
    }
    
    SimpleMesh result;
    
    result.num_vertices = int(vertices.size());
    result.vertices = (float*)malloc(result.num_vertices * sizeof(float));
    memcpy(result.vertices, vertices.data(), result.num_vertices * sizeof(float));

    result.num_indices = int(indices.size());
    result.indices = (int*)malloc(result.num_indices * sizeof(int));
    memcpy(result.indices, indices.data(), result.num_indices * sizeof(int));
    
    return result;
}
