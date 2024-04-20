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
#import "BulletConstraint.h"

NS_ASSUME_NONNULL_BEGIN

@class BulletRigidBody;
@class BulletTransform;

@interface BulletHingeConstraint : BulletConstraint

@property (nonatomic) BOOL angularOnly;
@property (nonatomic, readonly) float hingeAngle;
@property (nonatomic, readonly) float lowerLimit;
@property (nonatomic, readonly) float upperLimit;

- (instancetype)initWithNodeA:(BulletRigidBody *)nodeA
                        nodeB:(BulletRigidBody *)nodeB
                       frameA:(BulletTransform *)frameA
                       frameB:(BulletTransform *)frameB
           useReferenceFrameA:(BOOL)useReferenceFrameA;

- (instancetype)initWithNodeA:(BulletRigidBody *)nodeA
                        nodeB:(BulletRigidBody *)nodeB
                       pivotA:(vector_float3)pivotA
                       pivotB:(vector_float3)pivotB
                        axisA:(vector_float3)axisA
                        axisB:(vector_float3)axisB
           useReferenceFrameA:(BOOL)useReferenceFrameA;

- (instancetype)initWithNodeA:(BulletRigidBody *)nodeA
                        nodeB:(BulletRigidBody *)nodeB
                       pivotA:(vector_float3)pivotA
                       pivotB:(vector_float3)pivotB
                        axisA:(vector_float3)axisA
                        axisB:(vector_float3)axisB;

- (instancetype)initWithNodeA:(BulletRigidBody *)nodeA
                       pivotA:(vector_float3)pivotA
                        axisA:(vector_float3)axisA
           useReferenceFrameA:(BOOL)useReferenceFrameA;

- (instancetype)initWithNodeA:(BulletRigidBody *)nodeA
                       pivotA:(vector_float3)pivotA
                        axisA:(vector_float3)axisA;

- (void)enableAngularMotor:(BOOL)enable withTargetVelocity:(float)targetVelocity maxImpulse:(float)maxImpulse;
- (void)enableMotor:(BOOL)enable;
- (void)setAxis:(vector_float3)axis;
- (void)setLowLimit:(float)low highLimit:(float)high softness:(float)softness bias:(float)bias relaxation:(float)relaxation;
- (void)setLowLimit:(float)low highLimit:(float)high softness:(float)softness bias:(float)bias;
- (void)setLowLimit:(float)low highLimit:(float)high softness:(float)softness;
- (void)setLowLimit:(float)low highLimit:(float)high;
- (void)setMaxMotorImpulse:(float)maxImpulse;
- (void)setMotorTarget:(vector_float4)quat deltaTime:(float)dt;
- (void)setMotorTargetAngle:(float)targetAngle deltaTime:(float)dt;
@end

NS_ASSUME_NONNULL_END
