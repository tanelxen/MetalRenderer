//
//  BulletClosestHitConvexResult.m
//  BulletSwift
//
//  Created by Fedor Artemenkov on 25.11.2023.
//  Copyright © 2023 Yohei Yoshihara. All rights reserved.
//

#import "BulletClosestHitConvexResult.h"
#import "BulletUpAxis.h"
#import "BulletRigidBody.h"
#import "BulletCollision/CollisionDispatch/btCollisionWorld.h"

struct RayCastClosestConvexResultCallback: public btCollisionWorld::ClosestConvexResultCallback
{
    int m_shapePart;
    int m_triangleIndex;
    
    RayCastClosestConvexResultCallback (const btVector3 &rayFrom, const btVector3 &rayTo)
    : btCollisionWorld::ClosestConvexResultCallback(rayFrom, rayTo),
    m_shapePart(-1),
    m_triangleIndex(-1)
    {}
    
    virtual ~RayCastClosestConvexResultCallback()
    {}
    
    btScalar addSingleResult(btCollisionWorld::LocalConvexResult &convexResult, bool normalInWorldSpace) override
    {
        btScalar result = ClosestConvexResultCallback::addSingleResult(convexResult, normalInWorldSpace);
        
        if (convexResult.m_localShapeInfo)
        {
            m_shapePart = convexResult.m_localShapeInfo->m_shapePart;
            m_triangleIndex = convexResult.m_localShapeInfo->m_triangleIndex;
        }
        
        return result;
    }
};

@implementation BulletClosestHitConvexResult
{
    RayCastClosestConvexResultCallback *m_callback;
}

- (instancetype)initWithFrom:(vector_float3)fromPos
                          to:(vector_float3)toPos
        collisionFilterGroup:(int)collisionFilterGroup
         collisionFilterMask:(int)collisionFilterMask
{
    self = [super init];
    
    if (self)
    {
        m_callback = new RayCastClosestConvexResultCallback(btVector3(fromPos.x, fromPos.y, fromPos.z),
                                                         btVector3(toPos.x, toPos.y, toPos.z));
        m_callback->m_collisionFilterGroup = collisionFilterGroup;
        m_callback->m_collisionFilterMask = collisionFilterMask;
    }
    
    return self;
}

- (void)dealloc
{
    delete m_callback;
}

- (btClosestConvexResultCallbackC *)callback
{
    return bullet_cast(m_callback);
}

- (vector_float3)fromPos
{
    btVector3 v = m_callback->m_convexFromWorld;
    return vector3(v.x(), v.y(), v.z());
}

- (vector_float3)toPos
{
    btVector3 v = m_callback->m_convexToWorld;
    return vector3(v.x(), v.y(), v.z());
}

- (int)collisionFilterGroup
{
    return m_callback->m_collisionFilterGroup;
}

- (int)collisionFilterMask
{
    return m_callback->m_collisionFilterMask;
}

- (BOOL)hasHits
{
    return m_callback->hasHit();
}

- (BulletRigidBody *)node
{
    const btCollisionObject *objectPtr = m_callback->m_hitCollisionObject;
    return (objectPtr) ? (__bridge BulletRigidBody *)objectPtr->getUserPointer() : nil;
}

- (vector_float3)hitPos
{
    btVector3 v = m_callback->m_hitPointWorld;
    return vector3(v.x(), v.y(), v.z());
}

- (vector_float3)hitNormal
{
    btVector3 v = m_callback->m_hitNormalWorld;
    return vector3(v.x(), v.y(), v.z());
}

- (float)hitFraction
{
    return m_callback->m_closestHitFraction;
}

- (int)shapePart
{
    return m_callback->m_shapePart;
}

- (int)triangleIndex
{
    return m_callback->m_triangleIndex;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"{hasHit=%@, hitPos=(%f,%f,%f), hitNormal=(%f,%f,%f), hitFraction=%g, shapePart=%d, triangleIndex=%d, fromPos=(%f, %f, %f), toPos=(%f, %f, %f), collisionFilterGroup=%x, collisionFilterMask=%x}",
            self.hasHits ? @"YES" : @"NO",
            self.hitPos.x, self.hitPos.y, self.hitPos.z,
            self.hitNormal.x, self.hitNormal.y, self.hitNormal.z,
            self.hitFraction,
            self.shapePart,
            self.triangleIndex,
            self.fromPos.x, self.fromPos.y, self.fromPos.z,
            self.toPos.x, self.toPos.y, self.toPos.z,
            self.collisionFilterGroup,
            self.collisionFilterMask];
}

@end

