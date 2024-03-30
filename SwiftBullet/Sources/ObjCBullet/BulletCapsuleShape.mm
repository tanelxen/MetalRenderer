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

#import "BulletCapsuleShape.h"
#import "BulletCollision/CollisionShapes/btCapsuleShape.h"

@implementation BulletCapsuleShape
{
  btCapsuleShape *m_shape;
}

- (instancetype)initWithRadius:(float)radius height:(float)height up:(BulletUpAxis)up
{
  self = [super init];
  if (self) {
    switch (up) {
      case BulletUpAxis_x:
        m_shape = new btCapsuleShapeX(radius, height);
        break;
      case BulletUpAxis_y:
        m_shape = new btCapsuleShape(radius, height);
        break;
      case BulletUpAxis_z:
        m_shape = new btCapsuleShapeZ(radius, height);
        break;
    }
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

- (float)halfHeight
{
  return m_shape->getHalfHeight();
}

- (float)radius
{
  return m_shape->getRadius();
}

@end
