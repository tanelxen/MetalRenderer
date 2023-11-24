//
//  PlayerMovement.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 12.12.2022.
//

import simd
import Foundation

fileprivate enum MovementConstants
{
    static let cl_forwardspeed: Float = 400.0
    static let cl_sidespeed: Float = 350.0
    static let cl_movement_accelerate: Float = 15.0
    static let cl_movement_airaccelerate: Float = 7.0
    static let cl_movement_friction: Float = 8.0
    static let sv_gravity: Float = 800.0
    static let sv_max_speed: Float = 320.0
    static let cl_stop_speed: Float = 200.0
    static let cpm_air_stop_acceleration: Float = 2.5
    static let cpm_air_control_amount: Float = 150.0
    static let cpm_strafe_acceleration: Float = 70.0
    static let cpm_wish_speed: Float = 30.0
}

fileprivate let OVERCLIP: Float = 1.001
fileprivate let MAX_CLIP_PLANES: Int = 5
fileprivate let STEPSIZE: Float = 18

fileprivate let MOVEMENT_JUMP: Int              = 1 << 1
fileprivate let MOVEMENT_JUMP_THIS_FRAME: Int   = 1 << 2
fileprivate let MOVEMENT_JUMPING: Int           = 1 << 3

/*
 Класс отвечающий за обработку столкновений и симуляцию физики игрока
 */
final class PlayerMovement
{
    // Сцена, которая производит определение столкновений
    // TODO: работать через протокол CollisionDetector
    weak var scene: Q3MapScene!
    
    var transform: Transform = Transform()
    
    // Движение по осям через WASD
    var forwardmove: Float = 0.0
    var rightmove: Float = 0.0
    
    var cl_forwardspeed: Float = 200.0
    
    var isWishJump = false
    
    var isNoclip = false
    
    // Текущий вектор направления движения
    private var velocity: float3 = .zero
    
    // Нормаль плоскости, на которой стоит игрок
    private var ground_normal: float3?
    
    private let player_mins = float3( -15, -15, -24 )
    private let player_maxs = float3( 15, 15, 32 )
    
    private var movement: Int = 0
    
    var playStepsSound: (() -> Void)?
    private var lastStepDate = Date()
    private let stepDistance: Float = 64.0
    
    var speed: Float {
        length(velocity)
    }
    
    var isWalking: Bool {
        return speed > 10 && (forwardmove != 0 || rightmove != 0) && ground_normal != nil
    }
    
    // Произвести все вычисления столкновений и обновить position и velocity
    func update()
    {
        if isWishJump
        {
            movement |= MOVEMENT_JUMP
        }
        else
        {
            movement &= ~MOVEMENT_JUMP
        }
        
        trace_ground()
        apply_inputs()
        
        movement &= ~MOVEMENT_JUMP_THIS_FRAME

        if !isNoclip
        {
            let gravity = (movement & MOVEMENT_JUMPING) != 0
            step_slide(gravity: gravity)
        }
        else
        {
            transform.position += velocity * GameTime.deltaTime
        }
        
        if isWalking
        {
            let dt = Double(stepDistance / speed)
            
            if -lastStepDate.timeIntervalSinceNow > dt
            {
                lastStepDate = Date()
                playStepsSound?()
            }
        }
    }
    
    private func apply_inputs()
    {
        var forward = transform.rotation.forward
        var right = transform.rotation.right
        
        forward.z = 0
        right.z = 0
        
        if let normal = self.ground_normal
        {
            // Проецируем вектора на плоскость для движения по ней
            forward = clip_velocity(forward, normal: normal, overbounce: OVERCLIP)
            right = clip_velocity(right, normal: normal, overbounce: OVERCLIP)
            
            nrm3(&forward)
            nrm3(&right)
        }
        
        var direction: float3 = .zero
        direction += forward * forwardmove * cl_forwardspeed
        direction += right * rightmove * MovementConstants.cl_sidespeed
        
        var wishspeed = simd.length(direction)
        
        wishspeed = min(wishspeed, MovementConstants.sv_max_speed)
        
        if wishspeed >= 0.0001 {
            direction /= wishspeed
        }

        apply_jump()
        apply_friction()

        var selected_acceleration = MovementConstants.cl_movement_accelerate
        let base_wishspeed = wishspeed

        /* cpm air acceleration | TODO: pull this out */
        if isNoclip || (movement & MOVEMENT_JUMPING) != 0 || (movement & MOVEMENT_JUMP_THIS_FRAME) != 0
        {
            if dot(velocity, direction) < 0 {
                selected_acceleration = MovementConstants.cpm_air_stop_acceleration
            } else {
                selected_acceleration = MovementConstants.cl_movement_airaccelerate
            }

            if rightmove != 0 && forwardmove == 0
            {
                wishspeed = min(wishspeed, MovementConstants.cpm_wish_speed)
                selected_acceleration = MovementConstants.cpm_strafe_acceleration
            }
        }

        apply_acceleration(direction: direction, wishspeed: wishspeed, acceleration: selected_acceleration)
        apply_air_control(direction: direction, wishspeed: base_wishspeed)
    }
    
