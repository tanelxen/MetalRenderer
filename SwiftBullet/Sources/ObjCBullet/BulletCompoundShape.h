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
#import "BulletCollisionShape.h"
#import "BulletUpAxis.h"
#import "BulletAABB.h"

NS_ASSUME_NONNULL_BEGIN

@class BulletTransform;
@class BulletCollisionShape;

@interface BulletCompoundShape : BulletCollisionShape
- (instancetype)init;
- (instancetype)initWithEnableDynamicAabbTree:(BOOL)enableDynamicAabbTree;
- (void)addChildShape:(BulletCollisionShape *)shape withLocalTransform:(BulletTransform *)localTransform;
- (void)removeChildShape:(BulletCollisionShape *)shape;
- (void)removeChildShapeAtIndex:(NSUInteger)childShapeIndex;
- (void)removeAllChildShapes;
- (NSUInteger)numberOfChildShapes;
- (BulletCollisionShape *)childShapeAtIndex:(int)childShapeIndex;
- (BulletTransform *)childTransformAtIndex:(int)childShapeIndex;
- (void)updateChildTransform:(BulletTransform *)childTransform atIndex:(int)childShapeIndex;
- (NSArray<BulletCollisionShape *> *)childShapes;
- (BulletAABB)aabbWithTransform:(BulletTransform *)transform;
- (void)recalculateLocalAabb;
- (void)setLocalScaling:(vector_float3)scaling;
- (vector_float3)localScaling;
- (void)setMargin:(float)margin;
- (float)margin;
@end

NS_ASSUME_NONNULL_END
