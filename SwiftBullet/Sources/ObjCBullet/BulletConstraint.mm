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

#import "BulletConstraint.h"
#import "BulletRigidBody.h"
#import "BulletDynamics/ConstraintSolver/btTypedConstraint.h"

@implementation BulletConstraint

- (void)setEnableFeedback:(BOOL)enableFeedback
{
  bullet_cast(self.ptr)->enableFeedback(enableFeedback);
}

- (BOOL)needsFeedback
{
  return bullet_cast(self.ptr)->needsFeedback();
}

- (void)setEnabled:(BOOL)enabled
{
  bullet_cast(self.ptr)->setEnabled(enabled);
}

- (BOOL)isEnabled
{
  return bullet_cast(self.ptr)->isEnabled();
}

- (float)appliedImpulse
{
  return bullet_cast(self.ptr)->getAppliedImpulse();
}

- (BulletRigidBody *)rigidBodyA
{
  return (__bridge BulletRigidBody *)bullet_cast(self.ptr)->getRigidBodyA().getUserPointer();
}

- (BulletRigidBody *)rigidBodyB
{
  return (__bridge BulletRigidBody *)bullet_cast(self.ptr)->getRigidBodyB().getUserPointer();
}

- (btTypedConstraintC *)ptr
{
  NSAssert(NO, @"subclass must override this method");
  return nil;
}

- (void)setValue:(float)value forParam:(BulletConstraintParams)param
{
  bullet_cast(self.ptr)->setParam(static_cast<int>(param), value);
}

- (void)setValue:(float)value forParam:(BulletConstraintParams)param andAxis:(int)axis
{
  bullet_cast(self.ptr)->setParam(static_cast<int>(param), value, axis);
}

- (float)valueForParam:(BulletConstraintParams)param
{
  return bullet_cast(self.ptr)->getParam(static_cast<int>(param));
}

- (float)valueForParam:(BulletConstraintParams)param andAxis:(int)axis
{
  return bullet_cast(self.ptr)->getParam(static_cast<int>(param), axis);
}

- (void)setBreakingImpulseThreshold:(float)threshold
{
  bullet_cast(self.ptr)->setBreakingImpulseThreshold(threshold);
}

- (float)breakingImpulseThreshold
{
  return bullet_cast(self.ptr)->getBreakingImpulseThreshold();
}

- (NSString *)description
{
  NSMutableString *s = [NSMutableString stringWithString:@"BulletConstraint<"];
  [s appendFormat:@"rigidBodyA=%p,", &bullet_cast(self.ptr)->getRigidBodyA()];
  [s appendFormat:@"rigidBodyB=%p", &bullet_cast(self.ptr)->getRigidBodyB()];
  [s appendString:@">"];
  return s;
}

@end
