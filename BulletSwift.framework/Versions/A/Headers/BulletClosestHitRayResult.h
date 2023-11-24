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

@interface BulletClosestHitRayResult : NSObject
@property (nonatomic, readonly) vector_float3 fromPos;
@property (nonatomic, readonly) vector_float3 toPos;
@property (nonatomic, readonly) int collisionFilterGroup;
@property (nonatomic, readonly) int collisionFilterMask;
@property (nonatomic, readonly) BOOL hasHits;
@property (nonatomic, readonly) BulletRigidBody *node;
@property (nonatomic, readonly) vector_float3 hitPos;
@property (nonatomic, readonly) vector_float3 hitNormal;
@property (nonatomic, readonly) float hitFraction;
@property (nonatomic, readonly) int shapePart;
@property (nonatomic, readonly) int triangleIndex;

- (instancetype)initWithFrom:(vector_float3)fromPos
                          to:(vector_float3)toPos
        collisionFilterGroup:(int)collisionFilterGroup
         collisionFilterMask:(int)collisionFilterMask;
- (btClosestRayResultCallbackC *)callback;
@end

NS_ASSUME_NONNULL_END
