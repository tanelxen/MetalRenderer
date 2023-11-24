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

@interface BulletTransform : NSObject
@property (nonatomic) matrix_float3x3 basis;
@property (nonatomic) vector_float3 origin;

- (instancetype)init;
- (instancetype)initWithQuaternion:(vector_float4)q translation:(vector_float3)c;
- (instancetype)initWithRotation:(matrix_float3x3)b translation:(vector_float3)c;
- (instancetype)initWithbtTransform:(const btTransformC *)transform;
- (void)setIdentity;
- (BulletTransform *)inverse;
- (vector_float3)multiply:(vector_float3)vec;
- (void)setBasisFromEulerAngles:(vector_float3)eulerAngles;
- (vector_float3)basisAsEulerAngles;

- (btTransformC *)ref;
- (const btTransformC *)constRef;
@end

NS_ASSUME_NONNULL_END
