//
//  DetourPathfinder.h
//  
//
//  Created by Fedor Artemenkov on 05.04.2024.
//

#import <Foundation/Foundation.h>
#import <simd/simd.h>

NS_ASSUME_NONNULL_BEGIN

@interface DetourPathfinder: NSObject
- (instancetype)init;
- (void)loadFromData:(NSData*)data;
- (nullable NSArray*)getPathStartPos:(simd_float3)startPos endPos:(simd_float3)endPos;
@end

NS_ASSUME_NONNULL_END
