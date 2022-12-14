//
//  PlayerMovement.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 12.12.2022.
//

import simd

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
//        trace_ground()
        
        guard !isNoclip else {
            transform.position += velocity * GameTime.deltaTime
            return
        }
        
//        trace_ground()
//        slide(gravity: true)
    }
    
    private func apply_inputs()
    {
        var direction: float3 = .zero
        direction += transform.rotation.forward * forwardmove * MovementConstants.cl_forwardspeed
        direction += transform.rotation.right * rightmove * MovementConstants.cl_sidespeed

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
        var point = transform.position
        point.z -= 0.25
        
        let hitResult = scene.trace(start: transform.position, end: point, mins: player_mins, maxs: player_maxs)

//        if hitResult.fraction == 1 //|| (movement & MOVEMENT_JUMP_THIS_FRAME)
//        {
////            movement |= MOVEMENT_JUMPING
//            ground_normal = nil
//        }
//        else
//        {
////            movement &= ~MOVEMENT_JUMPING
//            ground_normal = hitResult.plane?.normal
//        }
//
//        if let ground_normal = ground_normal
//        {
//            print("ground_normal", ground_normal)
//        }
        
        print("hitResult.fraction", hitResult.fraction)
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
    
    private func slide(gravity: Bool)
    {
//        float end_velocity[3];
//        float planes[MAX_CLIP_PLANES][3];
//        int n_planes;
//        float time_left;
//        int n_bumps;
//        float end[3];
//
        var end_velocity: float3 = .zero
        
        var n_planes: Int = 0
        let time_left = GameTime.deltaTime

        if gravity
        {
            end_velocity = velocity
            end_velocity.z -= MovementConstants.sv_gravity * GameTime.deltaTime

            /* slide against floor */
            if let ground_normal = ground_normal
            {
                velocity = clip_velocity(velocity, normal: ground_normal, overbounce: OVERCLIP)
            }
        }
//
//        if (ground_normal) {
//            cpy3(planes[n_planes], ground_normal);
//            ++n_planes;
//        }
//
//        cpy3(planes[n_planes], velocity);
//        nrm3(planes[n_planes]);
//        ++n_planes;
//
//        for (n_bumps = 0; n_bumps < 4; ++n_bumps)
//        {
//            struct trace_work work;
//            int i;
//
//            /* calculate future position and attempt the move */
//            cpy3(end, velocity);
//            mul3_scalar(end, time_left);
//            add3(end, camera_pos);
//            trace(&work, camera_pos, end, player_mins, player_maxs);
//
//            if (work.frac > 0) {
//                cpy3(camera_pos, work.endpos);
//            }
//
//            /* if nothing blocked us we are done */
//            if (work.frac == 1) {
//                break;
//            }
//
//            time_left -= time_left * work.frac;
//
//            if (n_planes >= MAX_CLIP_PLANES) {
//                clr3(velocity);
//                return 1;
//            }
//
//            /*
//             * if it's a plane we hit before, nudge velocity along it
//             * to prevent epsilon issues and dont re-test it
//             */
//
//            for (i = 0; i < n_planes; ++i)
//            {
//                if (dot3(work.plane->normal, planes[i]) > 0.99) {
//                    add3(velocity, work.plane->normal);
//                    break;
//                }
//            }
//
//            if (i < n_planes) {
//                continue;
//            }
//
//            /*
//             * entirely new plane, add it and clip velocity against all
//             * planes that the move interacts with
//             */
//
//            cpy3(planes[n_planes], work.plane->normal);
//            ++n_planes;
//
//            for (i = 0; i < n_planes; ++i)
//            {
//                float clipped[3];
//                float end_clipped[3];
//                int j;
//
//                if (dot3(velocity, planes[i]) >= 0.1) {
//                    continue;
//                }
//
//                clip_velocity(velocity, planes[i], clipped, OVERCLIP);
//                clip_velocity(end_velocity, planes[i], end_clipped, OVERCLIP);
//
//                /*
//                 * if the clipped move still hits another plane, slide along
//                 * the line where the two planes meet (cross product) with the
//                 * un-clipped velocity
//                 *
//                 * TODO: reduce nesting in here
//                 */
//
//                for (j = 0; j < n_planes; ++j)
//                {
//                    int k;
//                    float dir[3];
//                    float speed;
//
//                    if (j == i) {
//                        continue;
//                    }
//
//                    if (dot3(clipped, planes[j]) >= 0.1) {
//                        continue;
//                    }
//
//                    clip_velocity(clipped, planes[j], clipped, OVERCLIP);
//                    clip_velocity(end_clipped, planes[j], end_clipped,
//                        OVERCLIP);
//
//                    if (dot3(clipped, planes[i]) >= 0) {
//                        /* goes back into the first plane */
//                        continue;
//                    }
//
//                    cross3(planes[i], planes[j], dir);
//                    nrm3(dir);
//
//                    speed = dot3(dir, velocity);
//                    cpy3(clipped, dir);
//                    mul3_scalar(clipped, speed);
//
//                    speed = dot3(dir, end_velocity);
//                    cpy3(end_clipped, dir);
//                    mul3_scalar(end_clipped, speed);
//
//                    /* if we still hit a plane, just give up and dead stop */
//
//                    for (k = 0; k < n_planes; ++k)
//                    {
//                        if (k == j || k == i) {
//                            continue;
//                        }
//
//                        if (dot3(clipped, planes[k]) >= 0.1) {
//                            continue;
//                        }
//
//                        clr3(velocity);
//                        return 1;
//                    }
//                }
//
//                /* resolved all collisions for this move */
//                cpy3(velocity, clipped);
//                cpy3(end_velocity, end_clipped);
//                break;
//            }
//        }
//
//        if (gravity) {
//            cpy3(velocity, end_velocity);
//        }
//
//        return n_bumps != 0;
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
