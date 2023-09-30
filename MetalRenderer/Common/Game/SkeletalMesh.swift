//
//  SkeletalMesh.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 15.02.2022.
//

import MetalKit

final class SkeletalMesh
{
    private var name = ""
    private static var cache: [String: SkeletalMeshAsset] = [:]
    
    private var vertexBuffer: MTLBuffer?
    private var indexBuffer: MTLBuffer?
    private var animBuffer: MTLBuffer?
    
    private var surfaces: [SkeletalMeshSurface] = []
    private var bones: [Int] = [] // [parentIndex, parentIndex, ...]
    
    private var cur_frame: Float = 0
    private var cur_frame_time: Float = 0.0
    
    private (set) var cur_anim_duration: Float = 1.0
    
    private var sequences: [String: SkeletalMeshAsset.Sequence] = [:]
    
    private (set) var groundSpeed: Float = 0
    
    var sequenceName: String? {
        didSet {
            framesCount = 0
            
            if let named = sequenceName
            {
                initSequence(named: named)
            }
        }
    }
    
    private var framesCount = 0
    
    init?(name: String)
    {
        self.name = name
        let asset: SkeletalMeshAsset
        
        let baseDir = UserDefaults.standard.url(forKey: "workingDir")!
        let assetsDir = baseDir.appendingPathComponent("Assets")
        let packageURL = assetsDir.appendingPathComponent(name)
        
        if let cached = Self.cache[name]
        {
            asset = cached
        }
        else if let serialized = SkeletalMeshAsset.load(with: packageURL)
        {
            asset = serialized
            Self.cache[name] = asset
        }
        else
        {
            return nil
        }
        
        loadFromAsset(asset, folder: packageURL)
    }
    
    private func loadFromAsset(_ asset: SkeletalMeshAsset, folder: URL)
    {
        let textures = asset.textures.map {
            let url = folder.appendingPathComponent("\($0).png")
            return TextureManager.shared.getTexture(url: url)
        }
        
        let vertices = asset.vertices.map {
            SkeletalMeshVertex(position: $0.position, texCoord: $0.texCoord, boneIndex: UInt32($0.boneIndex))
        }
        
        vertexBuffer = Engine.device.makeBuffer(bytes: vertices,
                                                length: vertices.count * MemoryLayout<SkeletalMeshVertex>.stride,
                                                options: [])
        
        indexBuffer = Engine.device.makeBuffer(bytes: asset.indices,
                                               length: asset.indices.count * MemoryLayout<UInt32>.stride,
                                               options: [])
        
        let animBufferSize = asset.bones.count * MemoryLayout<float4x4>.stride
        animBuffer = Engine.device.makeBuffer(length: animBufferSize, options: [])
        
        for surface in asset.surfaces
        {
            var texture = TextureManager.shared.devTexture
            
            if surface.textureIndex != -1, surface.textureIndex < textures.count
            {
                texture = textures[surface.textureIndex]
            }
            
            let mesh = SkeletalMeshSurface(
                texture: texture,
                indexCount: surface.indexCount,
                indexOffset: surface.firstIndex * MemoryLayout<UInt32>.size
            )
            
            surfaces.append(mesh)
        }
        
        sequences = Dictionary(uniqueKeysWithValues: asset.sequences.map{ ($0.name, $0) })
        bones = asset.bones.map { Int($0) }
    }
    
    private func initSequence(named: String)
    {
        guard let seq = sequences[named] else { return }

        cur_frame = 0
        
        cur_frame_time = 0.0
        cur_anim_duration = Float(seq.frames.count) / seq.fps
        
        groundSpeed = seq.groundSpeed
        framesCount = seq.frames.count
    }
    
