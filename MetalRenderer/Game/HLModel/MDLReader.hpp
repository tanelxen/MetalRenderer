//
//  MDLReader.h
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 11.02.2022.
//

#ifndef MDLReader_h
#define MDLReader_h

#include <stdio.h>
#include "studio.hpp"

class MDLReader
{
public:
    studiohdr_t* ReadMDLHeader(const void* data);
};

#endif /* MDLReader_h */
