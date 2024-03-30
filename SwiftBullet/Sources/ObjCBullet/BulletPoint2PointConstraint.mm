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

#import "BulletPoint2PointConstraint.h"
#import "BulletRigidBody.h"
#import "BulletUpAxis.h"
#import "BulletDynamics/ConstraintSolver/btPoint2PointConstraint.h"

@implementation BulletPoint2PointConstraint
{
  btPoint2PointConstraint *m_constraint;
}

- (instancetype)initWithNodeA:(BulletRigidBody *)nodeA
                        nodeB:(BulletRigidBody *)nodeB
                       pivotA:(vector_float3)pivotA
                       pivotB:(vector_float3)pivotB
{
  self = [super init];
  if (self) {
    btRigidBody *ptr_a = btRigidBody::upcast(bullet_cast(nodeA.ptr));
    btVector3 pos_a(pivotA.x, pivotA.y, pivotA.z);
    
    btRigidBody *ptr_b = btRigidBody::upcast(bullet_cast(nodeB.ptr));
    btVector3 pos_b(pivotB.x, pivotB.y, pivotB.z);
    
    m_constraint = new btPoint2PointConstraint(*ptr_a, *ptr_b, pos_a, pos_b);
  }
  return self;
}

- (instancetype)initWithNodeA:(BulletRigidBody *)nodeA
                       pivotA:(vector_float3)pivotA
{
  self = [super init];
  if (self) {
    btRigidBody *ptr_a = btRigidBody::upcast(bullet_cast(nodeA.ptr));
    btVector3 pos_a(pivotA.x, pivotA.y, pivotA.z);

    m_constraint = new btPoint2PointConstraint(*ptr_a, pos_a);
      
      m_constraint->m_setting.m_impulseClamp = 30;
      m_constraint->m_setting.m_tau = 0.001f;
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

- (void)setPivotA:(vector_float3)pivotA
{
  m_constraint->setPivotA(btVector3(pivotA.x, pivotA.y, pivotA.z));
}

- (void)setPivotB:(vector_float3)pivotB
{
  m_constraint->setPivotB(btVector3(pivotB.x, pivotB.y, pivotB.z));
}

- (vector_float3)pivotInA
{
  btVector3 pivot = m_constraint->getPivotInA();
  return vector3(pivot.x(), pivot.y(), pivot.z());
}

- (vector_float3)pivotInB
{
  btVector3 pivot = m_constraint->getPivotInB();
  return vector3(pivot.x(), pivot.y(), pivot.z());
}

-(void)setImpulseClamp:(float)impulseClamp
{
    m_constraint->m_setting.m_impulseClamp = impulseClamp;
}

-(float)impulseClamp
{
    return m_constraint->m_setting.m_impulseClamp;
}

-(void)setTau:(float)tau
{
    m_constraint->m_setting.m_tau = tau;
}

-(float)tau
{
    return m_constraint->m_setting.m_tau;
}

@end
