//
//  CDetour.cpp
//  
//
//  Created by Fedor Artemenkov on 13/4/24.
//

#include "CDetour.h"
#include "DetourNavMesh.h"
#include "DetourNavMeshQuery.h"
#include "string.h"

static const int MAX_POLYS = 256;

float m_straightPath[MAX_POLYS*3];

dtNavMeshQuery* create_query(dtNavMesh* mesh)
{
    dtNavMeshQuery* query = dtAllocNavMeshQuery();
    query->init(mesh, 2048);
    
    return (dtNavMeshQuery*) query;
}

Path find_path(dtNavMeshQuery* query, simd_float3 start, simd_float3 end, simd_float3 half_extents)
{
    if (query == NULL) return {};
    
    memset(m_straightPath, 0, MAX_POLYS*3 * sizeof(m_straightPath[0]));
    
    float m_spos[3] = { start.x, start.y, start.z };
    float m_epos[3] = { end.x, end.y, end.z };
    float ext[3] = { half_extents.x, half_extents.y, half_extents.z };
    
    dtQueryFilter m_filter;
    m_filter.setIncludeFlags(1);
    m_filter.setExcludeFlags(0);
    
    dtPolyRef m_startRef;
    query->findNearestPoly(m_spos, ext, &m_filter, &m_startRef, m_spos);
    
    dtPolyRef m_endRef;
    query->findNearestPoly(m_epos, ext, &m_filter, &m_endRef, m_epos);
    
    dtPolyRef m_polys[MAX_POLYS];
    int m_npolys;
    query->findPath(m_startRef, m_endRef, m_spos, m_epos, &m_filter, m_polys, &m_npolys, MAX_POLYS);
    
    int m_nstraightPath = 0;
    
    unsigned char m_straightPathFlags[MAX_POLYS];
    dtPolyRef m_straightPathPolys[MAX_POLYS];
    
    if (m_npolys)
    {
        
        float epos[3] = { m_epos[0], m_epos[1], m_epos[2] };
        
        // In case of partial path, make sure the end point is clamped to the last polygon.
        if (m_polys[m_npolys-1] != m_endRef)
        {
            query->closestPointOnPoly(m_polys[m_npolys-1], m_epos, epos, 0);
        }
        
        query->findStraightPath(m_spos, epos, m_polys, m_npolys,
                                m_straightPath, m_straightPathFlags,
                                m_straightPathPolys, &m_nstraightPath,
                                MAX_POLYS, 0);
    }
    
    return { m_straightPath, m_nstraightPath };
}

void destroy_navmesh(dtNavMesh* mesh)
{
    dtFreeNavMesh(mesh);
}

void destroy_query(dtNavMeshQuery* query)
{
    dtFreeNavMeshQuery(query);
}
