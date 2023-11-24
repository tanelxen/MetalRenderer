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

#ifndef BulletCast_h
#define BulletCast_h
typedef struct {} btCollisionObjectC;
typedef struct {} btDynamicsWorldC;
typedef struct {} btTypedConstraintC;
typedef struct {} btManifoldPointC;
typedef struct {} btPersistentManifoldC;
typedef struct {} btRotationalLimitMotorC;
typedef struct {} btCollisionShapeC;
typedef struct {} btTransformC;
typedef struct {} btTranslationalLimitMotorC;
typedef struct {} btConcaveShapeC;
typedef struct {} btContactResultCallbackC;
typedef struct {} btAllHitsRayResultCallbackC;
typedef struct {} btClosestRayResultCallbackC;

#ifdef __cplusplus
#include <BulletCollision/CollisionDispatch/btCollisionObject.h>
#include <BulletDynamics/Dynamics/btDynamicsWorld.h>
#include <BulletDynamics/ConstraintSolver/btTypedConstraint.h>
#include <BulletCollision/NarrowPhaseCollision/btManifoldPoint.h>
#include <BulletCollision/NarrowPhaseCollision/btPersistentManifold.h>
#include <BulletDynamics/ConstraintSolver/btGeneric6DofConstraint.h>
#include <BulletCollision/CollisionShapes/btCollisionShape.h>
#include <LinearMath/btTransform.h>
#include <BulletDynamics/ConstraintSolver/btGeneric6DofConstraint.h>
#include <BulletCollision/CollisionShapes/btConcaveShape.h>
#include <BulletCollision/CollisionDispatch/btCollisionWorld.h>
#include <BulletCollision/CollisionDispatch/btCollisionWorld.h>
#include <BulletCollision/CollisionDispatch/btCollisionWorld.h>

inline btCollisionObject * bullet_cast(btCollisionObjectC *p) { return reinterpret_cast<btCollisionObject *>(p); }
inline btCollisionObjectC * bullet_cast(btCollisionObject *p) { return reinterpret_cast<btCollisionObjectC *>(p); }
inline const btCollisionObject * bullet_cast(const btCollisionObjectC *p) { return reinterpret_cast<const btCollisionObject *>(p); }
inline const btCollisionObjectC * bullet_cast(const btCollisionObject *p) { return reinterpret_cast<const btCollisionObjectC *>(p); }

inline btDynamicsWorld * bullet_cast(btDynamicsWorldC *p) { return reinterpret_cast<btDynamicsWorld *>(p); }
inline btDynamicsWorldC * bullet_cast(btDynamicsWorld *p) { return reinterpret_cast<btDynamicsWorldC *>(p); }
inline const btDynamicsWorld * bullet_cast(const btDynamicsWorldC *p) { return reinterpret_cast<const btDynamicsWorld *>(p); }
inline const btDynamicsWorldC * bullet_cast(const btDynamicsWorld *p) { return reinterpret_cast<const btDynamicsWorldC *>(p); }

inline btTypedConstraint * bullet_cast(btTypedConstraintC *p) { return reinterpret_cast<btTypedConstraint *>(p); }
inline btTypedConstraintC * bullet_cast(btTypedConstraint *p) { return reinterpret_cast<btTypedConstraintC *>(p); }
inline const btTypedConstraint * bullet_cast(const btTypedConstraintC *p) { return reinterpret_cast<const btTypedConstraint *>(p); }
inline const btTypedConstraintC * bullet_cast(const btTypedConstraint *p) { return reinterpret_cast<const btTypedConstraintC *>(p); }

inline btManifoldPoint * bullet_cast(btManifoldPointC *p) { return reinterpret_cast<btManifoldPoint *>(p); }
inline btManifoldPointC * bullet_cast(btManifoldPoint *p) { return reinterpret_cast<btManifoldPointC *>(p); }
inline const btManifoldPoint * bullet_cast(const btManifoldPointC *p) { return reinterpret_cast<const btManifoldPoint *>(p); }
inline const btManifoldPointC * bullet_cast(const btManifoldPoint *p) { return reinterpret_cast<const btManifoldPointC *>(p); }

inline btPersistentManifold * bullet_cast(btPersistentManifoldC *p) { return reinterpret_cast<btPersistentManifold *>(p); }
inline btPersistentManifoldC * bullet_cast(btPersistentManifold *p) { return reinterpret_cast<btPersistentManifoldC *>(p); }
inline const btPersistentManifold * bullet_cast(const btPersistentManifoldC *p) { return reinterpret_cast<const btPersistentManifold *>(p); }
inline const btPersistentManifoldC * bullet_cast(const btPersistentManifold *p) { return reinterpret_cast<const btPersistentManifoldC *>(p); }

inline btRotationalLimitMotor * bullet_cast(btRotationalLimitMotorC *p) { return reinterpret_cast<btRotationalLimitMotor *>(p); }
inline btRotationalLimitMotorC * bullet_cast(btRotationalLimitMotor *p) { return reinterpret_cast<btRotationalLimitMotorC *>(p); }
inline const btRotationalLimitMotor * bullet_cast(const btRotationalLimitMotorC *p) { return reinterpret_cast<const btRotationalLimitMotor *>(p); }
inline const btRotationalLimitMotorC * bullet_cast(const btRotationalLimitMotor *p) { return reinterpret_cast<const btRotationalLimitMotorC *>(p); }