    private func apply_jump()
    {
        if !(movement & MOVEMENT_JUMP != 0) { return }
        if (movement & MOVEMENT_JUMPING != 0) && !isNoclip { return }

        movement |= MOVEMENT_JUMP_THIS_FRAME
        velocity.z = 270
        
        /* no auto bunnyhop */
        movement &= ~MOVEMENT_JUMP
    }
    
    // Поиск плоскости, на которой стоит игрок
    private func trace_ground()
    {
        var point = transform.position
        point.z -= 0.25
        
        let hitResult = scene.trace(start: transform.position, end: point, mins: player_mins, maxs: player_maxs)

        if hitResult.fraction == 1 || (movement & MOVEMENT_JUMP_THIS_FRAME) != 0
        {
            movement |= MOVEMENT_JUMPING
            ground_normal = nil
        }
        else
        {
            movement &= ~MOVEMENT_JUMPING
            ground_normal = hitResult.plane?.normal
        }
    }
    
    private func apply_friction()
    {
        if !isNoclip
        {
            if (movement & MOVEMENT_JUMPING) != 0 || (movement & MOVEMENT_JUMP_THIS_FRAME) != 0
            {
                return
            }
        }

        let speed = sqrt(dot(velocity, velocity))
        
        if speed < 1
        {
            velocity.x = 0
            velocity.y = 0
            return
        }

        let control = speed < MovementConstants.cl_stop_speed ? MovementConstants.cl_stop_speed : speed
        
        var new_speed = speed - control * MovementConstants.cl_movement_friction * GameTime.deltaTime
        new_speed = max(0, new_speed)
        
        velocity *= (new_speed / speed)
    }
    
    private func apply_acceleration(direction: float3, wishspeed: Float, acceleration: Float)
    {
        var wishspeed = wishspeed
        
        if !isNoclip && (movement & MOVEMENT_JUMPING) != 0
        {
            wishspeed = min(MovementConstants.cpm_wish_speed, wishspeed)
        }

        let cur_speed = dot(velocity, direction)
        let add_speed = wishspeed - cur_speed

        if add_speed <= 0 { return }

        var accel_speed = acceleration * GameTime.deltaTime * wishspeed
        accel_speed = min(accel_speed, add_speed)

        velocity += direction * accel_speed
    }
    
    private func apply_air_control(direction: float3, wishspeed: Float)
    {
        if forwardmove == 0 || wishspeed == 0 { return }

        let zspeed = velocity.z
        velocity.z = 0
        
        let speed = sqrt(dot(velocity, velocity))
        
        if speed >= 0.0001
        {
            velocity /= speed
        }
        

        let dot = dot(velocity, direction)

        if dot > 0
        {
            velocity *= speed
            nrm3(&velocity)
        }
        
        velocity *= speed
        velocity.z = zspeed
    }
    
    private func step_slide(gravity: Bool)
    {
        let start_o = transform.position
        let start_v = velocity
        
        if slide(gravity: gravity) == false
        {
            // we got exactly where we wanted to go first try
            return
        }
        
        var down = start_o
        down.z -= STEPSIZE

        var trace = scene.trace(start: start_o, end: down, mins: player_mins, maxs: player_maxs)

        var up = float3(0, 0, 1)
        
        // never step up when you still have up velocity
        if velocity.z > 0 && (trace.fraction == 1.0 || dot(trace.plane!.normal, up) < 0.7)
        {
            return
        }

        up = start_o
        up.z += STEPSIZE
        
        // test the player position if they were a stepheight higher
        trace = scene.trace(start: up, end: up, mins: player_mins, maxs: player_maxs)
        
        if trace.allsolid
        {
            // can't step up
            return
        }

        // try slidemove from this position
        transform.position = up
        velocity = start_v
        
        slide(gravity: gravity)

        // push down the final amount
        down = transform.position
        down.z -= STEPSIZE
        
        trace = scene.trace(start: transform.position, end: down, mins: player_mins, maxs: player_maxs)
        
        if !trace.allsolid
        {
            transform.position = trace.endpos
        }
        
        if trace.fraction < 1.0
        {
            velocity = clip_velocity(velocity, normal: trace.plane!.normal, overbounce: OVERCLIP)
        }
    }
    
