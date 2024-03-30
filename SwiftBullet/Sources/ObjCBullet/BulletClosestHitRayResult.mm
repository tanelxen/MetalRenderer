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

#import "BulletClosestHitRayResult.h"
#import "BulletUpAxis.h"
#import "BulletRigidBody.h"
#import "BulletCollision/CollisionDispatch/btCollisionWorld.h"

struct  RayCastClosestRayResultCallback : public btCollisionWorld::ClosestRayResultCallback
{
  int m_shapePart;
  int m_triangleIndex;
  
  RayCastClosestRayResultCallback (const btVector3 &rayFrom, const btVector3 &rayTo)
    : btCollisionWorld::ClosestRayResultCallback(rayFrom, rayTo),
      m_shapePart(-1),
      m_triangleIndex(-1)
  {}
  
  virtual ~RayCastClosestRayResultCallback()
  {}
  
  btScalar addSingleResult(btCollisionWorld::LocalRayResult &rayResult, bool normalInWorldSpace) override
  {
    btScalar result = ClosestRayResultCallback::addSingleResult(rayResult, normalInWorldSpace);
    
    if (rayResult.m_localShapeInfo) {
      m_shapePart = rayResult.m_localShapeInfo->m_shapePart;
      m_triangleIndex = rayResult.m_localShapeInfo->m_triangleIndex;
    }
    
    return result;
  }
};

@implementation BulletClosestHitRayResult
{
  RayCastClosestRayResultCallback *m_callback;
}

- (instancetype)initWithFrom:(vector_float3)fromPos
                          to:(vector_float3)toPos
           collisionFilterGroup:(int)collisionFilterGroup
            collisionFilterMask:(int)collisionFilterMask
{
  self = [super init];
  if (self) {
    m_callback = new RayCastClosestRayResultCallback(btVector3(fromPos.x, fromPos.y, fromPos.z),
                                                     btVector3(toPos.x, toPos.y, toPos.z));
    m_callback->m_collisionFilterGroup = collisionFilterGroup;
    m_callback->m_collisionFilterMask = collisionFilterMask;
  }
  return self;
}

- (void)dealloc
{
  delete m_callback;
}

- (btClosestRayResultCallbackC *)callback
{
  return bullet_cast(m_callback);
}

- (vector_float3)fromPos
{
  btVector3 v = m_callback->m_rayFromWorld;
  return vector3(v.x(), v.y(), v.z());
}

- (vector_float3)toPos
{
  btVector3 v = m_callback->m_rayToWorld;
  return vector3(v.x(), v.y(), v.z());
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

- (BulletRigidBody *)node
{
  const btCollisionObject *objectPtr = m_callback->m_collisionObject;
  return (objectPtr) ? (__bridge BulletRigidBody *)objectPtr->getUserPointer() : nil;
}

- (vector_float3)hitPos
{
  btVector3 v = m_callback->m_hitPointWorld;
  return vector3(v.x(), v.y(), v.z());
}

- (vector_float3)hitNormal
{
  btVector3 v = m_callback->m_hitNormalWorld;
  return vector3(v.x(), v.y(), v.z());
}

- (float)hitFraction
{
  return m_callback->m_closestHitFraction;
}

- (int)shapePart
{
  return m_callback->m_shapePart;
}

- (int)triangleIndex
{
  return m_callback->m_triangleIndex;
}

- (NSString *)description
{
  return [NSString stringWithFormat:@"{hasHit=%@, hitPos=(%f,%f,%f), hitNormal=(%f,%f,%f), hitFraction=%g, shapePart=%d, triangleIndex=%d, fromPos=(%f, %f, %f), toPos=(%f, %f, %f), collisionFilterGroup=%x, collisionFilterMask=%x}",
          self.hasHits ? @"YES" : @"NO",
          self.hitPos.x, self.hitPos.y, self.hitPos.z,
          self.hitNormal.x, self.hitNormal.y, self.hitNormal.z,
          self.hitFraction,
          self.shapePart,
          self.triangleIndex,
          self.fromPos.x, self.fromPos.y, self.fromPos.z,
          self.toPos.x, self.toPos.y, self.toPos.z,
          self.collisionFilterGroup,
          self.collisionFilterMask];
}

@end
