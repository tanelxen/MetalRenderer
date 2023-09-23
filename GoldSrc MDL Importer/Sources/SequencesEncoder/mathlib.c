//
//  mathlib.c
//  
//
//  Created by Fedor Artemenkov on 23.09.2023.
//

#include "mathlib.h"
#include <math.h>

void AngleQuaternion(const vec3_t angles, vec4_t quaternion)
{
    float        angle;
    float        sr, sp, sy, cr, cp, cy;

    // FIXME: rescale the inputs to 1/2 angle
    angle = angles[2] * 0.5;
    sy = sin(angle);
    cy = cos(angle);
    angle = angles[1] * 0.5;
    sp = sin(angle);
    cp = cos(angle);
    angle = angles[0] * 0.5;
    sr = sin(angle);
    cr = cos(angle);

    quaternion[0] = sr*cp*cy - cr*sp*sy; // X
    quaternion[1] = cr*sp*cy + sr*cp*sy; // Y
    quaternion[2] = cr*cp*sy - sr*sp*cy; // Z
    quaternion[3] = cr*cp*cy + sr*sp*sy; // W
}
