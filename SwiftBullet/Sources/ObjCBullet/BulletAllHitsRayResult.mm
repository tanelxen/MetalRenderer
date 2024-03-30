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

#import "BulletAllHitsRayResult.h"
#import "BulletRayHit.h"
#import "BulletUpAxis.h"
#import "BulletCollision/CollisionDispatch/btCollisionWorld.h"

struct  RayCastAllHitsRayResultCallback : public btCollisionWorld::AllHitsRayResultCallback
{
  btAlignedObjectArray<int> m_shapePart;
  btAlignedObjectArray<int> m_triangleIndex;
  
  RayCastAllHitsRayResultCallback (const btVector3 &rayFrom, const btVector3 &rayTo)
    : btCollisionWorld::AllHitsRayResultCallback(rayFrom, rayTo)
  {}
  
  virtual ~RayCastAllHitsRayResultCallback()
  {}
  
  btScalar addSingleResult(btCollisionWorld::LocalRayResult &rayResult, bool normalInWorldSpace) override
  {
    btScalar result = AllHitsRayResultCallback::addSingleResult(rayResult, normalInWorldSpace);
    
    if (rayResult.m_localShapeInfo) {
      m_shapePart.push_back(rayResult.m_localShapeInfo->m_shapePart);
      m_triangleIndex.push_back(rayResult.m_localShapeInfo->m_triangleIndex);
    }
    else {
      m_shapePart.push_back(-1);
      m_triangleIndex.push_back(-1);
    }
    
    return result;
  }
};

@implementation BulletAllHitsRayResult
{
  RayCastAllHitsRayResultCallback *m_callback;
}

- (instancetype)initWithFrom:(vector_float3)from
                          to:(vector_float3)to
        collisionFilterGroup:(int)collisionFilterGroup
         collisionFilterMask:(int)collisionFilterMask
{
  self = [super init];
  if (self) {
    m_callback = new RayCastAllHitsRayResultCallback(btVector3(from.x, from.y, from.z),
                                                     btVector3(to.x, to.y, to.z));
    m_callback->m_collisionFilterGroup = collisionFilterGroup;
    m_callback->m_collisionFilterMask = collisionFilterMask;
  }
  return self;
}

- (void)dealloc
{
  delete m_callback;
}

- (btAllHitsRayResultCallbackC *)callback
{
  return bullet_cast(m_callback);
}

- (vector_float3)from
{
  return vector3(m_callback->m_rayFromWorld.x(), m_callback->m_rayFromWorld.y(), m_callback->m_rayFromWorld.z());
}

- (vector_float3)to
{
  return vector3(m_callback->m_rayToWorld.x(), m_callback->m_rayToWorld.y(), m_callback->m_rayToWorld.z());
}

- (int)collisionFilterGroup
{
  return m_callback->m_collisionFilterGroup;
}

- (int)collisionFilterMask
{
  return m_callback->m_collisionFilterMask;
}

- (BOOL)hasHits
{
  return m_callback->hasHit();
}

- (float)closestHitFraction
{
  return m_callback->m_closestHitFraction;
}

- (NSUInteger)numberOfHits
{
  return m_callback->m_collisionObjects.size();
}

- (BulletRayHit *)hitAt:(NSUInteger)index
{
  btVector3 hitNormal = m_callback->m_hitNormalWorld[static_cast<int>(index)];
  btVector3 hitPoint = m_callback->m_hitPointWorld[static_cast<int>(index)];
  BulletRayHit *hit = [[BulletRayHit alloc] initWithCollisionObject:bullet_cast(m_callback->m_collisionObjects[static_cast<int>(index)])
                                                          hitNormal:vector3(hitNormal.x(), hitNormal.y(), hitNormal.z())
                                                             hitPos:vector3(hitPoint.x(), hitPoint.y(), hitPoint.z())
                                                        hitFraction:m_callback->m_hitFractions[static_cast<int>(index)]
                                                          shapePart:m_callback->m_shapePart[static_cast<int>(index)]
                                                      triangleIndex:m_callback->m_triangleIndex[static_cast<int>(index)]];
  return hit;
}

@end
