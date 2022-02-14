//
//  MDLReader.c
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 11.02.2022.
//

#include "MDLReader.hpp"

studiohdr_t* MDLReader::ReadMDLHeader(const void* data)
{
    return (studiohdr_t *)data;
}
