//
//  NavmeshBulder.mm
//  
//
//  Created by Fedor Artemenkov on 03.04.2024.
//

#import "Include/NavmeshBulder.h"
#import "Utils.h"

#import "Recast.h"
#import "DetourNavMesh.h"
#import "DetourNavMeshBuilder.h"

@implementation NavmeshBulder
{
    float m_cellSize;
    float m_cellHeight;
    float m_agentHeight;
    float m_agentRadius;
    float m_agentMaxClimb;
    float m_agentMaxSlope;
    float m_regionMinSize;
    float m_regionMergeSize;
    float m_edgeMaxLen;
    float m_edgeMaxError;
    float m_vertsPerPoly;
    float m_detailSampleDist;
    float m_detailSampleMaxError;
    
    rcConfig m_cfg;
    rcContext* m_ctx;
    
    rcHeightfield* m_solid;
    unsigned char* m_triareas;
    rcCompactHeightfield* m_chf;
    rcContourSet* m_cset;
    rcPolyMesh* m_pmesh;
    rcPolyMeshDetail* m_dmesh;
    
    dtNavMesh* m_navMesh;
}

- (instancetype)init
{
    if (self = [super init])
    {
        m_cellSize = 5.0f;
        m_cellHeight = 5.0f;
        m_agentHeight = 2.0f;
        m_agentRadius = 30.0f;
        m_agentMaxClimb = 20.0f;
        m_agentMaxSlope = 45.0f;
        m_regionMinSize = 8.0f;
        m_regionMergeSize = 20.0f;
        m_edgeMaxLen = 1.0f;
        m_edgeMaxError = 1.3f;
        m_vertsPerPoly = 3.0f;
        m_detailSampleDist = 3.0f;
        m_detailSampleMaxError = 1.0f;
        
        m_ctx = new rcContext;
    }
    
    return self;
}

