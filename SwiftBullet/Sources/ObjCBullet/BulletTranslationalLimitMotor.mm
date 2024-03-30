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

#import "BulletTranslationalLimitMotor.h"
#import "BulletDynamics/ConstraintSolver/btGeneric6DofConstraint.h"

@implementation BulletTranslationalLimitMotor
{
  btTranslationalLimitMotor *m_motor;
}

- (instancetype)initWithMotor:(btTranslationalLimitMotorC *)motor
{
  self = [super init];
  if (self) {
    m_motor = bullet_cast(motor);
  }
  return self;
}

- (void)setLowerLimit:(vector_float3)lowerLimit
{
  m_motor->m_lowerLimit = btVector3(lowerLimit.x, lowerLimit.y, lowerLimit.z);
}

- (vector_float3)lowerLimit
{
  return vector3(m_motor->m_lowerLimit.x(), m_motor->m_lowerLimit.x(), m_motor->m_lowerLimit.x());
}

- (void)setUpperLimit:(vector_float3)upperLimit
{
  m_motor->m_upperLimit = btVector3(upperLimit.x, upperLimit.y, upperLimit.z);
}

- (vector_float3)upperLimit
{
  return vector3(m_motor->m_upperLimit.x(), m_motor->m_upperLimit.x(), m_motor->m_upperLimit.x());
}

- (void)setLimitSoftness:(float)limitSoftness
{
  m_motor->m_limitSoftness = limitSoftness;
}

- (float)limitSoftness
{
  return m_motor->m_limitSoftness;
}

- (void)setDamping:(float)damping
{
  m_motor->m_damping = damping;
}

- (float)damping
{
  return m_motor->m_damping;
}

- (void)setRestitution:(float)restitution
{
  m_motor->m_restitution = restitution;
}

- (float)restitution
{
  return m_motor->m_restitution;
}

- (void)setEnableMotor:(BOOL)enable atIndex:(NSInteger)index
{
  m_motor->m_enableMotor[index] = enable;
}

- (BOOL)enableMotorAtIndex:(NSInteger)index
{
  return m_motor->m_enableMotor[index];
}

- (void)setTargetVelocity:(vector_float3)targetVelocity
{
  m_motor->m_targetVelocity = btVector3(targetVelocity.x, targetVelocity.y, targetVelocity.z);
}

- (void)setTargetVelocity:(float)value atIndex:(NSInteger)index
{
  m_motor->m_targetVelocity[index] = value;
}

- (vector_float3)targetVelocity
{
  return vector3(m_motor->m_targetVelocity.x(), m_motor->m_targetVelocity.y(), m_motor->m_targetVelocity.z());
}

- (void)setMaxMotorForce:(vector_float3)maxMotorForce
{
  m_motor->m_maxMotorForce = btVector3(maxMotorForce.x, maxMotorForce.y, maxMotorForce.z);
}

- (void)setMaxMotorForce:(float)value atIndex:(NSInteger)index
{
  m_motor->m_maxMotorForce[index] = value;
}

- (vector_float3)maxMotorForce
{
  return vector3(m_motor->m_maxMotorForce.x(), m_motor->m_maxMotorForce.y(), m_motor->m_maxMotorForce.z());
}

- (BOOL)isLimitedAtIndex:(NSInteger)limitIndex
{
  return m_motor->isLimited(static_cast<int>(limitIndex));
}

@end
