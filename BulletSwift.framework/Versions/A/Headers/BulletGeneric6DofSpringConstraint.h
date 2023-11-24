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

@interface BulletGeneric6DofSpringConstraint : BulletConstraint
@property (nonatomic) vector_float3 linearLowerLimit;
@property (nonatomic) vector_float3 linearUpperLimit;
@property (nonatomic) vector_float3 angularLowerLimit;
@property (nonatomic) vector_float3 angularUpperLimit;
@property (nonatomic) BulletTransform *frameOffsetA;
@property (nonatomic) BulletTransform *frameOffsetB;
- (instancetype)initWithNodeA:(BulletRigidBody *)nodeA
                        nodeB:(BulletRigidBody *)nodeB
                       frameA:(BulletTransform *)frameA
                       frameB:(BulletTransform *)frameB
           useReferenceFrameA:(BOOL)useReferenceFrameA;
- (instancetype)initWithNodeA:(BulletRigidBody *)nodeA
                       frameA:(BulletTransform *)frameA
           useReferenceFrameA:(BOOL)useReferenceFrameA;
- (float)angleOfAxisIndex:(int)axis;
- (vector_float3)axisOfAxisIndex:(int)axis;
- (float)pivotOfAxisIndex:(int)axis;
- (void)setLowLimit:(float)low highLimit:(float)high forAxisIndex:(int)axis;
- (void)setLinearLowLimit:(float)low highLimit:(float)high forAxisIndex:(int)axis;
- (void)setAngularLowLimit:(float)low highLimit:(float)high forAxisIndex:(int)axis;
- (void)enableSpring:(BOOL)onOff toAxisIndex:(int)axis;
- (void)setStiffness:(float)stiffness forAxisIndex:(int)axis;
- (void)setDamping:(float)damping forAxisIndex:(int)axis;
- (void)setEquilibriumPoint;
- (void)setEquilibriumPointForAxisIndex:(int)axis;
- (void)setEquilibriumPoint:(float)value forAxisIndex:(int)axis;
@end

NS_ASSUME_NONNULL_END
