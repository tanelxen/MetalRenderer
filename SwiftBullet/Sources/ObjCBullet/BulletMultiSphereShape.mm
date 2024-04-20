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

#import "BulletMultiSphereShape.h"
#import "BulletUpAxis.h"
#import "BulletCollision/CollisionShapes/btMultiSphereShape.h"
#import <vector>

@implementation BulletMultiSphereShape
{
  btMultiSphereShape *m_shape;
}

- (instancetype)initWithPositions:(float *)positions
                            radii:(float *)radii
                  numberOfSpheres:(NSInteger)numberOfSpheres
{
  self = [super init];
  if (self) {
    // Convert points
    std::vector<btVector3> bt_points(numberOfSpheres);
    for (int i = 0; i < numberOfSpheres; ++i) {
      bt_points[i] = btVector3(positions[i * 3 + 0],
                               positions[i * 3 + 1],
                               positions[i * 3 + 2]);
    }

    // Convert radii
    std::vector<btScalar> bt_radii(numberOfSpheres);
    for (int j = 0; j < numberOfSpheres; j++) {
      bt_radii[j] = radii[j];
    }

    // Create shape
    m_shape = new btMultiSphereShape(bt_points.data(), bt_radii.data(), (int)numberOfSpheres);
    m_shape->setUserPointer((__bridge void *)self);
  }
  return self;
}

- (NSUInteger)sphereCount
{
  return m_shape->getSphereCount();
}

- (vector_float3)spherePosAt:(NSUInteger)index
{
  btVector3 pos = m_shape->getSpherePosition(static_cast<int>(index));
  return vector3(pos.x(), pos.y(), pos.z());
}

- (float)sphereRadiusAt:(NSUInteger)index
{
  return m_shape->getSphereRadius(static_cast<int>(index));
}

- (btCollisionShapeC *)ptr
{
  return bullet_cast(static_cast<btCollisionShape *>(m_shape));
}

@end