- (void)calculateVerts:(const float*)verts nverts:(int)nverts tris:(const int*)tris ntris:(int)ntris
{
    float bmin[3];
    float bmax[3];
    rcCalcBounds(verts, nverts, bmin, bmax);
    
    //
    // Step 1. Initialize build config.
    //
    
    memset(&m_cfg, 0, sizeof(m_cfg));
    m_cfg.cs = m_cellSize;
    m_cfg.ch = m_cellHeight;
    m_cfg.walkableSlopeAngle = m_agentMaxSlope;
    m_cfg.walkableHeight = (int)ceilf(m_agentHeight / m_cfg.ch);
    m_cfg.walkableClimb = (int)floorf(m_agentMaxClimb / m_cfg.ch);
    m_cfg.walkableRadius = (int)ceilf(m_agentRadius / m_cfg.cs);
    m_cfg.maxEdgeLen = (int)(m_edgeMaxLen / m_cellSize);
    m_cfg.maxSimplificationError = m_edgeMaxError;
    m_cfg.minRegionArea = (int)rcSqr(m_regionMinSize);        // Note: area = size*size
    m_cfg.mergeRegionArea = (int)rcSqr(m_regionMergeSize);    // Note: area = size*size
    m_cfg.maxVertsPerPoly = (int)m_vertsPerPoly;
    m_cfg.detailSampleDist = m_detailSampleDist < 0.9f ? 0 : m_cellSize * m_detailSampleDist;
    m_cfg.detailSampleMaxError = m_cellHeight * m_detailSampleMaxError;
    
    // Set the area where the navigation will be built.
    // Here the bounds of the input mesh are used, but the
    // area could be specified by an user defined box, etc.
    rcVcopy(m_cfg.bmin, bmin);
    rcVcopy(m_cfg.bmax, bmax);
    rcCalcGridSize(m_cfg.bmin, m_cfg.bmax, m_cfg.cs, &m_cfg.width, &m_cfg.height);
    
    
    //
    // Step 2. Rasterize input polygon soup.
    //
    
    // Allocate voxel heightfield where we rasterize our input data to.
    m_solid = rcAllocHeightfield();
    
    if (!m_solid)
    {
        m_ctx->log(RC_LOG_ERROR, "buildNavigation: Out of memory 'solid'.");
        return;
    }
    if (!rcCreateHeightfield(m_ctx, *m_solid, m_cfg.width, m_cfg.height, m_cfg.bmin, m_cfg.bmax, m_cfg.cs, m_cfg.ch))
    {
        m_ctx->log(RC_LOG_ERROR, "buildNavigation: Could not create solid heightfield.");
        return;
    }
    
    // Allocate array that can hold triangle area types.
    // If you have multiple meshes you need to process, allocate
    // and array which can hold the max number of triangles you need to process.
    m_triareas = new unsigned char[ntris];
    memset(m_triareas, 0, ntris * sizeof(unsigned char));
    
    // Find triangles which are walkable based on their slope and rasterize them.
    // If your input data is multiple meshes, you can transform them here, calculate
    // the are type for each of the meshes and rasterize them.
    rcMarkWalkableTriangles(m_ctx, m_cfg.walkableSlopeAngle, verts, nverts, tris, ntris, m_triareas);
    rcRasterizeTriangles(m_ctx, verts, nverts, tris, m_triareas, ntris, *m_solid, m_cfg.walkableClimb);
    
    //
    // Step 3. Filter walkable surfaces.
    //
    
    // Once all geometry is rasterized, we do initial pass of filtering to
    // remove unwanted overhangs caused by the conservative rasterization
    // as well as filter spans where the character cannot possibly stand.
    rcFilterLowHangingWalkableObstacles(m_ctx, m_cfg.walkableClimb, *m_solid);
    rcFilterLedgeSpans(m_ctx, m_cfg.walkableHeight, m_cfg.walkableClimb, *m_solid);
    rcFilterWalkableLowHeightSpans(m_ctx, m_cfg.walkableHeight, *m_solid);
    
    //
    // Step 4. Partition walkable surface to simple regions.
    //

    // Compact the heightfield so that it is faster to handle from now on.
    // This will result more cache coherent data as well as the neighbours
    // between walkable cells will be calculated.
    m_chf = rcAllocCompactHeightfield();
    
    if (!m_chf)
    {
        m_ctx->log(RC_LOG_ERROR, "buildNavigation: Out of memory 'chf'.");
        return;
    }
    
    if (!rcBuildCompactHeightfield(m_ctx, m_cfg.walkableHeight, m_cfg.walkableClimb, *m_solid, *m_chf))
    {
        m_ctx->log(RC_LOG_ERROR, "buildNavigation: Could not build compact data.");
        return;
    }
    
    // Erode the walkable area by agent radius.
    if (!rcErodeWalkableArea(m_ctx, m_cfg.walkableRadius, *m_chf))
    {
        m_ctx->log(RC_LOG_ERROR, "buildNavigation: Could not erode.");
        return;
    }
    
    // Watershed partitioning

    // Prepare for region partitioning, by calculating distance field along the walkable surface.
    if (!rcBuildDistanceField(m_ctx, *m_chf))
    {
        m_ctx->log(RC_LOG_ERROR, "buildNavigation: Could not build distance field.");
        return;
    }
    
    // Partition the walkable surface into simple regions without holes.
    if (!rcBuildRegions(m_ctx, *m_chf, 0, m_cfg.minRegionArea, m_cfg.mergeRegionArea))
    {
        m_ctx->log(RC_LOG_ERROR, "buildNavigation: Could not build watershed regions.");
        return;
    }
    
    //
    // Step 5. Trace and simplify region contours.
    //
    
    // Create contours.
    m_cset = rcAllocContourSet();
    if (!m_cset)
    {
        m_ctx->log(RC_LOG_ERROR, "buildNavigation: Out of memory 'cset'.");
        return;
    }
    if (!rcBuildContours(m_ctx, *m_chf, m_cfg.maxSimplificationError, m_cfg.maxEdgeLen, *m_cset))
    {
        m_ctx->log(RC_LOG_ERROR, "buildNavigation: Could not create contours.");
        return;
    }
    
    //
    // Step 6. Build polygons mesh from contours.
    //
    
    // Build polygon navmesh from the contours.
    m_pmesh = rcAllocPolyMesh();
    if (!m_pmesh)
    {
        m_ctx->log(RC_LOG_ERROR, "buildNavigation: Out of memory 'pmesh'.");
        return;
    }
    if (!rcBuildPolyMesh(m_ctx, *m_cset, m_cfg.maxVertsPerPoly, *m_pmesh))
    {
        m_ctx->log(RC_LOG_ERROR, "buildNavigation: Could not triangulate contours.");
        return;
    }
    
    //
    // Step 7. Create detail mesh which allows to access approximate height on each polygon.
    //
    
    m_dmesh = rcAllocPolyMeshDetail();
    if (!m_dmesh)
    {
        m_ctx->log(RC_LOG_ERROR, "buildNavigation: Out of memory 'pmdtl'.");
        return;
    }

    if (!rcBuildPolyMeshDetail(m_ctx, *m_pmesh, *m_chf, m_cfg.detailSampleDist, m_cfg.detailSampleMaxError, *m_dmesh))
    {
        m_ctx->log(RC_LOG_ERROR, "buildNavigation: Could not build detail mesh.");
        return;
    }
    
    // At this point the navigation mesh data is ready, you can access it from m_pmesh.
    
    //
    // Step 8. Create Detour data from Recast poly mesh.
    //

    // Update poly flags from areas.
    for (int i = 0; i < m_pmesh->npolys; ++i)
    {
        if (m_pmesh->areas[i] == RC_WALKABLE_AREA)
            m_pmesh->areas[i] = SAMPLE_POLYAREA_GROUND;
            
        if (m_pmesh->areas[i] == SAMPLE_POLYAREA_GROUND ||
            m_pmesh->areas[i] == SAMPLE_POLYAREA_GRASS ||
            m_pmesh->areas[i] == SAMPLE_POLYAREA_ROAD)
        {
            m_pmesh->flags[i] = SAMPLE_POLYFLAGS_WALK;
        }
        else if (m_pmesh->areas[i] == SAMPLE_POLYAREA_WATER)
        {
            m_pmesh->flags[i] = SAMPLE_POLYFLAGS_SWIM;
        }
        else if (m_pmesh->areas[i] == SAMPLE_POLYAREA_DOOR)
        {
            m_pmesh->flags[i] = SAMPLE_POLYFLAGS_WALK | SAMPLE_POLYFLAGS_DOOR;
        }
    }
    
    dtNavMeshCreateParams params;
    memset(&params, 0, sizeof(params));
    
    params.verts = m_pmesh->verts;
    params.vertCount = m_pmesh->nverts;
    params.polys = m_pmesh->polys;
    params.polyAreas = m_pmesh->areas;
    params.polyFlags = m_pmesh->flags;
    params.polyCount = m_pmesh->npolys;
    params.nvp = m_pmesh->nvp;
    params.detailMeshes = m_dmesh->meshes;
    params.detailVerts = m_dmesh->verts;
    params.detailVertsCount = m_dmesh->nverts;
    params.detailTris = m_dmesh->tris;
    params.detailTriCount = m_dmesh->ntris;
    
    params.walkableHeight = m_agentHeight;
    params.walkableRadius = m_agentRadius;
    params.walkableClimb = m_agentMaxClimb;
    rcVcopy(params.bmin, m_pmesh->bmin);
    rcVcopy(params.bmax, m_pmesh->bmax);
    params.cs = m_cfg.cs;
    params.ch = m_cfg.ch;
    params.buildBvTree = true;
    
    unsigned char* navData = 0;
    int navDataSize = 0;
    
    if (!dtCreateNavMeshData(&params, &navData, &navDataSize))
    {
        m_ctx->log(RC_LOG_ERROR, "Could not build Detour navmesh.");
        return;
    }
    
    m_navMesh = dtAllocNavMesh();
    if (!m_navMesh)
    {
        dtFree(navData);
        m_ctx->log(RC_LOG_ERROR, "Could not create Detour navmesh");
        return;
    }
    
    dtStatus status;
    
    status = m_navMesh->init(navData, navDataSize, DT_TILE_FREE_DATA);
    if (dtStatusFailed(status))
    {
        dtFree(navData);
        m_ctx->log(RC_LOG_ERROR, "Could not init Detour navmesh");
        return;
    }
    
    //TODO: clean up all allocated memory
}

