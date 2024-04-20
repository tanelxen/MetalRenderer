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

#import "BulletRigidBody.h"
#import "BulletUpAxis.h"
#import "BulletTransform.h"
#import "BulletCollisionShape.h"
#import "BulletCollision/CollisionShapes/btCollisionShape.h"
#import "BulletDynamics/Dynamics/btRigidBody.h"

class BulletMotionState: public btMotionState
{
    void *m_node;
    
public:
    BulletMotionState(BulletRigidBody *node) : m_node((__bridge void *)node)
    {
    }
    
    virtual ~BulletMotionState() {}
    
    virtual void getWorldTransform(btTransform &transform) const override
    {
        BulletRigidBody *node = (__bridge BulletRigidBody *)m_node;
        BulletTransform *trans = node.motionStateGetCallback();
        transform = *(bullet_cast(trans.constRef));
    }
    
    virtual void setWorldTransform(const btTransform &transform) override
    {
        BulletRigidBody *node = (__bridge BulletRigidBody *)m_node;
        BulletTransform *trans = [[BulletTransform alloc] initWithbtTransform:bullet_cast(&transform)];
        node.motionStateSetCallback(trans);
    }
};


void setEuler(matrix_float4x4 *m, float ax, float ay, float az) {
    // euler -> quaternion
    ax = 0.5f * ax;
    ay = 0.5f * ay;
    az = 0.5f * az;
    
    float sax = sinf(ax);
    float cax = cosf(ax);
    float say = sinf(ay);
    float cay = cosf(ay);
    float saz = sinf(az);
    float caz = cosf(az);
    
    float x = cax * cay * caz + sax * say * saz;
    float y = sax * cay * caz - cax * say * saz;
    float z = cax * say * caz + sax * cay * saz;
    float w = cax * cay * saz - sax * say * caz;
    
    // quaternion -> matrix4x4
    float xy = x * y;
    float xz = x * z;
    float xw = x * w;
    
    float yy = y * y;
    float yz = y * z;
    float yw = y * w;
    
    float zz = z * z;
    float zw = z * w;
    
    float ww = w * w;
    
    m->columns[0][0] = 1 - 2 * (zz + ww);
    m->columns[1][0] =     2 * (yz - xw);
    m->columns[2][0] =     2 * (xz + yw);
    m->columns[0][1] =     2 * (yz + xw);
    m->columns[1][1] = 1 - 2 * (yy + ww);
    m->columns[2][1] =     2 * (zw - xy);
    m->columns[0][2] =     2 * (yw - xz);
    m->columns[1][2] =     2 * (xy + zw);
    m->columns[2][2] = 1 - 2 * (yy + zz);
}

@implementation BulletRigidBody
{
    BulletMotionState *m_motion;
    btRigidBody *m_rigid;
}

- (instancetype)init
{
    NSAssert(NO, @"not supported");
    return nil;
}

- (instancetype)initWithMass:(float)mass
motionStateGetWorldTransform:(MotionStateGetWorldTransform)motionStateGetWorldTransform
motionStateSetWorldTransform:(MotionStateSetWorldTransform)motionStateSetWorldTransform
              collisionShape:(BulletCollisionShape *)collisionShape
                localInertia:(vector_float3)localInertia
{
    self = [super init];
    
    if (self)
    {
        m_motion = new BulletMotionState(self);
        _motionStateGetCallback = motionStateGetWorldTransform;
        _motionStateSetCallback = motionStateSetWorldTransform;
        _shape = collisionShape;
        m_rigid = new btRigidBody(mass, m_motion, bullet_cast(self.shape.ptr), btVector3(localInertia.x, localInertia.y, localInertia.z));
        m_rigid->setUserPointer((__bridge void *)self);
    }
    
    return self;
}

- (void)dealloc
{
    if (m_motion != nullptr) {
        delete m_motion;
    }
    if (m_rigid != nullptr) {
        delete m_rigid;
    }
}

- (btCollisionObjectC *)ptr
{
    return bullet_cast(static_cast<btCollisionObject *>(m_rigid));
}

