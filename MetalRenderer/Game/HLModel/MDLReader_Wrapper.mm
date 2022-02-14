//
//  MDLReader_Wrapper.m
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 11.02.2022.
//

#import "MDLReader_Wrapper.h"
#import "MDLReader.hpp"
#import "mdlviewer.hpp"

@implementation MDLReader_Wrapper
{
    MDLReader _reader;
    StudioModel _model;
}

-(id)init: (NSData*) data
{
    self = [super init];
    
    self->_data = data;
    
    return self;
}

-(studiohdr_t) getHeader
{
//    MDLReader reader;
//
    studiohdr_t* header = _reader.ReadMDLHeader(_data.bytes);
    
    return *header;
}

-(void) initModel
{
    _model.Init(_data.bytes);
}

@end
