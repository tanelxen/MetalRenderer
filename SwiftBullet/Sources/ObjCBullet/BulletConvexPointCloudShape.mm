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

#import "BulletConvexPointCloudShape.h"
#import "BulletUpAxis.h"
#import "BulletCollision/CollisionShapes/btConvexPointCloudShape.h"

@implementation BulletConvexPointCloudShape
{
  btConvexPointCloudShape *m_shape;
  btVector3 *m_btPoints;
}

- (instancetype)initWithPoints:(float *)points
                numberOfPoints:(NSInteger)numberOfPoints
            numberOfComponents:(NSInteger)numberOfComponents
                         scale:(vector_float3)scale {
  self = [super init];
  if (self) {
    btVector3 btScale(scale.x, scale.y, scale.z);
    m_btPoints = new btVector3[numberOfPoints];
    for (int i = 0; i < numberOfPoints; ++i) {
      btVector3 v(points[i * numberOfComponents + 0],
                  points[i * numberOfComponents + 1],
                  points[i * numberOfComponents + 2]);
      m_btPoints[i] = v;
    }
    m_shape = new btConvexPointCloudShape(m_btPoints, static_cast<int>(numberOfPoints), btScale);
    m_shape->setUserPointer((__bridge void *)self);
  }
  return self;
}

- (void)dealloc
{
  delete m_shape;
  delete m_btPoints;
}

- (btCollisionShapeC *)ptr
{
  return bullet_cast(static_cast<btCollisionShape *>(m_shape));
}

- (NSUInteger)numberOfPoints
{
  return m_shape->getNumPoints();
}

@end
