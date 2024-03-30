//
//  BulletClosestHitConvexResult.h
//  BulletSwift
//
//  Created by Fedor Artemenkov on 25.11.2023.
//  Copyright © 2023 Yohei Yoshihara. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <simd/simd.h>
#import "BulletCast.h"

NS_ASSUME_NONNULL_BEGIN

@class BulletRigidBody;

@interface BulletClosestHitConvexResult : NSObject
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
- (btClosestConvexResultCallbackC *)callback;
@end

NS_ASSUME_NONNULL_END