- (void)setMass:(float)mass
{
    btScalar bt_mass = mass;
    btVector3 bt_inertia(0.0, 0.0, 0.0);
    
    if (bt_mass > 0.0f) {
        m_rigid->getCollisionShape()->calculateLocalInertia(bt_mass, bt_inertia);
    }
    
    m_rigid->setMassProps(bt_mass, bt_inertia);
    m_rigid->updateInertiaTensor();
}

- (float)mass
{
    btScalar inv_mass = m_rigid->getInvMass();
    btScalar mass = (inv_mass == btScalar(0.0)) ? btScalar(0.0) : btScalar(1.0) / inv_mass;
    
    return mass;
}

- (void)applyForce:(vector_float3)force onPoint:(vector_float3)position
{
    NSAssert(m_rigid != nullptr, @"can not call this method before attaching to the Bullet World");
    m_rigid->applyForce(btVector3(force.x, force.y, force.z), btVector3(position.x, position.y, position.z));
}

- (void)applyCentralForce:(vector_float3)force
{
    NSAssert(m_rigid != nullptr, @"can not call this method before attaching to the Bullet World");
    m_rigid->applyCentralForce(btVector3(force.x, force.y, force.z));
}

- (void)applyTorque:(vector_float3)torque
{
    NSAssert(m_rigid != nullptr, @"can not call this method before attaching to the Bullet World");
    m_rigid->applyTorque(btVector3(torque.x, torque.y, torque.z));
}

- (void)applyTorqueImpulse:(vector_float3)torque
{
    NSAssert(m_rigid != nullptr, @"can not call this method before attaching to the Bullet World");
    m_rigid->applyTorqueImpulse(btVector3(torque.x, torque.y, torque.z));
}

- (void)applyImpulse:(vector_float3)impulse onPoint:(vector_float3)position
{
    NSAssert(m_rigid != nullptr, @"can not call this method before attaching to the Bullet World");
    m_rigid->applyImpulse(btVector3(impulse.x, impulse.y, impulse.z),
                          btVector3(position.x, position.y, position.z));
}

- (void)applyCentralImpulse:(vector_float3)impulse
{
    NSAssert(m_rigid != nullptr, @"can not call this method before attaching to the Bullet World");
    m_rigid->applyCentralImpulse(btVector3(impulse.x, impulse.y, impulse.z));
}

- (void)clearForces
{
    NSAssert(m_rigid != nullptr, @"can not call this method before attaching to the Bullet World");
    m_rigid->clearForces();
}

- (void)setAngularDamping:(float)angularDamping
{
    NSAssert(m_rigid != nullptr, @"can not call this method before attaching to the Bullet World");
    m_rigid->setDamping(m_rigid->getLinearDamping(), angularDamping);
}

- (float)angularDamping
{
    NSAssert(m_rigid != nullptr, @"can not call this method before attaching to the Bullet World");
    return m_rigid->getAngularDamping();
}

- (void)setLinearDamping:(float)linearDamping
{
    NSAssert(m_rigid != nullptr, @"can not call this method before attaching to the Bullet World");
    m_rigid->setDamping(linearDamping, m_rigid->getAngularDamping());
}

- (float)linearDamping
{
    NSAssert(m_rigid != nullptr, @"can not call this method before attaching to the Bullet World");
    return m_rigid->getLinearDamping();
}

- (void)setAngularSleepThreshold:(float)angularSleepThreshold
{
    NSAssert(m_rigid != nullptr, @"can not call this method before attaching to the Bullet World");
    m_rigid->setSleepingThresholds(m_rigid->getLinearSleepingThreshold(), angularSleepThreshold);
}

- (float)angularSleepThreshold
{
    NSAssert(m_rigid != nullptr, @"can not call this method before attaching to the Bullet World");
    return m_rigid->getAngularSleepingThreshold();
}

- (void)setLinearSleepThreshold:(float)linearSleepThreshold
{
    m_rigid->setSleepingThresholds(linearSleepThreshold, m_rigid->getAngularSleepingThreshold());
}

- (float)linearSleepThreshold
{
    NSAssert(m_rigid != nullptr, @"can not call this method before attaching to the Bullet World");
    return m_rigid->getLinearSleepingThreshold();
}

