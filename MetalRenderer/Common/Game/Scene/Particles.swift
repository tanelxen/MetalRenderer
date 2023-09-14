//
//  Particles.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 14.09.2023.
//

import Metal
import simd

private let sv_gravity: Float = 800.0

final class Particles
{
    private class Particle
    {
        var transform: Transform = Transform()
        var velocity: float3 = .zero
        var lifespan: Float = 100.0
        let color: float3 = float3(1, 0, 0)
    }
    
    private var particles: [Particle] = []
    
    private let cubeShape = CubeShape(mins: .zero, maxs: .one)
    
    static let shared = Particles()
    
    private let maxCount = 1000
    
    private var constantsBuffer: MTLBuffer!
    private var texture: MTLTexture!
    
    init()
    {
        constantsBuffer = Engine.device.makeBuffer(length: float3.stride(maxCount), options: [])
        texture = TextureManager.shared.getTexture(for: "Assets/bubble.tga")
    }
    
    func addParticle(origin: float3, dir: float3)
    {
        let particle = Particle()
        particle.transform.position = origin
        particle.transform.scale = float3(repeating: 1)
        
        particle.velocity = dir * 6
        
        particles.append(particle)
    }
    
    func addParticles(origin: float3, dir: float3, count: Int)
    {
        for _ in 0 ..< count
        {
            let x = Float.random(in: -1...1)
            let y = Float.random(in: -1...1)
            let z = Float.random(in: -1...1)
            
            let scale: Float = 0.8
            let randDir = normalize(dir + float3(x, y, z) * scale)

            addParticle(origin: origin, dir: randDir)
        }
    }
    
    func update()
    {
        let dt = GameTime.deltaTime
        
        particles.removeAll(where: { $0.lifespan <= 0 })

        for particle in particles
        {
            guard particle.lifespan > 0 else { continue }

            particle.lifespan -= dt

            if particle.lifespan <= 0
            {
                continue
            }
            
//            particle.velocity.z -= sv_gravity * dt

            particle.transform.position += particle.velocity * dt
        }
    }
    
    func render(with encoder: MTLRenderCommandEncoder?)
    {
        guard !particles.isEmpty else { return }
        
        var pointer = constantsBuffer.contents().bindMemory(to: float3.self, capacity: maxCount)
        
        var count: Int = 0
        
        for particle in particles
        {
            guard particle.lifespan > 0 else { continue }
            
//            var modelConstants = ModelConstants()
//            modelConstants.color = particle.color
//
//            particle.transform.updateModelMatrix()
//            modelConstants.modelMatrix = particle.transform.matrix

            pointer.pointee = particle.transform.position
            pointer = pointer.advanced(by: 1)
            
            count += 1
        }
        
        if count > 0
        {
            encoder?.setVertexBuffer(constantsBuffer, offset: 0, index: 0)
            encoder?.setFragmentTexture(texture, index: 0)
            encoder?.drawPrimitives(type: .point, vertexStart: 0, vertexCount: count)
        }
    }
}

//private func randomVectorInCone(direction: simd_float3, angle: Float) -> simd_float3
//{
//    // Генерируем случайные угол и радиус в полярных координатах
//    let randomAngle = Float.random(in: 0...angle)
//    let randomRadius = Float.random(in: 0...1)
//
//    // Преобразуем полярные координаты в декартовы
//    let x = randomRadius * sin(randomAngle)
//    let y = randomRadius * cos(randomAngle)
//
//    // Генерируем случайный вектор внутри сферы
//    var randomSphereVector = simd_float3(x, y, Float.random(in: 0...1))
//    randomSphereVector = normalize(randomSphereVector)
//
//    // Поворачиваем вектор, чтобы он соответствовал направлению конуса
//    var axis = cross(direction, simd_float3(0, 0, 1))
//    axis = normalize(axis)
//
//    let rotation = simd_quatf(angle: angle, axis: axis)
//    let rotatedVector = rotation.act(randomSphereVector)
//
//    return normalize(rotatedVector)
//}
