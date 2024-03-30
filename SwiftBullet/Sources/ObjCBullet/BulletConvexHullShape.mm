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

#import "BulletConvexHullShape.h"
#import "BulletUpAxis.h"
#import "BulletCollision/CollisionShapes/btConvexHullShape.h"
#import "BulletCollision/CollisionShapes/btTriangleMesh.h"
#import "BulletCollision/CollisionShapes/btConvexShape.h"
#import "BulletCollision/CollisionShapes/btShapeHull.h"
#import "BulletCollision/CollisionShapes/btConvexTriangleMeshShape.h"

@implementation BulletConvexHullShape
{
  btConvexHullShape *m_shape;
}

- (instancetype)init
{
  self = [super init];
  if (self) {
    m_shape = new btConvexHullShape(nullptr, 0);
    m_shape->setUserPointer((__bridge void *)self);
  }
  return self;
}

- (instancetype)initWithPoints:(float *)points
                numberOfPoints:(NSInteger)numberOfPoints
            numberOfComponents:(NSInteger)numberOfComponents {
  self = [self init];
  if (self) {
    NSAssert(numberOfComponents >= 3, @"number of components must be more than or equal to 3");
    for (NSInteger i = 0; i < numberOfPoints; ++i) {
      btVector3 v(points[i * numberOfComponents + 0],
                  points[i * numberOfComponents + 1],
                  points[i * numberOfComponents + 2]);
      m_shape->addPoint(v);
    }
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

- (void)addPoint:(vector_float3)point
{
  m_shape->addPoint(btVector3(point.x, point.y, point.z));
}

@end
