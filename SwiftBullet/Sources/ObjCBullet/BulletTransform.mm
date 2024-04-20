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

#import "BulletTransform.h"
#import "BulletUpAxis.h"
#import "LinearMath/btTransform.h"

@implementation BulletTransform
{
  btTransform *m_transform;
}

- (instancetype)init
{
  self = [super init];
  if (self) {
    m_transform = new btTransform(btMatrix3x3::getIdentity());
    m_transform->setIdentity();
  }
  return self;
}

- (instancetype)initWithQuaternion:(vector_float4)q translation:(vector_float3)c
{
  self = [super init];
  if (self) {
    m_transform = new btTransform(btQuaternion(q.x, q.y, q.z, q.w), btVector3(c.x, c.y, c.z));
  }
  return self;
}

- (instancetype)initWithRotation:(matrix_float3x3)b translation:(vector_float3)c
{
  self = [super init];
  if (self) {
    btMatrix3x3 r(b.columns[0].x, b.columns[0].y, b.columns[0].z,
                  b.columns[1].x, b.columns[1].y, b.columns[1].z,
                  b.columns[2].x, b.columns[2].y, b.columns[2].z);
    btVector3 t(c.x, c.y, c.z);
    m_transform = new btTransform(r, t);
  }
  return self;
}

- (void)dealloc
{
  if(m_transform != nullptr) {
    delete m_transform;
  }
}

- (void)setBasis:(matrix_float3x3)basis
{
  btMatrix3x3 m(basis.columns[0].x, basis.columns[0].y, basis.columns[0].z,
                basis.columns[1].x, basis.columns[1].y, basis.columns[1].z,
                basis.columns[2].x, basis.columns[2].y, basis.columns[2].z);
  m_transform->setBasis(m);
}

- (matrix_float3x3)basis
{
  matrix_float3x3 m;
  m.columns[0] = vector3(m_transform->getBasis()[0].x(), m_transform->getBasis()[0].y(), m_transform->getBasis()[0].z());
  m.columns[1] = vector3(m_transform->getBasis()[1].x(), m_transform->getBasis()[1].y(), m_transform->getBasis()[1].z());
  m.columns[2] = vector3(m_transform->getBasis()[2].x(), m_transform->getBasis()[2].y(), m_transform->getBasis()[2].z());
  return m;
}

- (void)setOrigin:(vector_float3)origin
{
  m_transform->setOrigin(btVector3(origin.x, origin.y, origin.z));
}

- (vector_float3)origin
{
  return vector3(m_transform->getOrigin().x(), m_transform->getOrigin().y(), m_transform->getOrigin().z());
}

- (void)setRotation:(vector_float4)rotation
{
    m_transform->setRotation(btQuaternion(rotation[0], rotation[1], rotation[2], rotation[3]));
}

- (vector_float4)rotation
{
    btQuaternion q = m_transform->getRotation();
    return vector4(q.x(), q.y(), q.z(), q.w());
}

- (void)setIdentity
{
  m_transform->setIdentity();
}

- (BulletTransform *)inverse
{
  btTransform t = m_transform->inverse();
  BulletTransform *transform = [[BulletTransform alloc] initWithbtTransform:bullet_cast(&t)];
  return transform;
}

- (vector_float3)multiply:(vector_float3)vec
{
  btVector3 v = (*m_transform) * btVector3(vec.x, vec.y, vec.z);
  return vector3(v.x(), v.y(), v.z());
}

- (instancetype)initWithbtTransform:(const btTransformC *)transform
{
  self = [super init];
  if (self) {
    m_transform = new btTransform(*bullet_cast(transform));
  }
  return self;
}

- (btTransformC *)ref
{
  return bullet_cast(m_transform);
}

- (const btTransformC *)constRef
{
  return bullet_cast(m_transform);
}

- (void)setBasisFromEulerAngles:(vector_float3)eulerAngles
{
  m_transform->getBasis().setEulerZYX(eulerAngles.x, eulerAngles.y, eulerAngles.z);
}

- (vector_float3)basisAsEulerAngles
{
  btScalar eulerX, eulerY, eulerZ;
  m_transform->getBasis().getEulerZYX(eulerX, eulerY, eulerZ);
  return vector3(eulerX, eulerY, eulerZ);
}

#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone
{
  BulletTransform *copy = [[BulletTransform alloc] initWithRotation:self.basis translation:self.origin];
  return copy;
}

- (NSString *)description
{
  return [NSString stringWithFormat:@"{origin=(%f, %f, %f),basis=(%f, %f, %f)}",
          self.origin.x, self.origin.y, self.origin.z,
          self.basisAsEulerAngles.x, self.basisAsEulerAngles.y, self.basisAsEulerAngles.z];
}

@end
