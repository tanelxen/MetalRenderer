//
//  SequencesEncoder.c
//  
//
//  Created by Fedor Artemenkov on 23.09.2023.
//

#include "SequencesEncoder.h"

#include "studio.h"
#include "mathlib.h"

#include <stdlib.h>

typedef struct
{
    studiohdr_t* m_studiohdr;

    // Значения для текущего кадра текушей анимации
    vec3_t  frame_pos[MAXSTUDIOBONES];
    vec3_t  frame_rot_euler[MAXSTUDIOBONES];
    vec4_t  frame_rot_quat[MAXSTUDIOBONES];
    
} t_context;

void calcBoneQuaternion(int frame, mstudiobone_t *pbone, mstudioanim_t *panim, float *q);
void calcBoneRotation(int frame, mstudiobone_t *pbone, mstudioanim_t *panim, float *angle);
void calcBonePosition(int frame, mstudiobone_t *pbone, mstudioanim_t *panim, float *pos);

void* createContext(const void* data)
{
    t_context *ctx = (t_context *) malloc(sizeof(t_context));
    
    ctx->m_studiohdr = (studiohdr_t *)data;
    
    return ctx;
}

void clearContext(void* context)
{
    free(context);
}

void calcRotations(int sequence, int frame, void* context)
{
    t_context *ctx = (t_context *)context;
    
    mstudioseqdesc_t *pseqdesc;
    mstudioseqgroup_t *pseqgroup;
    
    pseqdesc = (mstudioseqdesc_t *)((byte *)ctx->m_studiohdr + ctx->m_studiohdr->seqindex) + sequence;
    pseqgroup = (mstudioseqgroup_t *)((byte *)ctx->m_studiohdr + ctx->m_studiohdr->seqgroupindex) + pseqdesc->seqgroup;
    
    mstudioanim_t *panim = (mstudioanim_t *)((byte *)ctx->m_studiohdr + pseqdesc->animindex);
    mstudiobone_t *pbone = (mstudiobone_t *)((byte *)ctx->m_studiohdr + ctx->m_studiohdr->boneindex);
    
    for (int i = 0; i < ctx->m_studiohdr->numbones; i++, pbone++, panim++)
    {
//        calcBoneQuaternion(frame, pbone, panim, ctx->frame_rot_quat[i]);
        calcBoneRotation(frame, pbone, panim, ctx->frame_rot_euler[i]);
        calcBonePosition(frame, pbone, panim, ctx->frame_pos[i]);
    }
}

void getBoneQuatertion(int bone, t_quaternion* rotation, void* context)
{
    t_context *ctx = (t_context *)context;
    
    rotation->x =  ctx->frame_rot_quat[bone][0];
    rotation->y =  ctx->frame_rot_quat[bone][1];
    rotation->z =  ctx->frame_rot_quat[bone][2];
    rotation->w =  ctx->frame_rot_quat[bone][3];
}

void getBonePosition(int bone, t_vector3f* position, void* context)
{
    t_context *ctx = (t_context *)context;
    
    position->x =  ctx->frame_pos[bone][0];
    position->y =  ctx->frame_pos[bone][1];
    position->z =  ctx->frame_pos[bone][2];
}

void getBoneRotation(int bone, t_vector3f* rotation, void* context)
{
    t_context *ctx = (t_context *)context;
    
    rotation->x =  ctx->frame_rot_euler[bone][0];
    rotation->y =  ctx->frame_rot_euler[bone][1];
    rotation->z =  ctx->frame_rot_euler[bone][2];
}

