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
#import "BulletCollisionObject.h"

NS_ASSUME_NONNULL_BEGIN

@class BulletCollisionShape;
@class BulletTransform;

typedef  BulletTransform * _Nonnull (^MotionStateGetWorldTransform)(void);
typedef void (^MotionStateSetWorldTransform)(BulletTransform *);

@interface BulletRigidBody : BulletCollisionObject

@property (nonatomic) MotionStateGetWorldTransform motionStateGetCallback;
@property (nonatomic) MotionStateSetWorldTransform motionStateSetCallback;

@property (nonatomic, strong, readonly) BulletCollisionShape *shape;

@property (nonatomic) float mass;
@property (nonatomic) float linearDamping;
@property (nonatomic) float angularDamping;
@property (nonatomic) float linearSleepThreshold;
@property (nonatomic) float angularSleepThreshold;
@property (nonatomic) vector_float3 linearVelocity;
@property (nonatomic) vector_float3 angularVelocity;
@property (nonatomic) vector_float3 linearFactor;
@property (nonatomic) vector_float3 angularFactor;
@property (nonatomic) vector_float3 gravity;
@property (nonatomic) vector_float3 inertia;

@property (nonatomic, strong) BulletTransform *centerOfMassTransform;

- (instancetype)initWithMass:(float)mass
motionStateGetWorldTransform:(MotionStateGetWorldTransform)motionStateGetWorldTransform
motionStateSetWorldTransform:(MotionStateSetWorldTransform)motionStateSetWorldTransform
              collisionShape:(BulletCollisionShape *)collisionShape
                localInertia:(vector_float3)localInertia;
- (instancetype)initWithShape:(BulletCollisionShape *)shape
                     position:(vector_float3)position
                     rotation:(vector_float3)rotation
                         mass:(float)mass
                  restitution:(float)restitution;
- (instancetype)initWithShape:(BulletCollisionShape *)shape
            transformationRef:(const matrix_float4x4 *)transformation
                         mass:(float)mass
                  restitution:(float)restitution;
- (void)applyCentralForce:(vector_float3)force;
- (void)applyCentralImpulse:(vector_float3)impulse;
- (void)applyForce:(vector_float3)force onPoint:(vector_float3)position;
- (void)applyImpulse:(vector_float3)impulse onPoint:(vector_float3)position;
- (void)applyTorque:(vector_float3)torque;
- (void)applyTorqueImpulse:(vector_float3)torque;
- (void)clearForces;
- (btCollisionObjectC *)ptr;
@end


@class BulletWorld;

@interface BulletCharacterController: NSObject

@property (nonatomic) vector_float3 linearVelocity;

- (instancetype)initWithWorld:(BulletWorld *)world
                          pos:(vector_float3)pos
                       radius:(float)radius
                       height:(float)height
                   stepHeight:(float)stepHeight;

- (void)setWalkDirection:(vector_float3)walkDirection;
- (vector_float3)getPos;

- (bool)isOnGround;
- (void)jump;

- (void *)ptr;

@end

NS_ASSUME_NONNULL_END
