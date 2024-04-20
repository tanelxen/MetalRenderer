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

#import "BulletBoxShape.h"
#import "BulletUpAxis.h"
#import "BulletCollision/CollisionShapes/btBoxShape.h"

@implementation BulletBoxShape
{
  btBoxShape *m_shape;
}

- (instancetype)initWithHalfExtents:(vector_float3)halfExtents {
  NSAssert(halfExtents.x != 0.0f && halfExtents.y != 0.0 && halfExtents.z != 0.0, @"all values of box size must not be zero");
  self = [super init];
  if (self) {
    btVector3 btHalfExtents(halfExtents.x, halfExtents.y, halfExtents.z);
    m_shape = new btBoxShape(btHalfExtents);
    m_shape->setUserPointer((__bridge void *)self);
  }
  return self;
}

- (void)dealloc
{
  delete m_shape;
}

- (btCollisionShapeC *)ptr
{
  return bullet_cast(static_cast<btCollisionShape *>(m_shape));
}

- (vector_float3)halfExtentsWithMargin
{
  btVector3 halfExtents = m_shape->getHalfExtentsWithMargin();
  return vector3(halfExtents.x(), halfExtents.y(), halfExtents.z());
}

- (vector_float3)halfExtentsWithoutMargin
{
  btVector3 halfExtents = m_shape->getHalfExtentsWithoutMargin();
  return vector3(halfExtents.x(), halfExtents.y(), halfExtents.z());
}

@end
