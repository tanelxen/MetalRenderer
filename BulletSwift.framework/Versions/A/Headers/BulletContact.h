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

@class BulletManifoldPoint;
@class BulletRigidBody;

@interface BulletContact : NSObject
@property (nonatomic, strong, readonly) BulletManifoldPoint *manifoldPoint;
@property (nonatomic, strong, readonly) BulletRigidBody *node0;
@property (nonatomic, strong, readonly) BulletRigidBody *node1;
@property (nonatomic, readonly) int index0;
@property (nonatomic, readonly) int index1;
@property (nonatomic, readonly) int partId0;
@property (nonatomic, readonly) int partId1;

- (instancetype)initWithManifoldPoint:(btManifoldPointC *)manifoldPoint
                              object0:(const btCollisionObjectC *)object0
                              partId0:(int)partId0
                               index0:(int)index0
                              object1:(const btCollisionObjectC *)object1
                              partId1:(int)partId1
                               index1:(int)index1;
@end

NS_ASSUME_NONNULL_END
