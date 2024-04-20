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

#import "BulletGhostObject.h"
#import "BulletCollisionShape.h"
#import "BulletCollision/CollisionDispatch/btGhostObject.h"

@implementation BulletGhostObject
{
  btPairCachingGhostObject *m_ghost;
}

- (instancetype)init
{
  NSAssert(NO, @"not supported");
  return nil;
}

- (instancetype)initWithShape:(BulletCollisionShape *)shape
{
  self = [super init];
  if (self) {
    btTransform trans = btTransform::getIdentity();

    m_ghost = new btPairCachingGhostObject();
    m_ghost->setUserPointer((__bridge void *)self);
    m_ghost->setCollisionFlags(btCollisionObject::CF_NO_CONTACT_RESPONSE);
    m_ghost->setWorldTransform(trans);
    m_ghost->setInterpolationWorldTransform(trans);
    m_ghost->setCollisionShape(bullet_cast(shape.ptr));
  }
  return self;
}

- (void)dealloc
{
  delete m_ghost;
}

- (btCollisionObjectC *)ptr
{
  return bullet_cast(static_cast<btCollisionObject *>(m_ghost));
}

- (NSUInteger)numberOfOverlappingNodes
{
  return m_ghost->getNumOverlappingObjects();
}

- (BulletCollisionObject *)overlappingNodeAt:(NSUInteger)index
{
  NSAssert(index >= 0 && index < m_ghost->getNumOverlappingObjects(), @"");
  btCollisionObject *object = m_ghost->getOverlappingObject(static_cast<int>(index));
  return object ? (__bridge BulletCollisionObject *)object->getUserPointer() : nil;
}

- (vector_float3) worldPosition
{
    btTransform transform = m_ghost->getWorldTransform();
    btVector3 origin = transform.getOrigin();
    
    return vector3(origin.x(), origin.y(), origin.z());
}

@end
