//
//  mathlib.h
//  
//
//  Created by Fedor Artemenkov on 23.09.2023.
//

#ifndef __MATHLIB__
#define __MATHLIB__

// mathlib.h

typedef float vec3_t[3];    // x,y,z
typedef float vec4_t[4];    // x,y,z,w

#define    ON_EPSILON        0.01
#define    EQUAL_EPSILON    0.001

void AngleQuaternion(const vec3_t angles, vec4_t quaternion);

#endif /* __MATHLIB__ */