    private func setPose(named: String, frameIndex: Float)
    {
        guard let buffer = self.animBuffer else { return }
        guard let seq = sequences[named] else { return }
        
        let currIndex = Int(floor(frameIndex))
        let nextIndex = currIndex < seq.frames.count - 1 ? currIndex + 1 : 0
        
        let factor = frameIndex - floor(frameIndex)
        
        let curr = seq.frames[currIndex]
        let next = seq.frames[nextIndex]
        
        let pointer = buffer.contents().bindMemory(to: float4x4.self, capacity: bones.count)
        
        for i in 0 ..< bones.count
        {
            let currRotation = anglesToQuaternion(curr.rotationPerBone[i])
            let nextRotation = anglesToQuaternion(next.rotationPerBone[i])
            
            let currPosition = curr.positionPerBone[i]
            let nextPosition = next.positionPerBone[i]
            
            let rotation = currRotation * (1 - factor) + nextRotation * factor
            let position = currPosition * (1 - factor) + nextPosition * factor
            
            var boneMatrix = matrix_float4x4.init(rotation)

            boneMatrix[3].x = position.x
            boneMatrix[3].y = position.y
            boneMatrix[3].z = position.z

            let parentIndex = bones[i]

            if parentIndex == -1
            {
                // Root bone
                pointer.advanced(by: i).pointee = boneMatrix
            }
            else
            {
                let parentMatrix = pointer.advanced(by: parentIndex).pointee
                let result = matrix_multiply(parentMatrix, boneMatrix)

                pointer.advanced(by: i).pointee = result
            }
        }
    }
    
    func renderWithEncoder(_ encoder: MTLRenderCommandEncoder)
    {
        guard let indexBuffer = self.indexBuffer else { return }
        guard framesCount > 0 else { return }
        
        if let pose = sequenceName
        {
            setPose(named: pose, frameIndex: cur_frame)
        }
        
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        encoder.setVertexBuffer(animBuffer, offset: 0, index: 3)
        
        for mesh in surfaces
        {
            encoder.setFragmentTexture(mesh.texture, index: 0)
            
            encoder.drawIndexedPrimitives(type: .triangle,
                                          indexCount: mesh.indexCount,
                                          indexType: .uint32,
                                          indexBuffer: indexBuffer,
                                          indexBufferOffset: mesh.indexOffset)
        }
        
        cur_frame_time += GameTime.deltaTime
        
        if cur_frame_time >= cur_anim_duration
        {
            cur_frame_time = 0
        }
        
        cur_frame = Float(framesCount) * (cur_frame_time / cur_anim_duration)
    }
    
    static func vertexDescriptor() -> MTLVertexDescriptor
    {
        let descriptor = MTLVertexDescriptor()
        var offset: Int = 0
        
        // Position
        descriptor.attributes[0].format = .float3
        descriptor.attributes[0].bufferIndex = 0
        descriptor.attributes[0].offset = offset
        offset += float3.size
        
        // UV
        descriptor.attributes[1].format = .float2
        descriptor.attributes[1].bufferIndex = 0
        descriptor.attributes[1].offset = offset
        offset += float2.size
        
        // Bone Index
        descriptor.attributes[2].format = .uint
        descriptor.attributes[2].bufferIndex = 0
        descriptor.attributes[2].offset = offset
        offset += UInt32.size
        
        descriptor.layouts[0].stride = SkeletalMeshVertex.stride
        
        return descriptor
    }
}

private struct SkeletalMeshSurface
{
    let texture: MTLTexture!
    let indexCount: Int
    let indexOffset: Int
}

private struct SkeletalMeshVertex: sizeable
{
    let position: float3
    let texCoord: float2
    let boneIndex: UInt32
}

private extension SkeletalMesh
{
    func anglesToQuaternion(_ angles: float3) -> simd_quatf
    {
        let pitch = angles[0]
        let roll = angles[1]
        let yaw = angles[2]
    
        // FIXME: rescale the inputs to 1/2 angle
        let cy = cos(yaw * 0.5)
        let sy = sin(yaw * 0.5)
        let cp = cos(roll * 0.5)
        let sp = sin(roll * 0.5)
        let cr = cos(pitch * 0.5)
        let sr = sin(pitch * 0.5)
    
        let vector = simd_float4(
            sr * cp * cy - cr * sp * sy,    // X
            cr * sp * cy + sr * cp * sy,    // Y
            cr * cp * sy - sr * sp * cy,    // Z
            cr * cp * cy + sr * sp * sy     // W
        )
    
        return simd_quatf(vector: vector)
    }
}
