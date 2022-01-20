//
//  SimpleQuad.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 13.01.2022.
//

import MetalKit

class SimpleQuad
{
    var vertexBuffer: MTLBuffer!
    
    private struct Vertex
    {
        let position: float3
        let texCoord: float2
    }
    
    private let vertices: [Float] = [
        -1, 1, 0, 0, 0,     //Top Left
        -1,-1, 0, 0, 1,     //Bottom Left
         1,-1, 0, 1, 1,     //Bottom Right
        
        -1, 1, 0, 0, 0,     //Top Left
         1,-1, 0, 1, 1,     //Bottom Right
         1, 1, 0, 1, 0      //Top Right
    ]
    
    private (set) var kernel: [float3] = []
    private (set) var kernelTexture: MTLTexture?
    private (set) var noiseTexture: MTLTexture?
    
    init()
    {
        vertexBuffer = Engine.device.makeBuffer(bytes: vertices, length: MemoryLayout<Float>.stride * vertices.count, options: [])
        
        kernel = makeKernel(size: 64)
        makeKernelTexture(kernelSize: 8)
        makeNoiseTexture(width: 4, height: 4)
    }
    
    func drawPrimitives(with encoder: MTLRenderCommandEncoder?)
    {
        var projection = DebugCamera.shared.projectionMatrix
        
        encoder?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        encoder?.setFragmentBytes(&projection, length: MemoryLayout<matrix_float4x4>.stride, index: 1)
        
        encoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertices.count)
    }
    
    private func makeKernelTexture(kernelSize: Int)
    {
        var ssaoKernel: [float4] = []
        
        let num = kernelSize * kernelSize
        
        func lerp(_ a: Float, _ b: Float, _ f: Float) -> Float
        {
            return a + f * (b - a)
        }

        for i in 0..<num
        {
            let x: Float = Float.random(in: 0...1)
            let y: Float = Float.random(in: 0...1)
            let z: Float = Float.random(in: 0...1)

            var sample = float4(x * 2.0 - 1.0, y * 2.0 - 1.0, z, 1.0)
            sample = normalize(sample)
            sample *= Float.random(in: 0...1)

            var scale: Float = Float(i) / Float(num)
            scale = lerp(0.1, 1.0, scale * scale)
            sample *= scale

            ssaoKernel.append(sample)
        }
        
        kernelTexture = createTexture(data: ssaoKernel, width: kernelSize, height: kernelSize)
    }
    
    private func makeKernel(size: Int) -> [float3]
    {
        var ssaoKernel: [float3] = []
        
        func lerp(_ a: Float, _ b: Float, _ f: Float) -> Float
        {
            return a + f * (b - a)
        }

        for i in 0..<size
        {
            let x: Float = Float.random(in: 0...1)
            let y: Float = Float.random(in: 0...1)
            let z: Float = Float.random(in: 0...1)

            var sample = float3(x * 2.0 - 1.0, y * 2.0 - 1.0, z)
            sample = normalize(sample)
            sample *= Float.random(in: 0...1)

            var scale: Float = Float(i) / Float(size)
            scale = lerp(0.1, 1.0, scale * scale)
            sample *= scale

            ssaoKernel.append(sample)
        }
        
        return ssaoKernel
    }
    
    private func makeNoiseTexture(width: Int, height: Int)
    {
        var ssaoNoise: [float4] = []
        
        let num = width * height
        
        for _ in 0..<num
        {
            let x: Float = Float.random(in: 0...1)
            let y: Float = Float.random(in: 0...1)

            let sample = float4(x * 2.0 - 1.0, y * 2.0 - 1.0, 0.0, 1.0)
            
            ssaoNoise.append(sample)
        }
        
        noiseTexture = createTexture(data: ssaoNoise, width: width, height: height)
    }
    
    private func createTexture(data: [float4], width: Int, height: Int) -> MTLTexture?
    {
        let pointer: UnsafeMutablePointer<float4> = UnsafeMutablePointer(mutating: data)

        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba16Float, width: width, height: height, mipmapped: false)

//        textureDescriptor.usage = [.shaderWrite, .shaderRead]

        guard let texture: MTLTexture = Engine.device.makeTexture(descriptor: textureDescriptor) else
        {
            return nil
        }

        let region = MTLRegion.init(origin: MTLOrigin.init(x: 0, y: 0, z: 0), size: MTLSize.init(width: texture.width, height: texture.height, depth: 1))

        texture.replace(region: region, mipmapLevel: 0, withBytes: pointer, bytesPerRow: width * 4 * 2)

        return texture
    }
    
    
//    // generate sample kernel
//    // ----------------------
//    std::uniform_real_distribution<GLfloat> randomFloats(0.0, 1.0); // generates random floats between 0.0 and 1.0
//    std::default_random_engine generator;
//    std::vector<glm::vec3> ssaoKernel;
//    for (unsigned int i = 0; i < 64; ++i)
//    {
//        glm::vec3 sample(randomFloats(generator) * 2.0 - 1.0, randomFloats(generator) * 2.0 - 1.0, randomFloats(generator));
//        sample = glm::normalize(sample);
//        sample *= randomFloats(generator);
//        float scale = float(i) / 64.0f;
//
//        // scale samples s.t. they're more aligned to center of kernel
//        scale = lerp(0.1f, 1.0f, scale * scale);
//        sample *= scale;
//        ssaoKernel.push_back(sample);
//    }
//
//    // generate noise texture
//    // ----------------------
//    std::vector<glm::vec3> ssaoNoise;
//    for (unsigned int i = 0; i < 16; i++)
//    {
//        glm::vec3 noise(randomFloats(generator) * 2.0 - 1.0, randomFloats(generator) * 2.0 - 1.0, 0.0f); // rotate around z-axis (in tangent space)
//        ssaoNoise.push_back(noise);
//    }
}
