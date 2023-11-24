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
#import "BulletTransform.h"

NS_ASSUME_NONNULL_BEGIN

@class BulletRigidBody;
@class BulletTransform;

@interface BulletConeTwistConstraint : BulletConstraint

@property (nonatomic) float fixThreshold;

- (instancetype)initWithNodeA:(BulletRigidBody *)nodeA
                        nodeB:(BulletRigidBody *)nodeB
                       frameA:(BulletTransform *)frameA
                       frameB:(BulletTransform *)frameB;
- (instancetype)initWithNodeA:(BulletRigidBody *)nodeA frameA:(BulletTransform *)frameA;

- (void)setLimitWithSwing1:(float)swing1 swing2:(float)swing2 twist:(float)twist softness:(float)softness bias:(float)bias relaxation:(float)relaxation;
- (void)setLimitWithSwing1:(float)swing1 swing2:(float)swing2 twist:(float)twist softness:(float)softness bias:(float)bias;
- (void)setLimitWithSwing1:(float)swing1 swing2:(float)swing2 twist:(float)twist softness:(float)softness;
- (void)setLimitWithSwing1:(float)swing1 swing2:(float)swing2 twist:(float)twist;
- (void)setLimitWithIndex:(int)index value:(float)value;

- (void)setMaxMotorImpulse:(float)maxImpulse;
- (void)setMaxMotorImpulseNormalized:(float)maxImpulse;
- (void)setMotorTarget:(vector_float4)quat;
- (void)setMotorTargetInConstraintSpace:(vector_float4)quat;

- (void)setDamping:(float)damping;
- (void)setEnableMotor:(BOOL)enableMotor;

@end

NS_ASSUME_NONNULL_END