    @discardableResult
    private func slide(gravity: Bool) -> Bool
    {
        var planes: [float3] = []
        
        var end_velocity: float3 = .zero
        
        var time_left = GameTime.deltaTime

        if gravity
        {
            end_velocity = velocity
            end_velocity.z -= MovementConstants.sv_gravity * GameTime.deltaTime
            
            /*
             * not 100% sure why this is necessary, maybe to avoid tunneling
             * through the floor when really close to it
             */

            velocity.z = (end_velocity.z + velocity.z) * 0.5

            /* slide against floor */
            if let ground_normal = ground_normal
            {
                velocity = clip_velocity(velocity, normal: ground_normal, overbounce: OVERCLIP)
            }
        }

        if let ground_normal = ground_normal
        {
            planes.append(ground_normal)
        }
        
        var vel = velocity
        nrm3(&vel)
        planes.append(vel)
        
        var n_bumps = 0

        while n_bumps < 4
        {
            defer { n_bumps += 1 }
            
            /* calculate future position and attempt the move */
            let end = transform.position + velocity * time_left
            let work = scene.trace(start: transform.position, end: end, mins: player_mins, maxs: player_maxs)
            
            if work.allsolid
            {
                // entity is completely trapped in another solid
                // don't build up falling damage, but allow sideways acceleration
                velocity.z = 0
                return true
            }

            if work.fraction > 0
            {
                transform.position = work.endpos
            }

            /* if nothing blocked us we are done */
            if work.fraction == 1 { break }

            time_left -= time_left * work.fraction

            if planes.count >= MAX_CLIP_PLANES {
                velocity = .zero
                return true
            }

            /*
             * if it's a plane we hit before, nudge velocity along it
             * to prevent epsilon issues and dont re-test it
             */
            
            let normal = work.plane!.normal
            
            if planes.contains(where: { dot(normal, $0) > 0.99 })
            {
                velocity += normal
                continue
            }
            

            /*
             * entirely new plane, add it and clip velocity against all
             * planes that the move interacts with
             */

            planes.append(normal)

            for i in 0 ..< planes.count
            {
                if dot(velocity, planes[i]) >= 0.1 { continue }

                var clipped = clip_velocity(velocity, normal: planes[i], overbounce: OVERCLIP)
                var end_clipped = clip_velocity(end_velocity, normal: planes[i], overbounce: OVERCLIP)

                /*
                 * if the clipped move still hits another plane, slide along
                 * the line where the two planes meet (cross product) with the
                 * un-clipped velocity
                 *
                 * TODO: reduce nesting in here
                 */
                
                for j in 0 ..< planes.count
                {
                    if j == i { continue }

                    if dot(clipped, planes[j]) >= 0.1 { continue }

                    clipped = clip_velocity(clipped, normal: planes[j], overbounce: OVERCLIP)
                    end_clipped = clip_velocity(end_clipped, normal: planes[j], overbounce: OVERCLIP)

                    /* goes back into the first plane */
                    if dot(clipped, planes[i]) >= 0 { continue }

                    var dir = cross(planes[i], planes[j])
                    nrm3(&dir)

                    clipped = dir * dot(dir, velocity)
                    end_clipped = dir * dot(dir, end_velocity)

                    /* if we still hit a plane, just give up and dead stop */

                    for k in 0 ..< planes.count
                    {
                        if k == j || k == i { continue }

                        if dot(clipped, planes[k]) >= 0.1 { continue }
                        
                        velocity = .zero
                        return true
                    }
                }

                /* resolved all collisions for this move */
                velocity = clipped
                end_velocity = end_clipped
                break
            }
        }

        if gravity
        {
            velocity = end_velocity
        }

        return n_bumps != 0
    }

}

fileprivate func clamp(angles: inout float3)
{
    let doubledPI = 2 * Float.pi
    
    if angles.x < 0 { angles.x += doubledPI }
    if angles.x > doubledPI { angles.x -= doubledPI }
    
    if angles.y < 0 { angles.y += doubledPI }
    if angles.y > doubledPI { angles.y -= doubledPI }
}

fileprivate func clip_velocity(_ velocity: float3, normal: float3, overbounce: Float) -> float3
{
    var backoff = simd.dot(velocity, normal)

    if backoff < 0
    {
        backoff *= overbounce
    }
    else
    {
        backoff /= overbounce
    }
    
    return velocity - normal * backoff
}

fileprivate func nrm3(_ v: inout float3)
{
    let squared_len = dot(v, v)

    if squared_len < 0.0001 {
        return
    }

    let len = sqrt(squared_len)
    
    v = v / len
}
