//
//  ModelMesh.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 13.01.2022.
//

import MetalKit

class Mesh
{
    private var _vertices: [Vertex] = []
    private var _vertexCount: Int = 0
    private var _vertexBuffer: MTLBuffer! = nil
    private var _instanceCount: Int = 1
    private var _submeshes: [Submesh] = []
    
    var transform: matrix_float4x4 = matrix_identity_float4x4 {
        didSet {
            modelConstants.modelMatrix = transform
        }
    }
    
    var material = Material()
    
    private var modelConstants = ModelConstants()
    
    init()
    {
        createMesh()
        createBuffer()
    }
    
    init(modelName: String)
    {
        createMeshFromModel(modelName)
    }
    
    func createMesh() { }
    
    private func createBuffer()
    {
        if(_vertices.count > 0)
        {
            _vertexBuffer = Engine.device.makeBuffer(bytes: _vertices,
                                                     length: Vertex.stride(_vertices.count),
                                                     options: [])
        }
    }
    
    private func createMeshFromModel(_ modelName: String, ext: String = "obj")
    {
        guard let assetURL = Bundle.main.url(forResource: modelName, withExtension: ext) else {
            fatalError("Asset \(modelName) does not exist.")
        }
        
        let descriptor = MTKModelIOVertexDescriptorFromMetal(VertexDescriptorLibrary.descriptor(.basic))
        
        (descriptor.attributes[0] as! MDLVertexAttribute).name = MDLVertexAttributePosition
        (descriptor.attributes[1] as! MDLVertexAttribute).name = MDLVertexAttributeNormal
        (descriptor.attributes[2] as! MDLVertexAttribute).name = MDLVertexAttributeTextureCoordinate
        
        let bufferAllocator = MTKMeshBufferAllocator(device: Engine.device)
        
        let asset: MDLAsset = MDLAsset(url: assetURL,
                                       vertexDescriptor: descriptor,
                                       bufferAllocator: bufferAllocator,
                                       preserveTopology: true,
                                       error: nil)
        
        var mtkMeshes: [MTKMesh] = []
        
        do
        {
            mtkMeshes = try MTKMesh.newMeshes(asset: asset, device: Engine.device).metalKitMeshes
        }
        catch
        {
            print("ERROR::LOADING_MESH::__\(modelName)__::\(error)")
        }
        
        let mtkMesh = mtkMeshes[0]
        
        self._vertexBuffer = mtkMesh.vertexBuffers[0].buffer
        self._vertexCount = mtkMesh.vertexCount
        
        for i in 0 ..< mtkMesh.submeshes.count
        {
            let mtkSubmesh = mtkMesh.submeshes[i]
            let submesh = Submesh(mtkSubmesh: mtkSubmesh)
            addSubmesh(submesh)
        }
    }
    
    func setInstanceCount(_ count: Int)
    {
        self._instanceCount = count
    }
    
    func addSubmesh(_ submesh: Submesh)
    {
        _submeshes.append(submesh)
    }
    
    func addVertex(position: float3, normal: float3 = float3(0, 1, 0), uv: float2 = float2(0, 0))
    {
        _vertices.append(Vertex(position: position, normal: normal, uv: uv))
    }
    
    func drawPrimitives(with encoder: MTLRenderCommandEncoder)
    {
        guard _vertexBuffer != nil else { return }
        
        encoder.setVertexBuffer(_vertexBuffer, offset: 0, index: 0)
        
        if _submeshes.count > 0
        {
            for submesh in _submeshes
            {
                encoder.drawIndexedPrimitives(type: submesh.primitiveType,
                                              indexCount: submesh.indexCount,
                                              indexType: submesh.indexType,
                                              indexBuffer: submesh.indexBuffer,
                                              indexBufferOffset: submesh.indexBufferOffset,
                                              instanceCount: _instanceCount)
            }
        }
        else
        {
            encoder.drawPrimitives(type: .triangle,
                                   vertexStart: 0,
                                   vertexCount: _vertices.count,
                                   instanceCount: _instanceCount)
        }
    }
}

extension Mesh: Renderable
{
    func doRender(with encoder: MTLRenderCommandEncoder?)
    {
        encoder?.pushDebugGroup("Mesh")
        
        encoder?.setDepthStencilState(DepthStencilStateLibrary[.less])
        
        // Устанавливаем матрицу трансформаций объекта
        encoder?.setVertexBytes(&modelConstants, length: ModelConstants.stride, index: 2)
        
        material.apply(to: encoder)
        
        drawPrimitives(with: encoder!)
        
        encoder?.popDebugGroup()
    }
}

// Index Information
class Submesh
{
    private var indices: [UInt32] = []
    
    private (set) var indexCount: Int = 0
    private (set) var indexBuffer: MTLBuffer!
    private (set) var primitiveType: MTLPrimitiveType = .triangle
    private (set) var indexType: MTLIndexType = .uint32
    private (set) var indexBufferOffset: Int = 0
    
    init(indices: [UInt32])
    {
        self.indices = indices
        self.indexCount = indices.count
        
        createIndexBuffer()
    }
    
    init(mtkSubmesh: MTKSubmesh)
    {
        indexBuffer = mtkSubmesh.indexBuffer.buffer
        indexBufferOffset = mtkSubmesh.indexBuffer.offset
        indexCount = mtkSubmesh.indexCount
        indexType = mtkSubmesh.indexType
        primitiveType = mtkSubmesh.primitiveType
    }
    
    private func createIndexBuffer()
    {
        guard indices.isEmpty else { return }
        
        indexBuffer = Engine.device.makeBuffer(bytes: indices, length: UInt32.stride(indices.count), options: [])
    }
}