- (void)setAngularVelocity:(vector_float3)angularVelocity
{
    NSAssert(m_rigid != nullptr, @"can not call this method before attaching to the Bullet World");
    m_rigid->setAngularVelocity(btVector3(angularVelocity.x, angularVelocity.y, angularVelocity.z));
}

- (vector_float3)angularVelocity
{
    NSAssert(m_rigid != nullptr, @"can not call this method before attaching to the Bullet World");
    btVector3 velocity = m_rigid->getAngularVelocity();
    return vector3(velocity.x(), velocity.y(), velocity.z());
}

- (void)setLinearVelocity:(vector_float3)linearVelocity
{
    NSAssert(m_rigid != nullptr, @"can not call this method before attaching to the Bullet World");
    m_rigid->setLinearVelocity(btVector3(linearVelocity.x, linearVelocity.y, linearVelocity.z));
}

- (vector_float3)linearVelocity
{
    NSAssert(m_rigid != nullptr, @"can not call this method before attaching to the Bullet World");
    btVector3 velocity = m_rigid->getLinearVelocity();
    return vector3(velocity.x(), velocity.y(), velocity.z());
}

- (void)setGravity:(vector_float3)gravity
{
    NSAssert(m_rigid != nullptr, @"can not call this method before attaching to the Bullet World");
    m_rigid->setGravity(btVector3(gravity.x, gravity.y, gravity.z));
}

- (vector_float3)gravity
{
    NSAssert(m_rigid != nullptr, @"can not call this method before attaching to the Bullet World");
    btVector3 gravity = m_rigid->getGravity();
    return vector3(gravity.x(), gravity.y(), gravity.z());
}

- (void)setInertia:(vector_float3)inertia
{
    NSAssert(m_rigid != nullptr, @"can not call this method before attaching to the Bullet World");
    btVector3 inv_inertia(inertia.x == 0.0f ? 0.0f : 1.0f / inertia.x,
                          inertia.y == 0.0f ? 0.0f : 1.0f / inertia.y,
                          inertia.z == 0.0f ? 0.0f : 1.0f / inertia.z);
    
    m_rigid->setInvInertiaDiagLocal(inv_inertia);
    m_rigid->updateInertiaTensor();
}

- (vector_float3)inertia
{
    NSAssert(m_rigid != nullptr, @"can not call this method before attaching to the Bullet World");
    btVector3 inv_inertia = m_rigid->getInvInertiaDiagLocal();
    return vector3(inv_inertia.x() == 0.0f ? 0.0f : 1.0f / inv_inertia.x(),
                   inv_inertia.y() == 0.0f ? 0.0f : 1.0f / inv_inertia.y(),
                   inv_inertia.z() == 0.0f ? 0.0f : 1.0f / inv_inertia.z());
}

- (void)setAngularFactor:(vector_float3)angularFactor
{
    NSAssert(m_rigid != nullptr, @"can not call this method before attaching to the Bullet World");
    m_rigid->setAngularFactor(btVector3(angularFactor.x, angularFactor.y, angularFactor.z));
}

- (vector_float3)angularFactor
{
    NSAssert(m_rigid != nullptr, @"can not call this method before attaching to the Bullet World");
    btVector3 v = m_rigid->getAngularFactor();
    return vector3(v.x(), v.y(), v.z());
}

- (void)setLinearFactor:(vector_float3)linearFactor
{
    NSAssert(m_rigid != nullptr, @"can not call this method before attaching to the Bullet World");
    m_rigid->setLinearFactor(btVector3(linearFactor.x, linearFactor.y, linearFactor.z));
}

- (vector_float3)linearFactor
{
    NSAssert(m_rigid != nullptr, @"can not call this method before attaching to the Bullet World");
    btVector3 v = m_rigid->getLinearFactor();
    return vector3(v.x(), v.y(), v.z());
}

- (void)setCenterOfMassTransform:(BulletTransform *)centerOfMassTransform
{
    m_rigid->setCenterOfMassTransform(*bullet_cast(centerOfMassTransform.constRef));
}

- (BulletTransform *)centerOfMassTransform
{
    btTransform t = m_rigid->getCenterOfMassTransform();
    BulletTransform *transform = [[BulletTransform alloc] initWithbtTransform:bullet_cast(&t)];
    return transform;
}

@end
