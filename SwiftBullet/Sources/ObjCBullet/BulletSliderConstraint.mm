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

#import "BulletRigidBody.h"
#import "BulletSliderConstraint.h"
#import "BulletTransform.h"
#import "BulletDynamics/ConstraintSolver/btSliderConstraint.h"

@implementation BulletSliderConstraint
{
  btSliderConstraint *m_constraint;
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

    m_constraint = new btSliderConstraint(*ptr_a, *ptr_b, trans_a, trans_b, useReferenceFrameA);
  }
  return self;
}

- (instancetype)initWithNodeA:(BulletRigidBody *)nodeA
                       frameA:(BulletTransform *)frameA
           useReferenceFrameA:(BOOL)useReferenceFrameA
{
  self = [super init];
  if (self) {
    btRigidBody *ptr_a = btRigidBody::upcast(bullet_cast(nodeA.ptr));
    const btTransform &trans_a = *bullet_cast(frameA.constRef);

    m_constraint = new btSliderConstraint(*ptr_a, trans_a, useReferenceFrameA);
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

- (float)lowerLinearLimit
{
  return m_constraint->getLowerLinLimit();
}

- (float)upperLinearLimit
{
  return m_constraint->getUpperLinLimit();
}

- (float)lowerAngularLimit
{
  return m_constraint->getLowerAngLimit();
}

- (float)upperAngularLimit
{
  return m_constraint->getUpperAngLimit();
}

- (void)setLowerLinearLimit:(float)lowerLinearLimit
{
  m_constraint->setLowerLinLimit(lowerLinearLimit);
}

- (void)setUpperLinearLimit:(float)upperLinearLimit
{
  m_constraint->setUpperLinLimit(upperLinearLimit);
}

- (void)setLowerAngularLimit:(float)lowerAngularLimit
{
  m_constraint->setLowerAngLimit(lowerAngularLimit);
}

- (void)setUpperAngularLimit:(float)upperAngularLimit
{
  m_constraint->setUpperAngLimit(upperAngularLimit);
}

- (float)linearPos
{
  return m_constraint->getLinearPos();
}

- (float)angularPos
{
  return m_constraint->getAngularPos();
}

- (void)setPoweredLinearMotor:(BOOL)poweredLinearMotor
{
  m_constraint->setPoweredLinMotor(poweredLinearMotor);
}

- (void)setTargetLinearMotorVelocity:(float)targetLinearMotorVelocity
{
  m_constraint->setTargetLinMotorVelocity(targetLinearMotorVelocity);
}

- (void)setMaxLinearMotorForce:(float)maxLinearMotorForce
{
  m_constraint->setMaxLinMotorForce(maxLinearMotorForce);
}

- (BOOL)poweredLinearMotor
{
  return m_constraint->getPoweredLinMotor();
}

- (float)targetLinearMotorVelocity
{
  return m_constraint->getTargetLinMotorVelocity();
}

- (float)maxLinearMotorForce
{
  return m_constraint->getMaxLinMotorForce();
}

- (void)setPoweredAngularMotor:(BOOL)poweredAngularMotor
{
  m_constraint->setPoweredAngMotor(poweredAngularMotor);
}

- (void)setTargetAngularMotorVelocity:(float)targetAngularMotorVelocity
{
  m_constraint->setTargetAngMotorVelocity(targetAngularMotorVelocity);
}

- (void)setMaxAngularMotorForce:(float)maxAngularMotorForce
{
  m_constraint->setMaxAngMotorForce(maxAngularMotorForce);
}

- (BOOL)poweredAngularMotor
{
  return m_constraint->getPoweredAngMotor();
}

- (float)targetAngularMotorVelocity
{
  return m_constraint->getTargetAngMotorVelocity();
}

- (float)maxAngularMotorForce
{
  return m_constraint->getMaxAngMotorForce();
}

#pragma mark DirLin - moving inside linear limits

- (void)setSoftnessDirLin:(float)softnessDirLin
{
  m_constraint->setSoftnessDirLin(softnessDirLin);
}

- (float)softnessDirLin
{
  return m_constraint->getSoftnessDirLin();
}

- (void)setRestitutionDirLin:(float)restitutionDirLin
{
  m_constraint->setRestitutionDirLin(restitutionDirLin);
}

- (float)restitutionDirLin
{
  return m_constraint->getRestitutionDirLin();
}

- (void)setDampingDirLin:(float)dampingDirLin
{
  m_constraint->setDampingDirLin(dampingDirLin);
}

- (float)dampingDirLin
{
  return m_constraint->getRestitutionDirLin();
}

#pragma mark DirAng - moving inside angular limits

- (void)setSoftnessDirAng:(float)softnessDirAng
{
  m_constraint->setSoftnessDirAng(softnessDirAng);
}

- (float)softnessDirAng
{
  return m_constraint->getSoftnessDirAng();
}

- (void)setRestitutionDirAng:(float)restitutionDirAng
{
  m_constraint->setRestitutionDirAng(restitutionDirAng);
}

- (float)restitutionDirAng
{
  return m_constraint->getRestitutionDirAng();
}

- (void)setDampingDirAng:(float)dampingDirAng
{
  m_constraint->setDampingDirAng(dampingDirAng);
}

- (float)dampingDirAng
{
  return m_constraint->getDampingDirAng();
}

#pragma mark LimLin - hitting linear limit

- (void)setSoftnessLimLin:(float)softnessLimLin
{
  m_constraint->setSoftnessLimLin(softnessLimLin);
}

- (float)softnessLimLin
{
  return m_constraint->getSoftnessLimLin();
}

- (void)setRestitutionLimLin:(float)restitutionLimLin
{
  m_constraint->setRestitutionLimLin(restitutionLimLin);
}

- (float)restitutionLimLin
{
  return m_constraint->getRestitutionLimLin();
}

- (void)setDampingLimLin:(float)dampingLimLin
{
  m_constraint->setDampingDirLin(dampingLimLin);
}

- (float)dampingLimLin
{
  return m_constraint->getDampingLimLin();
}

#pragma mark LimAng - hitting angular limit

- (void)setSoftnessLimAng:(float)softnessLimAng
{
  m_constraint->setSoftnessLimAng(softnessLimAng);
}

- (float)softnessLimAng
{
  return m_constraint->getSoftnessLimAng();
}

- (void)setRestitutionLimAng:(float)restitutionLimAng
{
  m_constraint->setRestitutionLimAng(restitutionLimAng);
}

- (float)restitutionLimAng
{
  return m_constraint->getRestitutionLimAng();
}

- (void)setDampingLimAng:(float)dampingLimAng
{
  m_constraint->setDampingLimAng(dampingLimAng);
}

- (float)dampingLimAng
{
  return m_constraint->getDampingLimAng();
}

#pragma mark OrthoLin,OrthoAng - against constraint axis

- (void)setSoftnessOrthoLin:(float)softnessOrthoLin
{
  m_constraint->setSoftnessOrthoLin(softnessOrthoLin);
}

- (float)softnessOrthoLin
{
  return m_constraint->getSoftnessOrthoLin();
}

- (void)setRestitutionOrthoLin:(float)restitutionOrthoLin
{
  m_constraint->setRestitutionOrthoLin(restitutionOrthoLin);
}

- (float)restitutionOrthoLin
{
  return m_constraint->getRestitutionOrthoLin();
}

- (void)setDampingOrthoLin:(float)dampingOrthoLin
{
  m_constraint->setDampingOrthoLin(dampingOrthoLin);
}

- (float)dampingOrthoLin
{
  return m_constraint->getDampingOrthoLin();
}

- (void)setSoftnessOrthoAng:(float)softnessOrthoAng
{
  m_constraint->setSoftnessOrthoAng(softnessOrthoAng);
}

- (float)softnessOrthoAng
{
  return m_constraint->getSoftnessOrthoAng();
}

- (void)setRestitutionOrthoAng:(float)restitutionOrthoAng
{
  m_constraint->setRestitutionOrthoAng(restitutionOrthoAng);
}

- (float)restitutionOrthoAng
{
  return m_constraint->getRestitutionOrthoAng();
}

- (void)setDampingOrthoAng:(float)dampingOrthoAng
{
  m_constraint->setDampingOrthoAng(dampingOrthoAng);
}

- (float)dampingOrthoAng
{
  return m_constraint->getDampingOrthoAng();
}

@end
