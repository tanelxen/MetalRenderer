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

#import "BulletCylinderShape.h"
#import "BulletUpAxis.h"
#import "BulletCollision/CollisionShapes/btCylinderShape.h"

@implementation BulletCylinderShape
{
  btCylinderShape *m_shape;
}

@synthesize up = _up;

- (instancetype)initWithHalfExtents:(vector_float3)halfExtents up:(BulletUpAxis)up
{
  self = [super init];
  if (self) {
    _up = up;
    btVector3 btHalfExtents(halfExtents.x, halfExtents.y, halfExtents.z);

    switch (up) {
      case BulletUpAxis_x:
        m_shape = new btCylinderShapeX(btHalfExtents);
        break;
      case BulletUpAxis_y:
        m_shape = new btCylinderShape(btHalfExtents);
        break;
      case BulletUpAxis_z:
        m_shape = new btCylinderShapeZ(btHalfExtents);
        break;
    }
    m_shape->setUserPointer((__bridge void *)self);
  }
  return self;
}

- (instancetype)initWithRadius:(float)radius height:(float)height up:(BulletUpAxis)up
{
  self = [super init];
  if (self) {
    _up = up;
    switch (up) {
      case BulletUpAxis_x:
        m_shape = new btCylinderShapeX(btVector3(0.5 * height, radius, radius));
        break;
      case BulletUpAxis_y:
        m_shape = new btCylinderShape(btVector3(radius, 0.5 * height, radius));
        break;
      case BulletUpAxis_z:
        m_shape = new btCylinderShapeZ(btVector3(radius, radius, 0.5 * height));
        break;
    }
    m_shape->setUserPointer((__bridge void *)self);
  }
  return self;
}

//- (instancetype)initFromB3Cylinder:(B3Cylinder *)cylinder
//{
//  self = [super init];
//  if (self) {
//    _up = cylinder.up;
//    switch (_up) {
//      case BulletUpAxis_X:
//        m_shape = new btCylinderShapeX(btVector3(0.5 * cylinder.height, cylinder.topRadius, cylinder.bottomRadius));
//        break;
//      case BulletUpAxis_Y:
//        m_shape = new btCylinderShape(btVector3(cylinder.topRadius, 0.5 * cylinder.height, cylinder.bottomRadius));
//        break;
//      case BulletUpAxis_Z:
//        m_shape = new btCylinderShapeZ(btVector3(cylinder.topRadius, cylinder.bottomRadius, 0.5 * cylinder.height));
//        break;
//    }
////    m_shape = new btCylinderShape(btVector3(cylinder.topRadius, 0.5 * cylinder.height, cylinder.bottomRadius));
//    m_shape->setUserPointer((__bridge void *)self);
//  }
//  return self;
//}

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

- (float)radius
{
  return m_shape->getRadius();
}

- (float)height
{
  switch (self.up) {
    case BulletUpAxis_x:
      return m_shape->getHalfExtentsWithoutMargin().x() * 2.0f;
      break;
    case BulletUpAxis_y:
      return m_shape->getHalfExtentsWithoutMargin().y() * 2.0f;
      break;
    case BulletUpAxis_z:
      return m_shape->getHalfExtentsWithoutMargin().z() * 2.0f;
      break;
  }
}

@end
