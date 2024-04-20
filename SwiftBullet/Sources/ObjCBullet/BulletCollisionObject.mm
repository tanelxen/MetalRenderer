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

#import "BulletCollisionObject.h"
#import "BulletCollisionShape.h"
#import "BulletTransform.h"
#import "BulletWorld.h"
#import "BulletUpAxis.h"
#import "BulletCollision/CollisionShapes/btCollisionShape.h"
#import "BulletCollision/CollisionShapes/btCompoundShape.h"
#import "BulletCollision/CollisionShapes/btConvexHullShape.h"
#import "BulletCollision/CollisionShapes/btEmptyShape.h"

@implementation BulletCollisionObject

- (instancetype)init
{
  self = [super init];
  if (self) {
  }
  return self;
}

- (void)setCollisionResponse:(BOOL)collisionResponse
{
  NSAssert(self.ptr != nullptr, @"can not call this method before attaching to the Bullet World");
  [self setCollisionFlag:btCollisionObject::CF_NO_CONTACT_RESPONSE value:!collisionResponse];
}

- (BOOL)collisionResponse
{
  NSAssert(self.ptr != nullptr, @"can not call this method before attaching to the Bullet World");
  return ![self collisionFlag:btCollisionObject::CF_NO_CONTACT_RESPONSE];
}

- (void)notifyCollisions:(BOOL)value
{
  NSAssert(self.ptr != nullptr, @"can not call this method before attaching to the Bullet World");
  [self setCollisionFlag:btCollisionObject::CF_CUSTOM_MATERIAL_CALLBACK value:value];
}

- (BOOL)notifiesCollisions
{
  NSAssert(self.ptr != nullptr, @"can not call this method before attaching to the Bullet World");
  return [self collisionFlag:btCollisionObject::CF_CUSTOM_MATERIAL_CALLBACK];
}

- (void)setStaticObject:(BOOL)staticObject
{
  NSAssert(self.ptr != nullptr, @"can not call this method before attaching to the Bullet World");
  [self setCollisionFlag:btCollisionObject::CF_STATIC_OBJECT value:staticObject];
}

- (BOOL)isStaticObject
{
  NSAssert(self.ptr != nullptr, @"can not call this method before attaching to the Bullet World");
  return bullet_cast(self.ptr)->isStaticObject();
}

- (void)setKinematicObject:(BOOL)kinematicObject
{
  NSAssert(self.ptr != nullptr, @"can not call this method before attaching to the Bullet World");
  [self setCollisionFlag:btCollisionObject::CF_KINEMATIC_OBJECT value:kinematicObject];
}

- (BOOL)isKinematicObject
{
  NSAssert(self.ptr != nullptr, @"can not call this method before attaching to the Bullet World");
  return bullet_cast(self.ptr)->isKinematicObject();
}

- (void)setRestitution:(float)restitution
{
  NSAssert(self.ptr != nullptr, @"can not call this method before attaching to the Bullet World");
  bullet_cast(self.ptr)->setRestitution(restitution);
}

- (float)restitution
{
  NSAssert(self.ptr != nullptr, @"can not call this method before attaching to the Bullet World");
  return bullet_cast(self.ptr)->getRestitution();
}

- (void)setFriction:(float)friction
{
  NSAssert(self.ptr != nullptr, @"can not call this method before attaching to the Bullet World");
  bullet_cast(self.ptr)->setFriction(friction);
}

- (float)friction
{
  NSAssert(self.ptr != nullptr, @"can not call this method before attaching to the Bullet World");
  return bullet_cast(self.ptr)->getFriction();
}

- (void)setRollingFriction:(float)rollingFriction
{
  NSAssert(self.ptr != nullptr, @"can not call this method before attaching to the Bullet World");
  bullet_cast(self.ptr)->setRollingFriction(rollingFriction);
}

- (float)rollingFriction
{
  NSAssert(self.ptr != nullptr, @"can not call this method before attaching to the Bullet World");
  return bullet_cast(self.ptr)->getRollingFriction();
}

- (BOOL)hasAnisotropicFriction
{
  NSAssert(self.ptr != nullptr, @"can not call this method before attaching to the Bullet World");
  return bullet_cast(self.ptr)->hasAnisotropicFriction();
}

- (void)setAnisotropicFriction:(vector_float3)anisotropicFriction
{
  NSAssert(self.ptr != nullptr, @"can not call this method before attaching to the Bullet World");
  bullet_cast(self.ptr)->setAnisotropicFriction(btVector3(anisotropicFriction.x, anisotropicFriction.y, anisotropicFriction.z));
}

- (vector_float3)anisotropicFriction
{
  NSAssert(self.ptr != nullptr, @"can not call this method before attaching to the Bullet World");
  btVector3 friction = bullet_cast(self.ptr)->getAnisotropicFriction();
  return vector3(friction.x(), friction.y(), friction.z());
}

- (BOOL)hasContactResponse
{
  NSAssert(self.ptr != nullptr, @"can not call this method before attaching to the Bullet World");
  return bullet_cast(self.ptr)->hasContactResponse();
}

- (void)setContactProcessingThreshold:(float)contactProcessingThreshold
{
  NSAssert(self.ptr != nullptr, @"can not call this method before attaching to the Bullet World");
  bullet_cast(self.ptr)->setContactProcessingThreshold(contactProcessingThreshold);
}

