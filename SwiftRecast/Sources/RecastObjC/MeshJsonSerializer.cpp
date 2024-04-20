//
//  MeshJsonSerializer.cpp
//  
//
//  Created by Fedor Artemenkov on 05.04.2024.
//

#include "Utils.h"
#include "DetourNavMesh.h"
#include <stdio.h>

size_t saveAsJsonToMemory(char** data, const dtNavMesh* mesh)
{
    if (!mesh) return 0;
    
    size_t buffer_size = 0;

    FILE* fp = open_memstream(data, &buffer_size);
    
    for (int i = 0; i < mesh->getMaxTiles(); ++i)
    {
        fprintf(fp, "{");
        
        const dtMeshTile* tile = mesh->getTile(i);
        if (!tile || !tile->header) continue;
        
        fprintf(fp, "\"verts\":[");
        
        for (int j = 0; j < tile->header->vertCount * 3; j += 3)
        {
            if (j != 0) { fprintf(fp, ","); }
            
            fprintf(fp, "[%f,%f,%f]", tile->verts[j + 0], -tile->verts[j + 2], tile->verts[j + 1]);
        }
        
        fprintf(fp, "],");
        
        fprintf(fp, "\"polys\":[");

        for (int j = 0; j < tile->header->polyCount; ++j)
        {
            const dtPoly* poly = &tile->polys[j];

            if (j != 0) { fprintf(fp, ","); }
            
            fprintf(fp, "[%d,%d,%d]", poly->verts[0], poly->verts[2], poly->verts[1]);
        }
        
        fprintf(fp, "]");
        
        fprintf(fp, "}");
        
        break;
    }
    
    fclose(fp);
    
    return buffer_size;
}

void saveAsJsonToFile(const char* path, const struct dtNavMesh* mesh)
{
    if (!mesh) return;
    
    char *buffer = NULL;
    size_t buffer_size = saveAsJsonToMemory(&buffer, mesh);
    
    FILE *fp = fopen(path, "w");
    if (!fp) return;
    
    fwrite(buffer, sizeof(char), buffer_size, fp);
    fclose(fp);
    
    free(buffer);
}

