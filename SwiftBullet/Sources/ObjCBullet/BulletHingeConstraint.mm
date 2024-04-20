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

#import "BulletHingeConstraint.h"
#import "BulletRigidBody.h"
#import "BulletUpAxis.h"
#import "BulletTransform.h"
#import "BulletDynamics/ConstraintSolver/btHingeConstraint.h"

@implementation BulletHingeConstraint
{
  btHingeConstraint *m_constraint;
}

- (instancetype)initWithNodeA:(BulletRigidBody *)nodeA
              nodeB:(BulletRigidBody *)nodeB
             frameA:(BulletTransform *)frameA
             frameB:(BulletTransform *)frameB
 useReferenceFrameA:(BOOL)useReferenceFrameA
{
  self = [super init];
  if (self) {
    btRigidBody *ptr_a = btRigidBody::upcast(bullet_cast(nodeA.ptr));
    btRigidBody *ptr_b = btRigidBody::upcast(bullet_cast(nodeB.ptr));
    const btTransform &_frameA = *bullet_cast(frameA.constRef);
    const btTransform &_frameB = *bullet_cast(frameB.constRef);
    m_constraint = new btHingeConstraint(*ptr_a, *ptr_b, _frameA, _frameB, useReferenceFrameA);
  }
  return self;
}

- (instancetype)initWithNodeA:(BulletRigidBody *)nodeA
                        nodeB:(BulletRigidBody *)nodeB
                       pivotA:(vector_float3)pivotA
                       pivotB:(vector_float3)pivotB
                        axisA:(vector_float3)axisA
                        axisB:(vector_float3)axisB
           useReferenceFrameA:(BOOL)useReferenceFrameA
{
  self = [super init];
  if (self) {
    btRigidBody *ptr_a = btRigidBody::upcast(bullet_cast(nodeA.ptr));
    btVector3 pos_a(pivotA.x, pivotA.y, pivotA.z);
    btVector3 vec_a(axisA.x, axisA.y, axisA.z);

    btRigidBody *ptr_b = btRigidBody::upcast(bullet_cast(nodeB.ptr));
    btVector3 pos_b(pivotB.x, pivotB.y, pivotB.z);
    btVector3 vec_b(axisB.x, axisB.y, axisB.z);

    m_constraint = new btHingeConstraint(*ptr_a, *ptr_b, pos_a, pos_b, vec_a, vec_b, useReferenceFrameA);
  }
  return self;
}

- (instancetype)initWithNodeA:(BulletRigidBody *)nodeA
                        nodeB:(BulletRigidBody *)nodeB
                       pivotA:(vector_float3)pivotA
                       pivotB:(vector_float3)pivotB
                        axisA:(vector_float3)axisA
                        axisB:(vector_float3)axisB
{
  return [self initWithNodeA:nodeA nodeB:nodeB pivotA:pivotA pivotB:pivotB axisA:axisA axisB:axisB useReferenceFrameA:NO];
}

- (instancetype)initWithNodeA:(BulletRigidBody *)nodeA
                       pivotA:(vector_float3)pivotA
                        axisA:(vector_float3)axisA
           useReferenceFrameA:(BOOL)useReferenceFrameA
{
  self = [super init];
  if (self) {
    btRigidBody *ptr_a = btRigidBody::upcast(bullet_cast(nodeA.ptr));
    btVector3 pos_a(pivotA.x, pivotA.y, pivotA.z);
    btVector3 vec_a(axisA.x, axisA.y, axisA.z);

    m_constraint = new btHingeConstraint(*ptr_a, pos_a, vec_a, useReferenceFrameA);
  }
  return self;
}

- (instancetype)initWithNodeA:(BulletRigidBody *)nodeA
                       pivotA:(vector_float3)pivotA
                        axisA:(vector_float3)axisA
{
  return [self initWithNodeA:nodeA pivotA:pivotA axisA:axisA useReferenceFrameA:NO];
}

- (void)dealloc
{
  delete m_constraint;
}

- (btTypedConstraintC *)ptr
{
  return bullet_cast(static_cast<btTypedConstraint *>(m_constraint));
}

- (void)setAngularOnly:(BOOL)angularOnly
{
  m_constraint->setAngularOnly(angularOnly);
}

- (BOOL)angularOnly
{
  return m_constraint->getAngularOnly();
}

- (void)setLowLimit:(float)low highLimit:(float)high softness:(float)softness bias:(float)bias relaxation:(float)relaxation
{
  m_constraint->setLimit(low, high, softness, bias, relaxation);
}

- (void)setLowLimit:(float)low highLimit:(float)high softness:(float)softness bias:(float)bias
{
  [self setLowLimit:low highLimit:high softness:softness bias:bias relaxation:1.0f];
}

- (void)setLowLimit:(float)low highLimit:(float)high softness:(float)softness
{
  [self setLowLimit:low highLimit:high softness:softness bias:0.3f relaxation:1.0f];
}

- (void)setLowLimit:(float)low highLimit:(float)high
{
  m_constraint->setLimit(low, high);
}

- (void)setAxis:(vector_float3)axis
{
  btVector3 v(axis.x, axis.y, axis.z);
  m_constraint->setAxis(v);
}

- (float)lowerLimit
{
  return m_constraint->getLowerLimit();
}

- (float)upperLimit
{
  return m_constraint->getUpperLimit();
}

- (float)hingeAngle
{
  return m_constraint->getHingeAngle();
}

- (void)enableAngularMotor:(BOOL)enable withTargetVelocity:(float)targetVelocity maxImpulse:(float)maxImpulse
{
  m_constraint->enableAngularMotor(enable, targetVelocity, maxImpulse);
}

- (void)enableMotor:(BOOL)enable
{
  m_constraint->enableMotor(enable);
}

- (void)setMaxMotorImpulse:(float)maxImpulse
{
  m_constraint->setMaxMotorImpulse(maxImpulse);
}

- (void)setMotorTarget:(vector_float4)quat deltaTime:(float)dt
{
  m_constraint->setMotorTarget(btQuaternion(quat.x, quat.y, quat.z, quat.w), dt);
}

- (void)setMotorTargetAngle:(float)targetAngle deltaTime:(float)dt
{
  m_constraint->setMotorTarget(targetAngle, dt);
}

@end
