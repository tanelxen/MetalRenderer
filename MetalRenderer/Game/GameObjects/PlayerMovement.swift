//
//  PlayerMovement.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 12.12.2022.
//

import simd

enum MovementConstants
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
    
    var isNoclip = true
    
    // Текущий вектор направления движения
    private var velocity: float3 = .zero
    
    // Нормаль плоскости, на которой стоит игрок
    private var ground_normal: float3?
    
    private let player_mins = float3( -15, -15, -24 )
    private let player_maxs = float3( 15, 15, 32 )
    
    // Произвести все вычисления столкновений и обновить position и velocity
    func update()
    {
        apply_inputs()
        
        guard !isNoclip else {
            transform.position += velocity * GameTime.deltaTime
            return
        }
        
        trace_ground()
    }
    
    private func apply_inputs()
    {
        let up = float3(0, 1, 0)
        let forward = transform.forward
        let right = simd_cross(forward, up)
        
        var direction: float3 = .zero
        direction += forward * forwardmove * MovementConstants.cl_forwardspeed
        direction += right * rightmove * MovementConstants.cl_sidespeed

        var wishspeed = simd.length(direction)
        wishspeed = min(wishspeed, MovementConstants.sv_max_speed)
        
        direction = simd.normalize(direction)

//        apply_jump()
        apply_friction()

        let selected_acceleration = MovementConstants.cl_movement_accelerate
        let base_wishspeed = wishspeed

//        /* cpm air acceleration | TODO: pull this out */
//        if isNoclip //|| (movement & MOVEMENT_JUMPING) || (movement & MOVEMENT_JUMP_THIS_FRAME)
//        {
//            if (dot3(velocity, direction) < 0) {
//                selected_acceleration = MovementConstants.cpm_air_stop_acceleration
//            } else {
//                selected_acceleration = MovementConstants.cl_movement_airaccelerate
//            }
//
//            if rightmove != 0 && forwardmove == 0
//            {
//                wishspeed = min(wishspeed, MovementConstants.cpm_wish_speed)
//                selected_acceleration = MovementConstants.cpm_strafe_acceleration
//            }
//        }

        apply_acceleration(direction: direction, wishspeed: wishspeed, acceleration: selected_acceleration)
        apply_air_control(wishspeed: base_wishspeed)
    }
    
    // Поиск плоскости, на которой стоит игрок
    private func trace_ground()
    {
        
    }
    
    private func apply_acceleration(direction: float3, wishspeed: Float, acceleration: Float)
    {
        var wishspeed = wishspeed
        
        if !isNoclip // && (movement & MOVEMENT_JUMPING)
        {
            wishspeed = min(MovementConstants.cpm_wish_speed, wishspeed)
        }

        let cur_speed = simd.dot(velocity, direction)
        let add_speed = wishspeed - cur_speed

        guard add_speed > 0 else { return }

        var accel_speed = acceleration * GameTime.deltaTime * wishspeed
        accel_speed = min(accel_speed, add_speed)

        velocity += direction * accel_speed
    }
    
    private func apply_air_control(wishspeed: Float)
    {
        guard forwardmove != 0 || wishspeed > 0 else { return }

        let zspeed = velocity.z
        velocity.z = 0
        
        let speed = simd.length(velocity)
        
        if speed >= 0.0001
        {
            velocity /= speed
        }
        
        velocity *= speed
        velocity.z = zspeed
    }
    
    private func apply_friction()
    {
//        if !isNoclip
//        {
//            if (movement & MOVEMENT_JUMPING) || (movement & MOVEMENT_JUMP_THIS_FRAME)
//            {
//                return
//            }
//        }

        let speed = simd.length(velocity)
        
        if speed < 1
        {
            velocity.x = 0
            velocity.y = 0
            return
        }

        let control = speed < MovementConstants.cl_stop_speed ? MovementConstants.cl_stop_speed : speed
        
        var new_speed = speed - control * MovementConstants.cl_movement_friction * GameTime.deltaTime
        new_speed = max(0, new_speed)
        
        velocity *= new_speed / speed
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
