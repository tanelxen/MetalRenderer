/**
 Bullet Continuous Collision Detection and Physics Library
 Copyright (c) 2003-2006 Erwin Coumans  http://continuousphysics.com/Bullet/
 
 Swift Binding
 Copyright (c) 2018 Yohei Yoshihara
 
 This software is provided 'as-is', without any express or implied warranty.
 In no event will the authors be held liable for any damages arising from the use of this software.
 Permission is granted to anyone to use this software for any purpose,
 including commercial applications, and to alter it and redistribute it freely,
 subject to the following restrictions:
 
 1. The origin of this software must not be misrepresented; you must not claim that you wrote the original software.
 If you use this software in a product, an acknowledgment in the product documentation would be appreciated
 but is not required.
 2. Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.
 3. This notice may not be removed or altered from any source distribution.
 */

#import "BulletAllHitsRayResult.h"
#import "BulletClosestHitRayResult.h"
#import "BulletClosestHitConvexResult.h"
#import "BulletConstraint.h"
#import "BulletContactResult.h"
#import "BulletGhostObject.h"
#import "BulletRigidBody.h"
#import "BulletWorld.h"
#import "BulletUpAxis.h"
#import "BulletPersistentManifold.h"
#import "BulletCollision/CollisionShapes/btBox2dShape.h"
#import "btBulletDynamicsCommon.h"
#import "BulletCollision/CollisionDispatch/btGhostObject.h"
#import "BulletCollision/Gimpact/btGImpactCollisionAlgorithm.h"

#import "BulletCollisionShape.h"

@interface BulletWorld ()
@end

@implementation BulletWorld
{
    btDefaultCollisionConfiguration *m_collisionConfig;
    btDbvtBroadphase *m_broadphase;
    btCollisionDispatcher *m_collisionDispatcher;
    btSequentialImpulseConstraintSolver *m_constraintSolver;
    btDiscreteDynamicsWorld *m_world;
    
    NSMutableArray<BulletRigidBody *> *m_bodies;
    NSMutableArray<BulletGhostObject *> *m_ghosts;
    NSMutableArray<BulletConstraint *> *m_constraints;
    NSMutableArray *m_vehicles;
}

+ (btCollisionObjectC *)getCollisionObject:(BulletCollisionObject *)node
{
    if ([node isKindOfClass:[BulletRigidBody class]]) {
        return ((BulletRigidBody *)node).ptr;
    }
    else if ([node isKindOfClass:[BulletGhostObject class]]) {
        return ((BulletGhostObject *)node).ptr;
    }
    return nil;
}

- (btDynamicsWorldC *)getWorld
{
    return bullet_cast(static_cast<btDynamicsWorld *>(m_world));
}

- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        m_collisionConfig = new btDefaultCollisionConfiguration();
        m_broadphase = new btDbvtBroadphase();
        m_collisionDispatcher = new btCollisionDispatcher(m_collisionConfig);
        m_constraintSolver = new btSequentialImpulseConstraintSolver();
        m_world = new btDiscreteDynamicsWorld(m_collisionDispatcher,
                                              m_broadphase,
                                              m_constraintSolver,
                                              m_collisionConfig);
        
        m_broadphase->getOverlappingPairCache()->setInternalGhostPairCallback(new btGhostPairCallback());
        
        m_bodies = [NSMutableArray array];
        m_ghosts = [NSMutableArray array];
        m_constraints = [NSMutableArray array];
        m_vehicles = [NSMutableArray array];
    }
    return self;
}

- (void)dealloc
{
    [self removeAll];
    delete m_world;
    delete m_collisionConfig;
    delete m_broadphase;
    delete m_collisionDispatcher;
    delete m_constraintSolver;
}

- (void)removeAll
{
    [self removeAllConstraints];
    [self removeAllGhosts];
    [self removeAllRigidBodies];
    //  [self removeAllVehicles];
    //  [self removeAllChildren];
}

- (void)registerGImpact
{
    btCollisionDispatcher * dispatcher = static_cast<btCollisionDispatcher *>(m_world->getDispatcher());
    btGImpactCollisionAlgorithm::registerAlgorithm(dispatcher);
}

- (void)setGravity:(vector_float3)gravity
{
    m_world->setGravity(btVector3(gravity.x, gravity.y, gravity.z));
}

- (vector_float3)gravity
{
    return vector3(m_world->getGravity().x(), m_world->getGravity().y(), m_world->getGravity().z());
}

#pragma mark rigid body

