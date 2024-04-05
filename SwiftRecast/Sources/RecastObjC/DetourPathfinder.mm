//
//  DetourPathfinder.mm
//  
//
//  Created by Fedor Artemenkov on 05.04.2024.
//

#import "Include/DetourPathfinder.h"
#import "Utils.h"

#import "DetourCommon.h"
#import "DetourNavMesh.h"
#import "DetourNavMeshQuery.h"

static const int MAX_POLYS = 256;

@implementation DetourPathfinder
{
    dtNavMesh* m_navMesh;
    dtNavMeshQuery* m_navQuery;
    dtQueryFilter m_filter;
    
    dtPolyRef m_startRef;
    dtPolyRef m_endRef;
    dtPolyRef m_polys[MAX_POLYS];
    dtPolyRef m_parent[MAX_POLYS];
    int m_npolys;
    float m_straightPath[MAX_POLYS*3];
    unsigned char m_straightPathFlags[MAX_POLYS];
    dtPolyRef m_straightPathPolys[MAX_POLYS];
    int m_nstraightPath;
    float m_polyPickExt[3];
    
    int m_straightPathOptions;
}

- (instancetype)init
{
    if (self = [super init])
    {
        m_navQuery = dtAllocNavMeshQuery();
        
        m_filter.setIncludeFlags(SAMPLE_POLYFLAGS_ALL ^ SAMPLE_POLYFLAGS_DISABLED);
        m_filter.setExcludeFlags(0);

        m_polyPickExt[0] = 2;
        m_polyPickExt[1] = 4;
        m_polyPickExt[2] = 2;
    }
    
    return self;
}

- (void)loadFromData:(NSData*)data
{
    dtFreeNavMesh(m_navMesh);
    
    m_navMesh = loadAllFromMemory(data.bytes, data.length);
    m_navQuery->init(m_navMesh, 2048);
}

- (nullable NSArray*)getPathStartPos:(simd_float3)startPos endPos:(simd_float3)endPos
{
    if (!m_navMesh) return nil;
    
    float m_spos[3] = { startPos.x, startPos.y, startPos.z };
    float m_epos[3] = { endPos.x, endPos.y, endPos.z };
    
    m_navQuery->findNearestPoly(m_spos, m_polyPickExt, &m_filter, &m_startRef, 0);
    m_navQuery->findNearestPoly(m_epos, m_polyPickExt, &m_filter, &m_endRef, 0);
    
    m_navQuery->findPath(m_startRef, m_endRef, m_spos, m_epos, &m_filter, m_polys, &m_npolys, MAX_POLYS);
    
    m_straightPathOptions = 0;
    m_nstraightPath = 0;
    
    if (m_npolys)
    {
        // In case of partial path, make sure the end point is clamped to the last polygon.
        float epos[3];
        dtVcopy(epos, m_epos);
        if (m_polys[m_npolys-1] != m_endRef)
            m_navQuery->closestPointOnPoly(m_polys[m_npolys-1], m_epos, epos, 0);
        
        m_navQuery->findStraightPath(m_spos, epos, m_polys, m_npolys,
                                     m_straightPath, m_straightPathFlags,
                                     m_straightPathPolys, &m_nstraightPath,
                                     MAX_POLYS, m_straightPathOptions);
    }
    
    if (!m_nstraightPath) return nil;
    
    NSMutableArray *array = [NSMutableArray arrayWithCapacity: m_nstraightPath];
    
    for (int i = 0; i < m_nstraightPath; i++)
    {
        float* point = &m_straightPath[i * 3];
        simd_float3 vector = { point[0], point[1], point[2] };
        
        [array addObject: [NSValue valueWithBytes: &vector objCType: @encode(float[3])]];
    }
    
    return [array copy];
}

- (void)dealloc
{
    dtFreeNavMesh(m_navMesh);
    dtFreeNavMeshQuery(m_navQuery);
}

@end
