//
//  MDLReader_Wrapper.h
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 11.02.2022.
//

#ifndef MDLReader_Wrapper_h
#define MDLReader_Wrapper_h

#import <Foundation/Foundation.h>
#import "studio.hpp"

@interface MDLReader_Wrapper: NSObject
{
    NSData* _data;
}

-(id)init: (NSData*) data;

-(studiohdr_t) getHeader;

-(void) initModel;

@end


#endif /* MDLReader_Wrapper_h */