- (void)addRigidBody:(BulletRigidBody *)rigidBody withCollisionFilterGroup:(int)collisionFilterGroup
 collisionFilterMask:(int)collisionFilterMask
{
    NSAssert(![m_bodies containsObject:rigidBody], @"this rigid body already exists");
    
    btRigidBody *ptr = btRigidBody::upcast(bullet_cast(rigidBody.ptr));
    NSAssert(ptr != nullptr, @"object is not a rigid body");
    
    [m_bodies addObject:rigidBody];
    m_world->addRigidBody(ptr, collisionFilterGroup, collisionFilterMask);
}

- (void)addRigidBody:(BulletRigidBody *)rigidBody
{
    NSAssert(![m_bodies containsObject:rigidBody], @"this rigid body already exists");
    
    btRigidBody *ptr = btRigidBody::upcast(bullet_cast(rigidBody.ptr));
    NSAssert(ptr != nullptr, @"object is not a rigid body");
    
    [m_bodies addObject:rigidBody];
    m_world->addRigidBody(ptr);
}

- (void)removeRigidBody:(BulletRigidBody *)rigidBody
{
    NSAssert([m_bodies containsObject:rigidBody], @"this rigid body does not exist");
    
    btRigidBody *ptr = btRigidBody::upcast(bullet_cast(rigidBody.ptr));
    NSAssert(ptr != nullptr, @"object is not a rigid body");
    
    [m_bodies removeObject:rigidBody];
    m_world->removeRigidBody(ptr);
}

- (void)removeAllRigidBodies
{
    for(BulletRigidBody *rigidBody in m_bodies) {
        btRigidBody *ptr = btRigidBody::upcast(bullet_cast(rigidBody.ptr));
        NSAssert(ptr != nullptr, @"object is not a rigid body");
        m_world->removeRigidBody(ptr);
    }
    [m_bodies removeAllObjects];
}

- (BulletRigidBody *)rigidBodyAt:(NSUInteger)index
{
    return m_bodies[index];
}

- (NSUInteger)numberOfRigidBodies
{
    return m_bodies.count;
}

#pragma mark ghost

- (void)addGhost:(BulletGhostObject *)ghostNode
{
    NSAssert(![m_ghosts containsObject:ghostNode], @"this ghost body already exists");
    
    btGhostObject *ptr = btGhostObject::upcast((btCollisionObject *)ghostNode.ptr);
    NSAssert(ptr != nullptr, @"object is not a ghost body");
    
    short group = btBroadphaseProxy::SensorTrigger;
    short mask = btBroadphaseProxy::AllFilter
    & ~btBroadphaseProxy::StaticFilter
    & ~btBroadphaseProxy::SensorTrigger;
    
    [m_ghosts addObject:ghostNode];
    m_world->addCollisionObject(ptr, group, mask);
}

- (void)removeGhost:(BulletGhostObject *)ghostNode
{
    NSAssert([m_ghosts containsObject:ghostNode], @"this ghost body does not exist");
    
    btGhostObject *ptr = btGhostObject::upcast((btCollisionObject *)ghostNode.ptr);
    NSAssert(ptr != nullptr, @"object is not a ghost body");
    
    [m_ghosts removeObject:ghostNode];
    m_world->removeCollisionObject(ptr);
}

- (void)removeAllGhosts
{
    for(BulletGhostObject *ghostNode in m_ghosts) {
        btGhostObject *ptr = btGhostObject::upcast((btCollisionObject *)ghostNode.ptr);
        NSAssert(ptr != nullptr, @"object is not a ghost body");
        m_world->removeCollisionObject(ptr);
    }
    [m_ghosts removeAllObjects];
}

- (BulletGhostObject *)ghostAt:(NSUInteger)index
{
    return m_ghosts[index];
}

- (NSUInteger)numberOfGhosts
{
    return m_ghosts.count;
}

#pragma mark constraint

- (void)addConstraint:(BulletConstraint *)constraint disableCollisionsBetweenLinkedBodies:(BOOL)disableCollisionsBetweenLinkedBodies
{
    NSAssert(constraint, @"constraint must not be nil");
    NSAssert(![m_constraints containsObject:constraint], @"constraint already attached");
    [m_constraints addObject:constraint];
    m_world->addConstraint(bullet_cast(constraint.ptr), disableCollisionsBetweenLinkedBodies);
}

- (void)removeConstraint:(BulletConstraint *)constraint
{
    NSAssert([m_constraints containsObject:constraint], @"constraint not attached");
    [m_constraints removeObject:constraint];
    m_world->removeConstraint(bullet_cast(constraint.ptr));
}

- (void)removeAllConstraints
{
    for(BulletConstraint *constraint in m_constraints) {
        m_world->removeConstraint(bullet_cast(constraint.ptr));
    }
    [m_constraints removeAllObjects];
}

