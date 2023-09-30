//
//  SequencesEncoder.h
//  
//
//  Created by Fedor Artemenkov on 23.09.2023.
//

#ifndef SequencesEncoder_h
#define SequencesEncoder_h

#include <stdio.h>

typedef float vec3_t[3];    // x,y,z
typedef float vec4_t[4];    // x,y,z,w

typedef struct Vector3f
{
    float x, y, z;
} t_vector3f;

typedef struct Quaternion
{
    float x, y, z, w;
} t_quaternion;

void* createContext(const void* data);
void clearContext(void* context);

void calcRotations(int sequence, int frame, void* context);
//void getBoneQuatertion(int bone, t_quaternion* rotation, void* context);
void getBoneRotation(int bone, t_vector3f* position, void* context);
void getBonePosition(int bone, t_vector3f* rotation, void* context);

#endif /* SequencesEncoder_h */
