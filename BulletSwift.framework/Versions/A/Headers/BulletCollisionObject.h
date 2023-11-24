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

#import <Foundation/Foundation.h>
#import <simd/simd.h>
#import "BulletCast.h"

NS_ASSUME_NONNULL_BEGIN

@class BulletCollisionShape;
@class BulletTransform;
@class BulletWorld;

/**
 * Activation States
 * http://bulletphysics.org/mediawiki-1.5.8/index.php/Activation_States
 */
typedef NS_ENUM(NSUInteger, BulletActivationState) {
  BulletActivationState_active = 1,
  BulletActivationState_islandSleeping = 2,
  BulletActivationState_wantsDeactivation = 3,
  BulletActivationState_disableDeactivation = 4,
  BulletActivationState_disableSimulation = 5,
};

@interface BulletCollisionObject : NSObject

@property (nonatomic) vector_float3 anisotropicFriction;
@property (nonatomic) float ccdMotionThreshold;
@property (nonatomic) float ccdSweptSphereRadius;
@property (nonatomic) BOOL collisionResponse;
@property (nonatomic) float contactProcessingThreshold;
@property (nonatomic) float deactivationTime;
@property (nonatomic) float friction;
@property (nonatomic) float rollingFriction;
@property (nonatomic) float restitution;
@property (nonatomic, getter = isStaticObject) BOOL staticObject;
@property (nonatomic, getter = isKinematicObject) BOOL kinematicObject;

@property (nonatomic, readonly) BOOL hasAnisotropicFriction;
@property (nonatomic, readonly) BOOL hasContactResponse;

- (instancetype)init;
- (BOOL)checkCollisionWith:(BulletCollisionObject *)node;
- (BulletActivationState)activationState;
- (void)forceActivationState:(BulletActivationState)activationState;

- (void)setActiveState:(BOOL)active;
- (void)setActiveState:(BOOL)active withForce:(BOOL)force;
- (BOOL)isActiveState;

- (BOOL)notifiesCollisions;
- (void)notifyCollisions:(BOOL)value;

- (void)setDeactivationEnabled:(BOOL)enabled;
- (void)setDeactivationEnabled:(BOOL)enabled withForce:(BOOL)force;
- (BOOL)isDeactivationEnabled;

- (void)setCollisionFlag:(int)flag value:(BOOL)value;
- (BOOL)collisionFlag:(int)flag;

- (btCollisionObjectC *)ptr;

@end

NS_ASSUME_NONNULL_END
