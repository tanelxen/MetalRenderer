//
//  Header.h
//  
//
//  Created by Fedor Artemenkov on 01.04.2024.
//

#import <Foundation/Foundation.h>
#import <simd/simd.h>
#import "BulletCast.h"
#import "BulletCollisionObject.h"

NS_ASSUME_NONNULL_BEGIN

@class BulletWorld;

@interface BulletCharacterController: NSObject

@property (nonatomic) vector_float3 linearVelocity;

- (instancetype)initWithWorld:(BulletWorld *)world
                          pos:(vector_float3)pos
                       radius:(float)radius
                       height:(float)height
                   stepHeight:(float)stepHeight;

- (void)setWalkDirection:(vector_float3)walkDirection;
- (vector_float3)getPos;

- (bool)isOnGround;
- (void)jump;

- (void *)ptr;

@end

NS_ASSUME_NONNULL_END
