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

@class BulletConstraint;
@class BulletGhostObject;
@class BulletRigidBody;
@class BulletContactResult;
@class BulletCollisionShape;
@class BulletAllHitsRayResult;
@class BulletClosestHitRayResult;
@class BulletVehicle;
@class BulletPersistentManifold;

@interface BulletWorld : NSObject

+ (btCollisionObjectC *)getCollisionObject:(BulletCollisionObject *)node;
- (btDynamicsWorldC *)getWorld;

@property (nonatomic) vector_float3 gravity;

- (instancetype)init;
- (void)registerGImpact;

- (int)stepSimulationWithTimeStep:(float)timeStep maxSubSteps:(int)maxSubSteps fixedTimeStep:(float)fixedTimeStep NS_REFINED_FOR_SWIFT;

- (void)removeAll;

- (void)addRigidBody:(BulletRigidBody *)rigidBody withCollisionFilterGroup:(int)collisionFilterGroup
    collisionFilterMask:(int)collisionFilterMask NS_REFINED_FOR_SWIFT;
- (void)addRigidBody:(BulletRigidBody *)rigidBody NS_REFINED_FOR_SWIFT;
- (void)removeRigidBody:(BulletRigidBody *)rigidBody NS_REFINED_FOR_SWIFT;
- (void)removeAllRigidBodies;
- (BulletRigidBody *)rigidBodyAt:(NSUInteger)index;
- (NSUInteger)numberOfRigidBodies;

- (void)addGhost:(BulletGhostObject *)ghostNode NS_REFINED_FOR_SWIFT;
- (void)removeGhost:(BulletGhostObject *)ghostNode NS_REFINED_FOR_SWIFT;
- (void)removeAllGhosts;
- (BulletGhostObject *)ghostAt:(NSUInteger)index;
- (NSUInteger)numberOfGhosts;

- (void)addConstraint:(BulletConstraint *)constraint disableCollisionsBetweenLinkedBodies:(BOOL)disableCollisionsBetweenLinkedBodies;
- (void)removeConstraint:(BulletConstraint *)constraint;
- (void)removeAllConstraints;
- (BulletConstraint *)constraintAt:(NSUInteger)index;
- (NSUInteger)numberOfConstraints;

- (BulletContactResult *)contactTest:(BulletCollisionObject *)node;
- (BulletContactResult *)contactTestPairWithNode0:(BulletCollisionObject *)node0 node1:(BulletCollisionObject *)node1;

- (NSUInteger)numberOfManifolds;
- (BulletPersistentManifold *)manifoldByIndex:(NSUInteger)index;

- (BulletAllHitsRayResult *)rayTestAllFrom:(vector_float3)fromPos
                                        to:(vector_float3)toPos
                      collisionFilterGroup:(int)collisionFilterGroup
                       collisionFilterMask:(int)collisionFilterMask;
- (BulletClosestHitRayResult *)rayTestClosestFrom:(vector_float3)fromPos
                                               to:(vector_float3)toPos
                             collisionFilterGroup:(int)collisionFilterGroup
                              collisionFilterMask:(int)collisionFilterMask;

@end

NS_ASSUME_NONNULL_END