- (BulletConstraint *)constraintAt:(NSUInteger)index
{
    return m_constraints[index];
}

- (NSUInteger)numberOfConstraints
{
    return m_constraints.count;
}

#pragma mark common

- (int)stepSimulationWithTimeStep:(float)timeStep maxSubSteps:(int)maxSubSteps fixedTimeStep:(float)fixedTimeStep {
    return m_world->stepSimulation(timeStep, maxSubSteps, fixedTimeStep);
}

- (BulletContactResult *)contactTest:(BulletCollisionObject *)node
{
    btCollisionObject *obj = bullet_cast([BulletWorld getCollisionObject:node]);
    BulletContactResult *cb = [[BulletContactResult alloc] init];
    if (obj) {
        m_world->contactTest(obj, *bullet_cast(cb.callback));
    }
    return cb;
}

- (BulletContactResult *)contactTestPairWithNode0:(BulletCollisionObject *)node0 node1:(BulletCollisionObject *)node1
{
    btCollisionObject *obj0 = bullet_cast([BulletWorld getCollisionObject:node0]);
    btCollisionObject *obj1 = bullet_cast([BulletWorld getCollisionObject:node1]);
    
    BulletContactResult *cb = [[BulletContactResult alloc] init];
    
    if (obj0 && obj1) {
        m_world->contactPairTest(obj0, obj1, *bullet_cast(cb.callback));
    }
    
    return cb;
}

- (NSUInteger)numberOfManifolds
{
    return m_world->getDispatcher()->getNumManifolds();
}

- (BulletPersistentManifold *)manifoldByIndex:(NSUInteger)index
{
    btPersistentManifold *pm = m_world->getDispatcher()->getManifoldByIndexInternal(static_cast<int>(index));
    return [[BulletPersistentManifold alloc] initWithPersistentManifold:bullet_cast(pm)];
}

- (BulletAllHitsRayResult *)rayTestAllFrom:(vector_float3)fromPos
                                        to:(vector_float3)toPos
                      collisionFilterGroup:(int)collisionFilterGroup
                       collisionFilterMask:(int)collisionFilterMask
{
    const btVector3 from(fromPos.x, fromPos.y, fromPos.z);
    const btVector3 to(toPos.x, toPos.y, toPos.z);
    
    BulletAllHitsRayResult *cb = [[BulletAllHitsRayResult alloc] initWithFrom:fromPos
                                                                           to:toPos
                                                         collisionFilterGroup:collisionFilterGroup
                                                          collisionFilterMask:collisionFilterMask];
    m_world->rayTest(from, to, *bullet_cast(cb.callback));
    return cb;
}

- (BulletClosestHitRayResult *)rayTestClosestFrom:(vector_float3)fromPos
                                               to:(vector_float3)toPos
                             collisionFilterGroup:(int)collisionFilterGroup
                              collisionFilterMask:(int)collisionFilterMask
{
    const btVector3 from(fromPos.x, fromPos.y, fromPos.z);
    const btVector3 to(toPos.x, toPos.y, toPos.z);
    
    BulletClosestHitRayResult *cb = [[BulletClosestHitRayResult alloc] initWithFrom:fromPos
                                                                                 to:toPos
                                                               collisionFilterGroup:collisionFilterGroup
                                                                collisionFilterMask:collisionFilterMask];
    m_world->rayTest(from, to, *bullet_cast(cb.callback));
    return cb;
}

- (BulletClosestHitConvexResult *)convexTestClosestFrom:(vector_float3)fromPos
                                                     to:(vector_float3)toPos
                                                  shape:(BulletCollisionShape *)shape
                                   collisionFilterGroup:(int)collisionFilterGroup
                                    collisionFilterMask:(int)collisionFilterMask
{
    btTransform from;
    from.setIdentity();
    from.setOrigin(btVector3(fromPos.x, fromPos.y, fromPos.z));
    
    btTransform to;
    to.setIdentity();
    to.setOrigin(btVector3(toPos.x, toPos.y, toPos.z));
    
    BulletClosestHitConvexResult *cb = [[BulletClosestHitConvexResult alloc] initWithFrom:fromPos
                                                                                       to:toPos
                                                                     collisionFilterGroup:collisionFilterGroup
                                                                      collisionFilterMask:collisionFilterMask];
    
    btConvexShape* convex = reinterpret_cast<btConvexShape *>(shape.ptr);
    
    m_world->convexSweepTest(convex, from, to, *bullet_cast(cb.callback));
    return cb;
}

@end
