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

#import "BulletPersistentManifold.h"
#import "BulletManifoldPoint.h"
#import "BulletCollision/NarrowPhaseCollision/btPersistentManifold.h"
#import "BulletCollision/CollisionDispatch/btCollisionObject.h"

@implementation BulletPersistentManifold
{
  btPersistentManifold *m_pm;
}

- (instancetype)initWithPersistentManifold:(btPersistentManifoldC *)pm
{
  self = [super init];
  if (self) {
    m_pm = bullet_cast(pm);
  }
  return self;
}

- (BulletCollisionObject *)body0
{
  return (__bridge BulletCollisionObject *)m_pm->getBody0()->getUserPointer();
}

- (BulletCollisionObject *)body1
{
  return (__bridge BulletCollisionObject *)m_pm->getBody1()->getUserPointer();
}

- (float)contactBreakingThreshold
{
  return m_pm->getContactBreakingThreshold();
}

- (float)contactProcessingThreshold
{
  return m_pm->getContactProcessingThreshold();
}

- (NSUInteger)numberOfContacts
{
  return m_pm->getNumContacts();
}

- (NSUInteger)count
{
  return m_pm->getNumContacts();
}

- (BulletManifoldPoint *)contactPointAtIndex:(NSUInteger)index
{
  return [[BulletManifoldPoint alloc] initWithManifoldPoint:bullet_cast(&m_pm->getContactPoint(static_cast<int>(index)))];
}

@end