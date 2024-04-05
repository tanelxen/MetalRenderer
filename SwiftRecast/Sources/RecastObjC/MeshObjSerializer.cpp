//
//  MeshObjWritter.cpp
//  
//
//  Created by Fedor Artemenkov on 04.04.2024.
//

#include "Utils.h"
#include "Recast.h"
#include <stdio.h>
#include <vector>

size_t saveAsObjToMemory(char** data, const rcPolyMeshDetail* mesh)
{
    if (!mesh) return 0;
    
    size_t buffer_size = 0;
    FILE* fp = open_memstream(data, &buffer_size);

    std::vector<float> nav_vertices;
    std::vector<int> nav_indices;
    
    for (int i = 0; i < mesh->nverts; i++)
    {
        const float *v = &mesh->verts[i * 3];
        
        nav_vertices.push_back(v[0]);
        nav_vertices.push_back(v[1]);
        nav_vertices.push_back(v[2]);
    }
    
    for (int i = 0; i < mesh->nmeshes; i++)
    {
        const unsigned int *detail_mesh_m = &mesh->meshes[i * 4];
        
        const unsigned int detail_mesh_bverts = detail_mesh_m[0];
        const unsigned int detail_mesh_m_btris = detail_mesh_m[2];
        const unsigned int detail_mesh_ntris = detail_mesh_m[3];
        
        const unsigned char *detail_mesh_tris = &mesh->tris[detail_mesh_m_btris * 4];
        
        for (unsigned int j = 0; j < detail_mesh_ntris; j++)
        {
            int v0 = ((int)(detail_mesh_bverts + detail_mesh_tris[j * 4 + 0]));
            int v1 = ((int)(detail_mesh_bverts + detail_mesh_tris[j * 4 + 1]));
            int v2 = ((int)(detail_mesh_bverts + detail_mesh_tris[j * 4 + 2]));
            
            // Polygon order in recast is opposite than our's
            nav_indices.push_back(v0);
            nav_indices.push_back(v2);
            nav_indices.push_back(v1);
        }
    }

    for (int i = 0; i < nav_vertices.size(); i += 3)
    {
        float* vertex = &nav_vertices[i];
        fprintf(fp, "v %f %f %f\n", vertex[0], -vertex[2], vertex[1]);
    }

    for (int i = 0; i < nav_indices.size(); i += 3)
    {
        int* poly = &nav_indices[i];
        fprintf(fp, "f %d %d %d\n", poly[0] + 1, poly[1] + 1, poly[2] + 1);
    }

    fclose(fp);
    
    return buffer_size;
}

void saveAsObjToFile(const char* path, const struct rcPolyMeshDetail* mesh)
{
    if (!mesh) return;
    
    char *buffer = NULL;
    size_t buffer_size = saveAsObjToMemory(&buffer, mesh);
    
    FILE *fp = fopen(path, "w");
    if (!fp) return;
    
    fwrite(buffer, sizeof(char), buffer_size, fp);
    fclose(fp);
    
    free(buffer);
}
