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

@interface BulletSliderConstraint : BulletConstraint
@property (nonatomic, readonly) float linearPos;
@property (nonatomic, readonly) float angularPos;
@property (nonatomic) BOOL poweredLinearMotor;
@property (nonatomic) float maxLinearMotorForce;
@property (nonatomic) float targetLinearMotorVelocity;
@property (nonatomic) BOOL poweredAngularMotor;
@property (nonatomic) float maxAngularMotorForce;
@property (nonatomic) float targetAngularMotorVelocity;
@property (nonatomic) float lowerLinearLimit;
@property (nonatomic) float upperLinearLimit;
@property (nonatomic) float lowerAngularLimit;
@property (nonatomic) float upperAngularLimit;

@property (nonatomic) float softnessDirLin;
@property (nonatomic) float restitutionDirLin;
@property (nonatomic) float dampingDirLin;

@property (nonatomic) float softnessLimLin;
@property (nonatomic) float restitutionLimLin;
@property (nonatomic) float dampingLimLin;

@property (nonatomic) float softnessDirAng;
@property (nonatomic) float restitutionDirAng;
@property (nonatomic) float dampingDirAng;

@property (nonatomic) float softnessLimAng;
@property (nonatomic) float restitutionLimAng;
@property (nonatomic) float dampingLimAng;

@property (nonatomic) float softnessOrthoLin;
@property (nonatomic) float restitutionOrthoLin;
@property (nonatomic) float dampingOrthoLin;

@property (nonatomic) float softnessOrthoAng;
@property (nonatomic) float restitutionOrthoAng;
@property (nonatomic) float dampingOrthoAng;

- (instancetype)initWithNodeA:(BulletRigidBody *)nodeA
                        nodeB:(BulletRigidBody *)nodeB
                       frameA:(BulletTransform *)frameA
                       frameB:(BulletTransform *)frameB
           useReferenceFrameA:(BOOL)useReferenceFrameA;

- (instancetype)initWithNodeA:(BulletRigidBody *)nodeA
                       frameA:(BulletTransform *)frameA
           useReferenceFrameA:(BOOL)useReferenceFrameA;
@end

NS_ASSUME_NONNULL_END
