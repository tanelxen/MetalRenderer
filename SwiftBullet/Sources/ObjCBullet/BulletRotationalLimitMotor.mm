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

#import "BulletRotationalLimitMotor.h"
#import "BulletDynamics/ConstraintSolver/btGeneric6DofConstraint.h"

@implementation BulletRotationalLimitMotor
{
  btRotationalLimitMotor *m_motor;
}

- (instancetype)initWithMotor:(btRotationalLimitMotorC *)motor
{
  self = [super init];
  if (self) {
    m_motor = bullet_cast(motor);
  }
  return self;
}

- (void)setLowerLimit:(float)lowerLimit
{
  m_motor->m_loLimit = lowerLimit;
}

- (float)lowerLimit
{
  return m_motor->m_loLimit;
}

- (void)setUpperLimit:(float)upperLimit
{
  m_motor->m_hiLimit = upperLimit;
}

- (float)upperLimit
{
  return m_motor->m_hiLimit;
}

- (void)setTargetVelocity:(float)targetVelocity
{
  m_motor->m_targetVelocity = targetVelocity;
}

- (float)targetVelocity
{
  return m_motor->m_targetVelocity;
}

- (void)setMaxMotorForce:(float)maxMotorForce
{
  m_motor->m_maxMotorForce = maxMotorForce;
}

- (float)maxMotorForce
{
  return m_motor->m_maxMotorForce;
}

- (void)setMaxLimitForce:(float)maxLimitForce
{
  m_motor->m_maxLimitForce = maxLimitForce;
}

- (float)maxLimitForce
{
  return m_motor->m_maxLimitForce;
}

- (void)setDamping:(float)damping
{
  m_motor->m_damping = damping;
}

- (float)damping
{
  return m_motor->m_damping;
}

- (void)setLimitSoftness:(float)limitSoftness
{
  m_motor->m_limitSoftness = limitSoftness;
}

- (float)limitSoftness
{
  return m_motor->m_limitSoftness;
}

- (void)setRestitution:(float)restitution
{
  m_motor->m_bounce = restitution;
}

- (float)restitution
{
  return m_motor->m_bounce;
}

- (void)setEnableMotor:(BOOL)enableMotor
{
  m_motor->m_enableMotor = enableMotor;
}

- (BOOL)enableMotor
{
  return m_motor->m_enableMotor;
}

@end
