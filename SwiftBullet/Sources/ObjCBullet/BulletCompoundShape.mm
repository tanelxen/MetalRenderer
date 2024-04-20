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

#import "BulletCompoundShape.h"
#import "BulletTransform.h"
#import "BulletCollisionShape.h"
#import "BulletUpAxis.h"
#import "BulletCollision/CollisionShapes/btCompoundShape.h"

@implementation BulletCompoundShape
{
  btCompoundShape *m_shape;
  NSMutableArray<BulletCollisionShape *> *m_childShapes;
  NSMutableArray<BulletTransform *> *m_childTransforms;
}

- (instancetype)init
{
  return [self initWithEnableDynamicAabbTree:YES];
}

- (instancetype)initWithEnableDynamicAabbTree:(BOOL)enableDynamicAabbTree
{
  self = [super init];
  if (self) {
    m_shape = new btCompoundShape(enableDynamicAabbTree);
    m_childShapes = [NSMutableArray array];
    m_childTransforms = [NSMutableArray array];
  }
  return self;
}

- (void)dealloc
{
  [self removeAllChildShapes];
  delete m_shape;
}

- (void)addChildShape:(BulletCollisionShape *)shape withLocalTransform:(BulletTransform *)localTransform
{
  [m_childShapes addObject:shape];
  [m_childTransforms addObject:localTransform];
  m_shape->addChildShape(*bullet_cast(localTransform.constRef), bullet_cast(shape.ptr));
}

- (void)removeChildShape:(BulletCollisionShape *)shape
{
  NSUInteger index = [m_childShapes indexOfObject:shape];
  if(index == NSNotFound) {
    return;
  }
  [self removeChildShapeAtIndex:index];
}

- (void)removeChildShapeAtIndex:(NSUInteger)childShapeIndex
{
  [m_childShapes removeObjectAtIndex:childShapeIndex];
  [m_childTransforms removeObjectAtIndex:childShapeIndex];
  m_shape->removeChildShapeByIndex(static_cast<int>(childShapeIndex));
}

- (void)removeAllChildShapes
{
  int n = static_cast<int>([self numberOfChildShapes]);
  for(int i = n - 1; i >= 0; --i) {
    [self removeChildShapeAtIndex:i];
  }
}

- (NSUInteger)numberOfChildShapes
{
  return m_shape->getNumChildShapes();
}

- (BulletCollisionShape *)childShapeAtIndex:(int)childShapeIndex
{
  return m_childShapes[childShapeIndex];
}

- (BulletTransform *)childTransformAtIndex:(int)childShapeIndex
{
  return m_childTransforms[childShapeIndex];
}

- (void)updateChildTransform:(BulletTransform *)childTransform atIndex:(int)childShapeIndex
{
  m_shape->updateChildTransform(childShapeIndex, *bullet_cast(childTransform.constRef));
}

- (NSArray<BulletCollisionShape *> *)childShapes
{
  return [m_childShapes copy];
}

- (BulletAABB)aabbWithTransform:(BulletTransform *)transform
{
  btVector3 aabbMin;
  btVector3 aabbMax;
  m_shape->getAabb(*bullet_cast(transform.constRef), aabbMin, aabbMax);
  BulletAABB aabox;
  aabox.min = vector3(aabbMin.x(), aabbMin.y(), aabbMin.z());
  aabox.max = vector3(aabbMax.x(), aabbMax.y(), aabbMax.z());
  return aabox;
}

- (void)recalculateLocalAabb
{
  m_shape->recalculateLocalAabb();
}

- (void)setLocalScaling:(vector_float3)scaling
{
  m_shape->setLocalScaling(btVector3(scaling.x, scaling.y, scaling.z));
}

- (vector_float3)localScaling
{
  btVector3 scaling = m_shape->getLocalScaling();
  return vector3(scaling.x(), scaling.y(), scaling.z());
}

- (void)setMargin:(float)margin
{
  m_shape->setMargin(margin);
}

- (float)margin
{
  return m_shape->getMargin();
}

- (btCollisionShapeC *)ptr
{
  return bullet_cast(static_cast<btCollisionShape *>(m_shape));
}

@end
