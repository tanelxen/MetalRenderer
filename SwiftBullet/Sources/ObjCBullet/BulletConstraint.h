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

@class BulletRigidBody;

typedef NS_ENUM(NSUInteger, BulletConstraintParams)
{
	BulletConstraintParams_erp = 1,
	BulletConstraintParams_stop_erp,
	BulletConstraintParams_cfm,
	BulletConstraintParams_stop_cfm
};

@interface BulletConstraint : NSObject

@property (nonatomic, getter = needsFeedback) BOOL enableFeedback;
@property (nonatomic, getter = isEnabled) BOOL enabled;
@property (nonatomic, readonly) float appliedImpulse;
@property (nonatomic, strong, readonly) BulletRigidBody *rigidBodyA;
@property (nonatomic, strong, readonly) BulletRigidBody *rigidBodyB;

- (void)setValue:(float)value forParam:(BulletConstraintParams)param;
- (void)setValue:(float)value forParam:(BulletConstraintParams)param andAxis:(int)axis;
- (float)valueForParam:(BulletConstraintParams)param;
- (float)valueForParam:(BulletConstraintParams)param andAxis:(int)axis;

- (void)setBreakingImpulseThreshold:(float)threshold;
- (float)breakingImpulseThreshold;
- (btTypedConstraintC *)ptr;
@end

NS_ASSUME_NONNULL_END