- (float)contactProcessingThreshold
{
  NSAssert(self.ptr != nullptr, @"can not call this method before attaching to the Bullet World");
  return bullet_cast(self.ptr)->getContactProcessingThreshold();
}

- (void)setCcdSweptSphereRadius:(float)ccdSweptSphereRadius
{
  NSAssert(self.ptr != nullptr, @"can not call this method before attaching to the Bullet World");
  bullet_cast(self.ptr)->setCcdSweptSphereRadius(ccdSweptSphereRadius);
}

- (float)ccdSweptSphereRadius
{
  NSAssert(self.ptr != nullptr, @"can not call this method before attaching to the Bullet World");
  return bullet_cast(self.ptr)->getCcdSweptSphereRadius();
}

- (void)setCcdMotionThreshold:(float)ccdMotionThreshold
{
  NSAssert(self.ptr != nullptr, @"can not call this method before attaching to the Bullet World");
  bullet_cast(self.ptr)->setCcdMotionThreshold(ccdMotionThreshold);
}

- (float)ccdMotionThreshold
{
  NSAssert(self.ptr != nullptr, @"can not call this method before attaching to the Bullet World");
  return bullet_cast(self.ptr)->getCcdMotionThreshold();
}

- (void)setDeactivationEnabled:(BOOL)enabled
{
  NSAssert(self.ptr != nullptr, @"can not call this method before attaching to the Bullet World");
  [self setDeactivationEnabled:enabled withForce:NO];
}

- (void)setDeactivationEnabled:(BOOL)enabled withForce:(BOOL)force;
{
  NSAssert(self.ptr != nullptr, @"can not call this method before attaching to the Bullet World");
  int state = (enabled) ? WANTS_DEACTIVATION : DISABLE_DEACTIVATION;
  if(force) {
    bullet_cast(self.ptr)->forceActivationState(state);
  }
  else {
    bullet_cast(self.ptr)->setActivationState(state);
  }
}

- (BOOL)isDeactivationEnabled
{
  NSAssert(self.ptr != nullptr, @"can not call this method before attaching to the Bullet World");
  return (bullet_cast(self.ptr)->getActivationState() & DISABLE_DEACTIVATION) == 0;
}

- (void)setDeactivationTime:(float)deactivationTime
{
  NSAssert(self.ptr != nullptr, @"can not call this method before attaching to the Bullet World");
  bullet_cast(self.ptr)->setDeactivationTime(deactivationTime);
}

- (float)deactivationTime
{
  NSAssert(self.ptr != nullptr, @"can not call this method before attaching to the Bullet World");
  return bullet_cast(self.ptr)->getDeactivationTime();
}

- (BOOL)checkCollisionWith:(BulletCollisionObject *)node
{
  btCollisionObject *obj = bullet_cast([BulletWorld getCollisionObject:node]);
  if (obj) {
    return bullet_cast(self.ptr)->checkCollideWith(obj);
  }
  else {
    return NO;
  }
}

- (BulletActivationState)activationState
{
  return (BulletActivationState)bullet_cast(self.ptr)->getActivationState();
}

- (void)forceActivationState:(BulletActivationState)activationState
{
  bullet_cast(self.ptr)->forceActivationState(static_cast<int>(activationState));
}

- (void)setActiveState:(BOOL)active
{
  NSAssert(self.ptr != nullptr, @"can not call this method before attaching to the Bullet World");
  [self setActiveState:active withForce:NO];
}

- (void)setActiveState:(BOOL)active withForce:(BOOL)force
{
  NSAssert(self.ptr != nullptr, @"can not call this method before attaching to the Bullet World");
  if (active) {
    bullet_cast(self.ptr)->activate(force);
  }
  else {
    if (force) {
      bullet_cast(self.ptr)->forceActivationState(ISLAND_SLEEPING);
    }
    else {
      bullet_cast(self.ptr)->setActivationState(ISLAND_SLEEPING);
    }
  }
}

- (BOOL)isActiveState
{
  NSAssert(self.ptr != nullptr, @"can not call this method before attaching to the Bullet World");
  return self.ptr != nullptr ? bullet_cast(self.ptr)->isActive() : NO;
}


- (void)setCollisionFlag:(int)flag value:(BOOL)value
{
  NSAssert(self.ptr != nullptr, @"can not call this method before attaching to the Bullet World");
  int flags = bullet_cast(self.ptr)->getCollisionFlags();
  
  if (value == YES) {
    flags |= flag;
  }
  else {
    flags &= ~(flag);
  }
  bullet_cast(self.ptr)->setCollisionFlags(flags);
}

- (BOOL)collisionFlag:(int)flag
{
  NSAssert(self.ptr != nullptr, @"can not call this method before attaching to the Bullet World");
  return (bullet_cast(self.ptr)->getCollisionFlags() & flag) ? YES : NO;
}

- (btCollisionObjectC *)ptr
{
  NSAssert(NO, @"subclass must override");
  return nil;
}

- (NSString *)description
{
  return @"BulletBodyNode";
}

- (void)setWorldTransform:(BulletTransform *)transform
{
    const btTransform &_transform = *bullet_cast(transform.constRef);
    bullet_cast(self.ptr)->setWorldTransform(_transform);
}

@end
