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

#import "BulletGearConstraint.h"
#import "BulletRigidBody.h"
#import "BulletUpAxis.h"
#import "BulletDynamics/ConstraintSolver/btGearConstraint.h"

@implementation BulletGearConstraint
{
  btGearConstraint *m_constraint;
}

- (instancetype)initWithNodeA:(BulletRigidBody *)nodeA
              nodeB:(BulletRigidBody *)nodeB
              axisA:(vector_float3)axisA
              axisB:(vector_float3)axisB
              ratio:(float)ratio
{
  self = [super init];
  if (self) {
    btRigidBody *ptr_a = btRigidBody::upcast(bullet_cast(nodeA.ptr));
    btVector3 vec_a(axisA.x, axisA.y, axisA.z);
    
    btRigidBody *ptr_b = btRigidBody::upcast(bullet_cast(nodeB.ptr));
    btVector3 vec_b(axisB.x, axisB.y, axisB.z);
    
    m_constraint = new btGearConstraint(*ptr_a, *ptr_b, vec_a, vec_b, ratio);
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

@end
