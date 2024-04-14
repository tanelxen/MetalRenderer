//
//  CDetour.hpp
//  
//
//  Created by Fedor Artemenkov on 13/4/24.
//

#ifndef CDetour_hpp
#define CDetour_hpp

#include "stdlib.h"
#include "simd/simd.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct dtNavMesh dtNavMesh;
typedef struct dtNavMeshQuery dtNavMeshQuery;

typedef struct {
    float* points;
    int count;
} Path;

dtNavMesh* create_navmesh(const void* data, size_t size);
dtNavMeshQuery* create_query(dtNavMesh* mesh);

Path find_path(dtNavMeshQuery* query, simd_float3 start, simd_float3 end, simd_float3 half_extents);

void destroy_navmesh(dtNavMesh* mesh);
void destroy_query(dtNavMeshQuery* query);

#ifdef __cplusplus
}
#endif

#endif /* CDetour_hpp */
