//
//  BulletKinematicCharacterController.mm
//  BulletSwift
//
//  Created by Fedor Artemenkov on 29.12.2023.
//  Copyright © 2023 Yohei Yoshihara. All rights reserved.
//

#import "BulletCharacterController.h"
#import "BulletRigidBody.h"
#import "BulletGhostObject.h"
#import "BulletCapsuleShape.h"
#import "BulletWorld.h"

#import "BulletDynamics/Character/btKinematicCharacterController.h"
#import "BulletCollision/CollisionDispatch/btGhostObject.h"
#import "BulletCollision/CollisionShapes/btCapsuleShape.h"

#import "LinearMath/btDefaultMotionState.h"
#import "DynamicCharacterController.h"

@implementation BulletCharacterController
{
    btKinematicCharacterController* m_character;
    btConvexShape* m_shape;
}

- (instancetype)initWithWorld:(BulletWorld *)world
                          pos:(vector_float3)pos
                       radius:(float)radius
                       height:(float)height
                   stepHeight:(float)stepHeight
{
    self = [super init];
    
    if (self)
    {
        m_shape = new btCapsuleShapeZ(radius, height);

        btVector3 vPos(pos[0], pos[1], pos[2]);

        btTransform trans;
        trans.setIdentity();
        trans.setOrigin(vPos);

        btPairCachingGhostObject* ghostObject = new btPairCachingGhostObject();
        ghostObject->setWorldTransform(trans);
        ghostObject->setCollisionShape(m_shape);
        ghostObject->setCollisionFlags(btCollisionObject::CF_CHARACTER_OBJECT);

        btVector3 up = btVector3(0, 0, 1);

        m_character = new btKinematicCharacterController(ghostObject, m_shape, stepHeight, up);
        m_character->setUseGhostSweepTest(true);

        btDynamicsWorld* pWorld = (btDynamicsWorld *) world.getWorld;

        pWorld->addCollisionObject(ghostObject, btBroadphaseProxy::CharacterFilter,
                                   btBroadphaseProxy::StaticFilter | btBroadphaseProxy::DefaultFilter | btBroadphaseProxy::CharacterFilter);

        pWorld->addCharacter(m_character);
    }
    
    return self;
}

- (void)setWalkDirection:(vector_float3)walkDirection
{
    btVector3 dir = btVector3(walkDirection.x, walkDirection.y, walkDirection.z);
    m_character->setWalkDirection(dir);
}

- (vector_float3)getPos
{
    btPairCachingGhostObject* ghost = m_character->getGhostObject();
    btVector3 origin = ghost->getWorldTransform().getOrigin();
    
    return vector3(origin.x(), origin.y(), origin.z());
}

- (bool)isOnGround
{
    return m_character->onGround();
}

- (void)jump
{
    m_character->jump();
}

- (void *)ptr
{
    return m_character;
}

- (void)setLinearVelocity:(vector_float3)linearVelocity
{
    m_character->setLinearVelocity(btVector3(linearVelocity.x, linearVelocity.y, linearVelocity.z));
}

- (vector_float3)linearVelocity
{
    btVector3 velocity = m_character->getLinearVelocity();
    return vector3(velocity.x(), velocity.y(), velocity.z());
}

@end
