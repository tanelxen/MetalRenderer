//
//  ModelMesh.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 13.01.2022.
//

import MetalKit

class ModelMesh: Mesh
{
    var vertexBuffer: MTLBuffer!
    var transform: matrix_float4x4 = matrix_identity_float4x4 {
        didSet {
            modelConstants.modelMatrix = transform
        }
    }
    
    var material = Material()
    
    private var modelConstants = ModelConstants()
    
//    private var _instanceCount: Int = 1
    private var meshes: [MTKMesh] = []
    
    init(modelName: String)
    {
        load(modelName: modelName)
    }
    
    func load(modelName: String)
    {
        let descriptor = MTKModelIOVertexDescriptorFromMetal(VertexDescriptorLibrary.descriptor(.basic))

        (descriptor.attributes[0] as! MDLVertexAttribute).name = MDLVertexAttributePosition
        (descriptor.attributes[1] as! MDLVertexAttribute).name = MDLVertexAttributeNormal
        (descriptor.attributes[2] as! MDLVertexAttribute).name = MDLVertexAttributeTextureCoordinate
        
        guard let assetURL = Bundle.main.url(forResource: modelName, withExtension: "obj") else {
            fatalError("Asset \(modelName) does not exist.")
        }
        
        let bufferAllocator = MTKMeshBufferAllocator(device: Engine.device)
        
        let asset: MDLAsset = MDLAsset(url: assetURL, vertexDescriptor: descriptor, bufferAllocator: bufferAllocator)
        
        if let meshes = try? MTKMesh.newMeshes(asset: asset, device: Engine.device).metalKitMeshes
        {
            self.meshes = meshes
        }
        else
        {
            print("ERROR::LOADING_MESH::__\(modelName)")
        }
    }
    
//    func setInstanceCount(_ count: Int)
//    {
//        self._instanceCount = count
//    }
    
    func drawPrimitives(with encoder: MTLRenderCommandEncoder?)
    {
        for mesh in meshes
        {
            for vertexBuffer in mesh.vertexBuffers
            {
                encoder?.setVertexBuffer(vertexBuffer.buffer, offset: vertexBuffer.offset, index: 0)
                
                for submesh in mesh.submeshes
                {
                    encoder?.drawIndexedPrimitives(type: submesh.primitiveType,
                                                   indexCount: submesh.indexCount,
                                                   indexType: submesh.indexType,
                                                   indexBuffer: submesh.indexBuffer.buffer,
                                                   indexBufferOffset: submesh.indexBuffer.offset)
                }
            }
        }
    }
}

extension ModelMesh: Renderable
{
    func doRender(with encoder: MTLRenderCommandEncoder?)
    {
        encoder?.pushDebugGroup("ModelMesh")
        
        encoder?.setDepthStencilState(DepthStencilStateLibrary[.less])
        
        // Устанавливаем матрицу трансформаций объекта
        encoder?.setVertexBytes(&modelConstants, length: ModelConstants.stride, index: 2)
        
        material.apply(to: encoder)
        
        drawPrimitives(with: encoder)
        
        encoder?.popDebugGroup()
    }
}