void calcBoneQuaternion(int frame, mstudiobone_t *pbone, mstudioanim_t *panim, float *q)
{
    int                    j, k;
    vec4_t                q1, q2;
    vec3_t                angle1, angle2;
    mstudioanimvalue_t    *panimvalue;

    for (j = 0; j < 3; j++)
    {
        if (panim->offset[j + 3] == 0)
        {
            angle2[j] = angle1[j] = pbone->value[j + 3]; // default;
        }
        else
        {
            panimvalue = (mstudioanimvalue_t *)((byte *)panim + panim->offset[j + 3]);
            k = frame;
            while (panimvalue->num.total <= k)
            {
                k -= panimvalue->num.total;
                panimvalue += panimvalue->num.valid + 1;
            }
            // Bah, missing blend!
            if (panimvalue->num.valid > k)
            {
                angle1[j] = panimvalue[k + 1].value;
                
                if (panimvalue->num.valid > k + 1)
                {
                    angle2[j] = panimvalue[k + 2].value;
                }
                else
                {
                    if (panimvalue->num.total > k + 1)
                        angle2[j] = angle1[j];
                    else
                        angle2[j] = panimvalue[panimvalue->num.valid + 2].value;
                }
            }
            else
            {
                angle1[j] = panimvalue[panimvalue->num.valid].value;
                if (panimvalue->num.total > k + 1)
                {
                    angle2[j] = angle1[j];
                }
                else
                {
                    angle2[j] = panimvalue[panimvalue->num.valid + 2].value;
                }
            }
            
            angle1[j] = pbone->value[j + 3] + angle1[j] * pbone->scale[j + 3];
            angle2[j] = pbone->value[j + 3] + angle2[j] * pbone->scale[j + 3];
        }
    }

    AngleQuaternion(angle1, q);
}

void calcBoneRotation(int frame, mstudiobone_t *pbone, mstudioanim_t *panim, float *angle)
{
    int                    j, k;
    mstudioanimvalue_t    *panimvalue;

    for (j = 0; j < 3; j++)
    {
        if (panim->offset[j + 3] == 0)
        {
            angle[j] = pbone->value[j + 3]; // default;
        }
        else
        {
            panimvalue = (mstudioanimvalue_t *)((byte *)panim + panim->offset[j + 3]);
            k = frame;
            while (panimvalue->num.total <= k)
            {
                k -= panimvalue->num.total;
                panimvalue += panimvalue->num.valid + 1;
            }
            // Bah, missing blend!
            if (panimvalue->num.valid > k)
            {
                angle[j] = panimvalue[k + 1].value;
            }
            else
            {
                angle[j] = panimvalue[panimvalue->num.valid].value;
            }
            
            angle[j] = pbone->value[j + 3] + angle[j] * pbone->scale[j + 3];
        }
    }
}

void calcBonePosition(int frame, mstudiobone_t *pbone, mstudioanim_t *panim, float *pos)
{
    int                    j, k;
    mstudioanimvalue_t    *panimvalue;
    
    float s = 0.0;

    for (j = 0; j < 3; j++)
    {
        pos[j] = pbone->value[j]; // default;
        
        if (panim->offset[j] != 0)
        {
            panimvalue = (mstudioanimvalue_t *)((byte *)panim + panim->offset[j]);

            k = frame;
            // find span of values that includes the frame we want
            while (panimvalue->num.total <= k)
            {
                k -= panimvalue->num.total;
                panimvalue += panimvalue->num.valid + 1;
            }
            // if we're inside the span
            if (panimvalue->num.valid > k)
            {
                // and there's more data in the span
                if (panimvalue->num.valid > k + 1)
                {
                    pos[j] += (panimvalue[k + 1].value * (1.0 - s) + s * panimvalue[k + 2].value) * pbone->scale[j];
                }
                else
                {
                    pos[j] += panimvalue[k + 1].value * pbone->scale[j];
                }
            }
            else
            {
                // are we at the end of the repeating values section and there's another section with data?
                if (panimvalue->num.total <= k + 1)
                {
                    pos[j] += (panimvalue[panimvalue->num.valid].value * (1.0 - s) + s * panimvalue[panimvalue->num.valid + 2].value) * pbone->scale[j];
                }
                else
                {
                    pos[j] += panimvalue[panimvalue->num.valid].value * pbone->scale[j];
                }
            }
        }

//        if (pbone->bonecontroller[j] != -1)
//        {
//            pos[j] += m_adj[pbone->bonecontroller[j]];
//        }
    }
}