- (nullable NSData*)getDetourData
{
    NSData* data = NULL;
    
    char *buffer;
    size_t size = saveAllToMemory(&buffer, m_navMesh);
    
    if (buffer)
    {
        data = [NSData dataWithBytes:(const void *)buffer length:sizeof(char)*size];
        free(buffer);
    }
    
    return data;
}

- (nullable NSData*)getMeshJson
{
    NSData* data = NULL;
    
    char *buffer;
    size_t size = saveAsJsonToMemory(&buffer, m_navMesh);
    
    if (buffer)
    {
        data = [NSData dataWithBytes:(const void *)buffer length:sizeof(char)*size];
        free(buffer);
    }
    
    return data;
}

- (nullable NSData*)getMeshObj
{
    NSData* data = NULL;
    
    char *buffer;
    size_t size = saveAsObjToMemory(&buffer, m_dmesh);
    
    if (buffer)
    {
        data = [NSData dataWithBytes:(const void *)buffer length:sizeof(char)*size];
        free(buffer);
    }
    
    return data;
}

-(void)cleanUp
{
    if (m_triareas != nullptr) {
        delete[] m_triareas;
    }
    
    rcFreeHeightField(m_solid);
    rcFreeCompactHeightfield(m_chf);
    rcFreeContourSet(m_cset);
}

- (void)dealloc
{
    if (m_ctx != nullptr)
    {
        delete m_ctx;
    }
    
    if (m_pmesh != nullptr)
    {
        delete m_pmesh;
    }
    
    if (m_dmesh != nullptr)
    {
        delete m_dmesh;
    }
    
    [self cleanUp];
    
    dtFreeNavMesh(m_navMesh);
}

@end
