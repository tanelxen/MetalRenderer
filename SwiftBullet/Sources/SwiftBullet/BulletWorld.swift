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

import ObjCBullet
import Foundation
import simd

public extension BulletWorld
{
    @discardableResult
    func stepSimulation(timeStep: Float, maxSubSteps: Int = 1, fixedTimeStep: Float = Float(1.0/60.0)) -> Int
    {
        return Int(__stepSimulation(withTimeStep: timeStep, maxSubSteps: Int32(maxSubSteps), fixedTimeStep: fixedTimeStep))
    }
    
    func add(rigidBody: BulletRigidBody, collisionFilterGroup: Int32, collisionFilterMask: Int32)
    {
        __add(rigidBody, withCollisionFilterGroup: collisionFilterGroup, collisionFilterMask: collisionFilterMask)
    }
    
    func add(rigidBody: BulletRigidBody)
    {
        __add(rigidBody)
    }
    
    func remove(rigidBody: BulletRigidBody)
    {
        __remove(rigidBody)
    }
    
    func add(ghost: BulletGhostObject)
    {
        __addGhost(ghost)
    }
    
    func remove(ghost: BulletGhostObject)
    {
        __removeGhost(ghost)
    }
}
