//
//  SkeletalMesh.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 15.02.2022.
//

import MetalKit
import GoldSrcMDL

class SkeletalMesh
{
    private static var cache: [URL: ValveModel] = [:]
    
    private var meshes: [SkeletalMeshData] = []
    //private var textures: [MTLTexture] = []
    
    private var cur_frame: Int = 0
    private var cur_frame_time: Float = 0.0
    private var frames: [[matrix_float4x4]]
    
    private var cur_anim_duration: Float = 1.0
    
    private var sequences: [Sequence] = []
    
    var sequenceName: String = "idle" {
        didSet {
            initSequence()
        }
    }
    
    init?(name: String, ext: String)
    {
        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else { return nil }
        
        let model: ValveModel
        
        if let mdl = SkeletalMesh.cache[url]
        {
            model = mdl
        }
        else if let data = try? Data(contentsOf: url)
        {
            model = GoldSrcMDL(data: data).valveModel
            SkeletalMesh.cache[url] = model
        }
        else
        {
            return nil
        }
        
        let assetURL = Bundle.main.url(forResource: "dev_256", withExtension: "jpeg")!
        let devTexture = TextureManager.shared.getTexture(url: assetURL, origin: .topLeft)!
        
        let textures = model.textures.map {
            TextureManager.shared.createTexture($0.name, bytes: $0.data, width: $0.width, height: $0.height)
        }
        
        for mdlMesh in model.meshes
        {
            let vertices = mdlMesh.vertexBuffer.map {
                SkeletalMeshVertex(position: $0.position, texCoord: $0.texCoord, boneIndex: uint($0.boneIndex))
            }
            
            let indices = mdlMesh.indexBuffer.map( { UInt32($0) } )
            
            let vertexBuffer = Engine.device.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<SkeletalMeshVertex>.stride, options: [])
            let indexBuffer = Engine.device.makeBuffer(bytes: indices, length: indices.count * MemoryLayout<UInt32>.stride, options: [])
            
            var texture = devTexture
            
            if mdlMesh.textureIndex != -1, mdlMesh.textureIndex < textures.count
            {
                texture = textures[mdlMesh.textureIndex]
            }
            
            let mesh = SkeletalMeshData(texture: texture,
                                        vertexBuffer: vertexBuffer!,
                                        indexBuffer: indexBuffer!,
                                        indexCount: indices.count)
            
            meshes.append(mesh)
        }
        
        sequences = model.sequences
        
        frames = []
        initSequence()
    }
    
    private func initSequence()
    {
        let seq = sequences.first(where: { $0.name == sequenceName }) ?? sequences.first!

        frames = seq.frames.map { $0.bonetransforms }
        cur_frame = 0
        
        cur_frame_time = 0.0
        cur_anim_duration = Float(seq.frames.count) / seq.fps
    }
    
    func renderWithEncoder(_ encoder: MTLRenderCommandEncoder)
    {
        var bonetransforms = frames[cur_frame]
        
        let length = float4x4.stride * bonetransforms.count
        encoder.setVertexBytes(&bonetransforms, length: length, index: 3)
        
        for mesh in meshes
        {
            encoder.setVertexBuffer(mesh.vertexBuffer, offset: 0, index: 0)
            encoder.setFragmentTexture(mesh.texture, index: 0)
            
            encoder.drawIndexedPrimitives(type: .triangle,
                                          indexCount: mesh.indexCount,
                                          indexType: .uint32,
                                          indexBuffer: mesh.indexBuffer,
                                          indexBufferOffset: 0)
        }
        
        cur_frame_time += GameTime.deltaTime
        
        if cur_frame_time >= cur_anim_duration
        {
            cur_frame_time = 0
        }
        
        cur_frame = Int( Float(frames.count) * (cur_frame_time / cur_anim_duration) )
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

private struct SkeletalMeshData
{
    let texture: MTLTexture!
    let vertexBuffer: MTLBuffer
    let indexBuffer: MTLBuffer
    let indexCount: Int
}

private struct SkeletalMeshVertex: sizeable
{
    let position: float3
    let texCoord: float2
    let boneIndex: uint
}
