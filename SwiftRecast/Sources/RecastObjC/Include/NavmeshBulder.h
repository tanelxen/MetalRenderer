//
//  NavmeshBulder.h
//  
//
//  Created by Fedor Artemenkov on 03.04.2024.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NavmeshBulder: NSObject
- (instancetype)init;
- (void)calculateVerts:(const float*)verts nverts:(int)nverts tris:(const int*)tris ntris:(int)ntris;
- (nullable NSData*)getDetourData;
@end

NS_ASSUME_NONNULL_END
