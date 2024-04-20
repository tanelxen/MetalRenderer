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

#import "BulletConeTwistConstraint.h"
#import "BulletRigidBody.h"
#import "BulletTransform.h"
#import "BulletUpAxis.h"
#import "BulletDynamics/ConstraintSolver/btConeTwistConstraint.h"

@implementation BulletConeTwistConstraint
{
  btConeTwistConstraint *m_constraint;
}

- (instancetype)initWithNodeA:(BulletRigidBody *)nodeA frameA:(BulletTransform *)frameA
{
  self = [super init];
  if (self) {
    btRigidBody *ptr_a = btRigidBody::upcast(bullet_cast(nodeA.ptr));
    const btTransform &trans_a = *bullet_cast(frameA.constRef);

    m_constraint = new btConeTwistConstraint(*ptr_a, trans_a);
  }
  return self;
}

- (instancetype)initWithNodeA:(BulletRigidBody *)nodeA nodeB:(BulletRigidBody *)nodeB frameA:(BulletTransform *)frameA frameB:(BulletTransform *)frameB
{
  self = [super init];
  if (self) {

    btRigidBody *ptr_a = btRigidBody::upcast(bullet_cast(nodeA.ptr));
    const btTransform &trans_a = *bullet_cast(frameA.constRef);

    btRigidBody *ptr_b = btRigidBody::upcast(bullet_cast(nodeB.ptr));
    const btTransform &trans_b = *bullet_cast(frameB.constRef);

    m_constraint = new btConeTwistConstraint(*ptr_a, *ptr_b, trans_a, trans_b);
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

- (void)setLimitWithIndex:(int)index value:(float)value
{
  m_constraint->setLimit(index, value);
}

- (void)setLimitWithSwing1:(float)swing1 swing2:(float)swing2 twist:(float)twist softness:(float)softness bias:(float)bias relaxation:(float)relaxation
{
  m_constraint->setLimit(swing1, swing2, twist, softness, bias, relaxation);
}

- (void)setLimitWithSwing1:(float)swing1 swing2:(float)swing2 twist:(float)twist softness:(float)softness bias:(float)bias
{
  [self setLimitWithSwing1:swing1 swing2:swing2 twist:twist softness:softness bias:bias relaxation:1.0f];
}

- (void)setLimitWithSwing1:(float)swing1 swing2:(float)swing2 twist:(float)twist softness:(float)softness
{
  [self setLimitWithSwing1:swing1 swing2:swing2 twist:twist softness:softness bias:0.3f relaxation:1.0f];
}

- (void)setLimitWithSwing1:(float)swing1 swing2:(float)swing2 twist:(float)twist
{
  [self setLimitWithSwing1:swing1 swing2:swing2 twist:twist softness:1.0f bias:0.3f relaxation:1.0f];
}

- (void)setDamping:(float)damping
{
  m_constraint->setDamping(damping);
}

- (void)setFixThreshold:(float)fixThreshold
{
  m_constraint->setFixThresh(fixThreshold);
}

- (float)fixThreshold
{
  return m_constraint->getFixThresh();
}

- (void)setEnableMotor:(BOOL)enableMotor
{
  m_constraint->enableMotor(enableMotor);
}

- (void)setMaxMotorImpulse:(float)maxImpulse
{
  m_constraint->setMaxMotorImpulse(maxImpulse);
}

- (void)setMaxMotorImpulseNormalized:(float)maxImpulse
{
  m_constraint->setMaxMotorImpulseNormalized(maxImpulse);
}

- (void)setMotorTarget:(vector_float4)quat
{
  m_constraint->setMotorTarget(btQuaternion(quat.x, quat.y, quat.z, quat.w));
}

- (void)setMotorTargetInConstraintSpace:(vector_float4)quat
{
  m_constraint->setMotorTargetInConstraintSpace(btQuaternion(quat.x, quat.y, quat.z, quat.w));
}

@end
