/**
 Bullet Continuous Collision Detection and Physics Library
 Copyright (c) 2003-2006 Erwin Coumans  http://continuousphysics.com/Bullet/
 
 Swift Binding
 Copyright (c) 2018 Yohei Yoshihara
 
 This software is provided 'as-is', without any express or implied warranty.
 In no event will the authors be held liable for any damages arising from the use of this software.
 Permission is granted to anyone to use this software for any purpose,
 including commercial applications, and to alter it and redistribute it freely,
 subject to the following restrictions:
 
 1. The origin of this software must not be misrepresented; you must not claim that you wrote the original software.
    If you use this software in a product, an acknowledgment in the product documentation would be appreciated
    but is not required.
 2. Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.
 3. This notice may not be removed or altered from any source distribution.
 */

#import "BulletTriangleMeshShape.h"
#import "BulletCollision/CollisionShapes/btBvhTriangleMeshShape.h"
#import "BulletCollision/Gimpact/btGImpactShape.h"
#import "BulletCollision/CollisionShapes/btTriangleMesh.h"
#import "BulletCollision/CollisionShapes/btTriangleMeshShape.h"
#include <iostream>
#include <vector>

class BulletTriangleMeshShapeTriangleCallback : public btTriangleCallback
{
public:
  BulletTriangleMeshShapeTriangleCallback() {}
	virtual void processTriangle(btVector3* triangle, int partId, int triangleIndex)
  {
    NSLog(@"%d: {%g,%g,%g}-{%g,%g,%g}-{%g,%g,%g}", triangleIndex,
          triangle[0].x(), triangle[0].y(), triangle[0].z(),
          triangle[1].x(), triangle[1].y(), triangle[1].z(),
          triangle[2].x(), triangle[2].y(), triangle[2].z());
  }
};

@implementation BulletTriangleMeshShape
{
  btTriangleMesh *m_mesh;
  btIndexedMesh m_indexedMesh;
  btGImpactMeshShape *m_gimpact_shape;
  btBvhTriangleMeshShape *m_bvh_shape;
	btTriangleIndexVertexArray  *m_indexVertexArrays;
  
  std::vector<int> m_indices;
  std::vector<float> m_vertices;
}

- (instancetype)initWithVertexBase:(void *)vertexBase
                  numberOfVertices:(NSInteger)numberOfVertices
                      vertexStride:(NSInteger)vertexStride
                 triangleIndexBase:(void *)triangleIndexBase
                 numberOfTriangles:(NSInteger)numberOfTriangles
               triangleIndexStride:(NSInteger)triangleIndexStride
                         indexType:(BulletIndexType)indexType
                           dynamic:(BOOL)dynamic
                          compress:(BOOL)compress
                               bvh:(BOOL)bvh {
  self = [super init];
  if (self) {
    m_mesh = new btTriangleMesh();
    
    m_indexedMesh.m_numTriangles = (int)numberOfTriangles;
    m_indexedMesh.m_triangleIndexBase = (unsigned char *)triangleIndexBase;
    m_indexedMesh.m_triangleIndexStride = (int)triangleIndexStride;
    m_indexedMesh.m_indexType = indexType == BulletIndexType_uint16 ? PHY_SHORT : PHY_INTEGER;
    
    m_indexedMesh.m_numVertices = (int)numberOfVertices;
    m_indexedMesh.m_vertexBase = (unsigned char *)vertexBase;
    m_indexedMesh.m_vertexStride = (int)vertexStride;
    m_indexedMesh.m_vertexType = PHY_FLOAT;
    
    m_mesh->addIndexedMesh(m_indexedMesh, m_indexedMesh.m_indexType);
    
    // Dynamic will create a GImpact mesh shape
    if (dynamic) {
      m_gimpact_shape = new btGImpactMeshShape(m_mesh);
      m_gimpact_shape->updateBound();
      m_gimpact_shape->setUserPointer((__bridge void *)self);
      
      m_bvh_shape = nullptr;
    }
    
    // Static will create a Bvh mesh shape
    else {
      m_bvh_shape = new btBvhTriangleMeshShape(m_mesh, compress, bvh);
      m_bvh_shape->setUserPointer((__bridge void *)self);
      
      m_gimpact_shape = nullptr;
    }
  }
  return self;
}

- (void)dealloc
{
  if (m_mesh != nullptr) {
    delete m_mesh;
  }
  if (m_gimpact_shape != nullptr) {
    delete m_gimpact_shape;
  }
  if (m_bvh_shape != nullptr) {
    delete m_bvh_shape;
  }
}

- (btCollisionShapeC *)ptr
{
  if (m_bvh_shape) {
    return bullet_cast(static_cast<btCollisionShape *>(m_bvh_shape));
  }

  if (m_gimpact_shape) {
    return bullet_cast(static_cast<btCollisionShape *>(m_gimpact_shape));
  }

  return nullptr;
}

- (btConcaveShapeC *)btConcaveShape
{
  if (m_bvh_shape) {
    return bullet_cast(static_cast<btConcaveShape *>(m_bvh_shape));
  }
  
  if (m_gimpact_shape) {
    return bullet_cast(static_cast<btConcaveShape *>(m_gimpact_shape));
  }
  
  return nullptr;
}

- (BOOL)isDynamicObject
{
  return (m_gimpact_shape != nullptr);
}

- (BOOL)isStaticObject
{
  return (m_bvh_shape != nullptr);
}

- (void)dump
{
  if(m_gimpact_shape) {
    BulletTriangleMeshShapeTriangleCallback triangleCallback;
    m_gimpact_shape->processAllTriangles(&triangleCallback, btVector3(FLT_MIN, FLT_MIN, FLT_MIN), btVector3(FLT_MAX, FLT_MAX, FLT_MAX));
  }
  else {
    BulletTriangleMeshShapeTriangleCallback triangleCallback;
    m_bvh_shape->processAllTriangles(&triangleCallback, btVector3(FLT_MIN, FLT_MIN, FLT_MIN), btVector3(FLT_MAX, FLT_MAX, FLT_MAX));
  }
}

@end
