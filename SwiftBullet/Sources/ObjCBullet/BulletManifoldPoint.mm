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

#import "BulletManifoldPoint.h"
#import "BulletUpAxis.h"
#import "BulletCollision/NarrowPhaseCollision/btManifoldPoint.h"

@implementation BulletManifoldPoint
{
  btManifoldPoint *m_pt;
}

- (instancetype)initWithManifoldPoint:(btManifoldPointC *)pt
{
  self = [super init];
  if (self) {
    m_pt = bullet_cast(pt);
  }
  return self;
}
- (int)lifeTime
{
  return m_pt->getLifeTime();
}

- (float)distance
{
  return m_pt->getDistance();
}

- (float)appliedImpulse
{
  return m_pt->getAppliedImpulse();
}

- (vector_float3)positionWorldOnA
{
  btVector3 pos = m_pt->getPositionWorldOnA();
  return vector3(pos.x(), pos.y(), pos.z());
}

- (vector_float3)positionWorldOnB
{
  btVector3 pos = m_pt->getPositionWorldOnB();
  return vector3(pos.x(), pos.y(), pos.z());
}

- (vector_float3)normalWorldOnB
{
  btVector3 point = m_pt->m_normalWorldOnB;
  return vector3(point.x(), point.y(), point.z());
}

- (int)index0
{
  return m_pt->m_index0;
}

- (int)index1
{
  return m_pt->m_index1;
}

- (vector_float3)localPointA
{
  btVector3 point = m_pt->m_localPointA;
  return vector3(point.x(), point.y(), point.z());
}

- (vector_float3)localPointB
{
  btVector3 point = m_pt->m_localPointB;
  return vector3(point.x(), point.y(), point.z());
}

- (int)partId0
{
  return m_pt->m_partId0;
}

- (int)partId1
{
  return m_pt->m_partId1;
}

@end