inline btCollisionShape * bullet_cast(btCollisionShapeC *p) { return reinterpret_cast<btCollisionShape *>(p); }
inline btCollisionShapeC * bullet_cast(btCollisionShape *p) { return reinterpret_cast<btCollisionShapeC *>(p); }
inline const btCollisionShape * bullet_cast(const btCollisionShapeC *p) { return reinterpret_cast<const btCollisionShape *>(p); }
inline const btCollisionShapeC * bullet_cast(const btCollisionShape *p) { return reinterpret_cast<const btCollisionShapeC *>(p); }

inline btTransform * bullet_cast(btTransformC *p) { return reinterpret_cast<btTransform *>(p); }
inline btTransformC * bullet_cast(btTransform *p) { return reinterpret_cast<btTransformC *>(p); }
inline const btTransform * bullet_cast(const btTransformC *p) { return reinterpret_cast<const btTransform *>(p); }
inline const btTransformC * bullet_cast(const btTransform *p) { return reinterpret_cast<const btTransformC *>(p); }

inline btTranslationalLimitMotor * bullet_cast(btTranslationalLimitMotorC *p) { return reinterpret_cast<btTranslationalLimitMotor *>(p); }
inline btTranslationalLimitMotorC * bullet_cast(btTranslationalLimitMotor *p) { return reinterpret_cast<btTranslationalLimitMotorC *>(p); }
inline const btTranslationalLimitMotor * bullet_cast(const btTranslationalLimitMotorC *p) { return reinterpret_cast<const btTranslationalLimitMotor *>(p); }
inline const btTranslationalLimitMotorC * bullet_cast(const btTranslationalLimitMotor *p) { return reinterpret_cast<const btTranslationalLimitMotorC *>(p); }

inline btConcaveShape * bullet_cast(btConcaveShapeC *p) { return reinterpret_cast<btConcaveShape *>(p); }
inline btConcaveShapeC * bullet_cast(btConcaveShape *p) { return reinterpret_cast<btConcaveShapeC *>(p); }
inline const btConcaveShape * bullet_cast(const btConcaveShapeC *p) { return reinterpret_cast<const btConcaveShape *>(p); }
inline const btConcaveShapeC * bullet_cast(const btConcaveShape *p) { return reinterpret_cast<const btConcaveShapeC *>(p); }

inline btCollisionWorld::ContactResultCallback * bullet_cast(btContactResultCallbackC *p) { return reinterpret_cast<btCollisionWorld::ContactResultCallback *>(p); }
inline btContactResultCallbackC * bullet_cast(btCollisionWorld::ContactResultCallback *p) { return reinterpret_cast<btContactResultCallbackC *>(p); }
inline const btCollisionWorld::ContactResultCallback * bullet_cast(const btContactResultCallbackC *p) { return reinterpret_cast<const btCollisionWorld::ContactResultCallback *>(p); }
inline const btContactResultCallbackC * bullet_cast(const btCollisionWorld::ContactResultCallback *p) { return reinterpret_cast<const btContactResultCallbackC *>(p); }

inline btCollisionWorld::AllHitsRayResultCallback * bullet_cast(btAllHitsRayResultCallbackC *p) { return reinterpret_cast<btCollisionWorld::AllHitsRayResultCallback *>(p); }
inline btAllHitsRayResultCallbackC * bullet_cast(btCollisionWorld::AllHitsRayResultCallback *p) { return reinterpret_cast<btAllHitsRayResultCallbackC *>(p); }
inline const btCollisionWorld::AllHitsRayResultCallback * bullet_cast(const btAllHitsRayResultCallbackC *p) { return reinterpret_cast<const btCollisionWorld::AllHitsRayResultCallback *>(p); }
inline const btAllHitsRayResultCallbackC * bullet_cast(const btCollisionWorld::AllHitsRayResultCallback *p) { return reinterpret_cast<const btAllHitsRayResultCallbackC *>(p); }

inline btCollisionWorld::ClosestRayResultCallback * bullet_cast(btClosestRayResultCallbackC *p) { return reinterpret_cast<btCollisionWorld::ClosestRayResultCallback *>(p); }
inline btClosestRayResultCallbackC * bullet_cast(btCollisionWorld::ClosestRayResultCallback *p) { return reinterpret_cast<btClosestRayResultCallbackC *>(p); }
inline const btCollisionWorld::ClosestRayResultCallback * bullet_cast(const btClosestRayResultCallbackC *p) { return reinterpret_cast<const btCollisionWorld::ClosestRayResultCallback *>(p); }
inline const btClosestRayResultCallbackC * bullet_cast(const btCollisionWorld::ClosestRayResultCallback *p) { return reinterpret_cast<const btClosestRayResultCallbackC *>(p); }

#endif

#endif /* BulletCast_h */
