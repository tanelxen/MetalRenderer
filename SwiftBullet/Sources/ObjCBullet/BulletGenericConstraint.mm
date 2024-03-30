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

#import "BulletGenericConstraint.h"
#import "BulletRigidBody.h"
#import "BulletTransform.h"
#import "BulletUpAxis.h"
#import "BulletTranslationalLimitMotor.h"
#import "BulletRotationalLimitMotor.h"
#import "BulletDynamics/ConstraintSolver/btGeneric6DofConstraint.h"

@interface BulletGenericConstraint ()
@property (nonatomic, strong) BulletTranslationalLimitMotor *translationalLimitMotor;
@property (nonatomic, strong) NSArray<BulletRotationalLimitMotor *> *rotationalLimitMotors;
@end

@implementation BulletGenericConstraint
{
  btGeneric6DofConstraint *m_constraint;
}

- (void)initMotors
{
  _translationalLimitMotor = [[BulletTranslationalLimitMotor alloc] initWithMotor:bullet_cast(m_constraint->getTranslationalLimitMotor())];
  BulletRotationalLimitMotor *rm0 = [[BulletRotationalLimitMotor alloc] initWithMotor:bullet_cast(m_constraint->getRotationalLimitMotor(0))];
  BulletRotationalLimitMotor *rm1 = [[BulletRotationalLimitMotor alloc] initWithMotor:bullet_cast(m_constraint->getRotationalLimitMotor(1))];
  BulletRotationalLimitMotor *rm2 = [[BulletRotationalLimitMotor alloc] initWithMotor:bullet_cast(m_constraint->getRotationalLimitMotor(2))];
  _rotationalLimitMotors = @[rm0, rm1, rm2];
}

- (instancetype)initWithNodeA:(BulletRigidBody *)nodeA
                       frameA:(BulletTransform *)frameA
           useReferenceFrameA:(BOOL)useReferenceFrameA
{
  self = [super init];
  if (self) {
    btRigidBody *ptr_a = btRigidBody::upcast(bullet_cast(nodeA.ptr));
    const btTransform &trans_a = *bullet_cast(frameA.constRef);

    m_constraint = new btGeneric6DofConstraint(*ptr_a, trans_a, useReferenceFrameA);
    [self initMotors];
  }
  return self;
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
    const btTransform &trans_a = *bullet_cast(frameA.constRef);

    btRigidBody *ptr_b = btRigidBody::upcast(bullet_cast(nodeB.ptr));
    const btTransform &trans_b = *bullet_cast(frameB.constRef);

    m_constraint = new btGeneric6DofConstraint(*ptr_a, *ptr_b, trans_a, trans_b, useReferenceFrameA);
    [self initMotors];
  }
  return self;
}

- (void)dealloc
{
  delete m_constraint;
}

- (btTypedConstraintC *)ptr
{
  return bullet_cast(static_cast<btTypedConstraint *>(m_constraint));
}

- (vector_float3)axisOfAxisIndex:(int)axis
{
  NSAssert(axis >= 0 && axis <= 3, @"illegal axis");

  m_constraint->buildJacobian();
  btVector3 axisVector = m_constraint->getAxis(axis);
  return vector3(axisVector.x(), axisVector.y(), axisVector.z());
}

- (float)pivotOfAxisIndex:(int)axis
{
  NSAssert(axis >= 0 && axis <= 3, @"illegal axis");

  m_constraint->buildJacobian();
  return m_constraint->getRelativePivotPosition(axis);
}

- (float)angleOfAxisIndex:(int)axis
{
  NSAssert(axis >= 0 && axis <= 3, @"illegal axis");

  m_constraint->buildJacobian();
  return m_constraint->getAngle(axis);
}

- (void)setLowLimit:(float)low highLimit:(float)high forAxisIndex:(int)axis
{
  m_constraint->buildJacobian();
  m_constraint->setLimit(axis, low, high);
}

- (void)setAngularLowLimit:(float)low highLimit:(float)high forAxisIndex:(int)axis
{
  NSAssert(axis >= 0 && axis <= 3, @"illegal axis");

  m_constraint->buildJacobian();
  m_constraint->setLimit(axis + 3, low, high);
}

- (void)setLinearLowLimit:(float)low highLimit:(float)high forAxisIndex:(int)axis
{
  NSAssert(axis >= 0 && axis <= 3, @"illegal axis");

  m_constraint->buildJacobian();
  m_constraint->setLimit(axis, low, high);
}

- (void)setLinearLowerLimit:(vector_float3)linearLowerLimit
{
  m_constraint->setLinearLowerLimit(btVector3(linearLowerLimit.x, linearLowerLimit.y, linearLowerLimit.z));
}

- (vector_float3)linearLowerLimit
{
  btVector3 linearLower;
  m_constraint->getLinearLowerLimit(linearLower);
  return vector3(linearLower.x(), linearLower.y(), linearLower.z());
}

- (void)setLinearUpperLimit:(vector_float3)linearUpperLimit
{
  m_constraint->setLinearUpperLimit(btVector3(linearUpperLimit.x, linearUpperLimit.y, linearUpperLimit.z));
}

- (vector_float3)linearUpperLimit
{
  btVector3 linearUpper;
  m_constraint->getLinearUpperLimit(linearUpper);
  return vector3(linearUpper.x(), linearUpper.y(), linearUpper.z());
}

- (void)setFrameOffsetA:(BulletTransform *)frameOffsetA
{
  m_constraint->getFrameOffsetA() = *bullet_cast(frameOffsetA.constRef);
}

- (BulletTransform *)frameOffsetA
{
  return [[BulletTransform alloc] initWithbtTransform:bullet_cast(&m_constraint->getFrameOffsetA())];
}

- (void)setFrameOffsetB:(BulletTransform *)frameOffsetB
{
  m_constraint->getFrameOffsetB() = *bullet_cast(frameOffsetB.constRef);
}

- (BulletTransform *)frameOffsetB
{
  return [[BulletTransform alloc] initWithbtTransform:bullet_cast(&m_constraint->getFrameOffsetB())];
}

- (BulletTranslationalLimitMotor *)translationalLimitMotor
{
  return _translationalLimitMotor;
}

- (BulletRotationalLimitMotor *)rotationLimitMotorAtIndex:(NSInteger)index
{
  return _rotationalLimitMotors[index];
}

@end
