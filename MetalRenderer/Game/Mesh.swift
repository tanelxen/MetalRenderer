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
    
    var boundingBox: MDLAxisAlignedBoundingBox!
    
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
        (descriptor.attributes[1] as! MDLVertexAttribute).name = MDLVertexAttributeTextureCoordinate
        (descriptor.attributes[2] as! MDLVertexAttribute).name = MDLVertexAttributeNormal
        (descriptor.attributes[3] as! MDLVertexAttribute).name = MDLVertexAttributeTangent
        
        let bufferAllocator = MTKMeshBufferAllocator(device: Engine.device)
        
        let asset: MDLAsset = MDLAsset(url: assetURL,
                                       vertexDescriptor: descriptor,
                                       bufferAllocator: bufferAllocator,
                                       preserveTopology: true,
                                       error: nil)
        
        asset.loadTextures()
        
        var mtkMeshes: [MTKMesh] = []
        var mdlMeshes: [MDLMesh] = []
        
        do
        {
            (mdlMeshes, mtkMeshes) = try MTKMesh.newMeshes(asset: asset, device: Engine.device)
        }
        catch
        {
            print("ERROR::LOADING_MESH::__\(modelName)__::\(error)")
        }
        
        for mdlMesh in mdlMeshes
        {
            mdlMesh.addTangentBasis(
                forTextureCoordinateAttributeNamed: MDLVertexAttributeTextureCoordinate,
                normalAttributeNamed: MDLVertexAttributeNormal,
                tangentAttributeNamed: MDLVertexAttributeTangent)
            
            mdlMesh.vertexDescriptor = descriptor
        }
        
        let mtkMesh = mtkMeshes[0]
        let mdlMesh = mdlMeshes[0]
        
        self._vertexBuffer = mtkMesh.vertexBuffers[0].buffer
        self._vertexCount = mtkMesh.vertexCount
        
        for i in 0 ..< mtkMesh.submeshes.count
        {
            let mtkSubmesh = mtkMesh.submeshes[i]
            let mdlSubmesh = mdlMesh.submeshes![i] as! MDLSubmesh
            
            let submesh = Submesh(mtkSubmesh: mtkSubmesh, mdlMaterial: mdlSubmesh.material)
            addSubmesh(submesh)
        }
        
        boundingBox = mdlMesh.boundingBox
    }
    
    func setInstanceCount(_ count: Int)
    {
        self._instanceCount = count
    }
    
    func addSubmesh(_ submesh: Submesh)
    {
        _submeshes.append(submesh)
    }
    
    func addVertex(position: float3, uv: float2 = float2(0, 0), normal: float3 = float3(0, 1, 0), tangent: float3 = float3(1, 0, 0))
    {
        _vertices.append(Vertex(position: position, uv: uv, normal: normal, tangent: tangent))
    }
    
    func drawPrimitives(with encoder: MTLRenderCommandEncoder)
    {
        guard _vertexBuffer != nil else { return }
        
        encoder.setVertexBuffer(_vertexBuffer, offset: 0, index: 0)
        
        if _submeshes.count > 0
        {
            for submesh in _submeshes
            {
                submesh._material.apply(to: encoder)
                
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
            material.apply(to: encoder)
            
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
    
    private (set) var _material = Material()
    private var _baseColorTexture: MTLTexture!
    
    init(indices: [UInt32])
    {
        self.indices = indices
        self.indexCount = indices.count
        
        createIndexBuffer()
    }
    
    init(mtkSubmesh: MTKSubmesh, mdlMaterial: MDLMaterial?)
    {
        indexBuffer = mtkSubmesh.indexBuffer.buffer
        indexBufferOffset = mtkSubmesh.indexBuffer.offset
        indexCount = mtkSubmesh.indexCount
        indexType = mtkSubmesh.indexType
        primitiveType = mtkSubmesh.primitiveType
        
        if let mdlMaterial = mdlMaterial
        {
            loadTexture(for: mdlMaterial)
            createMaterial(from: mdlMaterial)
        }
    }
    
    private func loadTexture(for mdlMaterial: MDLMaterial)
    {
        if let base = texture(for: .baseColor, in: mdlMaterial, textureOrigin: .bottomLeft)
        {
            _material.setBaseColorMap(base)
            _material.materialConstants.useBaseColorMap = true
        }
        
        if let normal = texture(for: .tangentSpaceNormal, in: mdlMaterial, textureOrigin: .bottomLeft)
        {
            _material.setNormalMap(normal)
            _material.materialConstants.useNormalMap = true
        }
    }
    
    private func texture(for semantic: MDLMaterialSemantic, in material: MDLMaterial?, textureOrigin: MTKTextureLoader.Origin) -> MTLTexture?
    {
        let textureLoader = MTKTextureLoader(device: Engine.device)
        
        guard let materialProperty = material?.property(with: semantic) else { return nil }
        guard let sourceTexture = materialProperty.textureSamplerValue?.texture else { return nil }
        
        let options: [MTKTextureLoader.Option : Any] = [
            MTKTextureLoader.Option.origin : textureOrigin as Any,
            MTKTextureLoader.Option.generateMipmaps : true
        ]
        
        return try? textureLoader.newTexture(texture: sourceTexture, options: options)
    }
     
    
    private func createMaterial(from mdlMaterial: MDLMaterial)
    {
        if let color = mdlMaterial.property(with: .baseColor)?.float3Value
        {
            _material.materialConstants.color = float4(color, 1.0)
        }

        if let ambient = mdlMaterial.property(with: .emission)?.float3Value
        {
            _material.materialConstants.ambient = ambient
        }
        
        if let diffuse = mdlMaterial.property(with: .baseColor)?.float3Value
        {
            _material.materialConstants.diffuse = diffuse
        }
        
        if let specular = mdlMaterial.property(with: .specular)?.float3Value
        {
            _material.materialConstants.specular = specular
        }
        
        if let shininess = mdlMaterial.property(with: .specularExponent)?.floatValue
        {
            _material.materialConstants.shininess = shininess
        }
        
        _material.materialConstants.isLit = true
    }
    
    private func createIndexBuffer()
    {
        guard indices.isEmpty else { return }
        
        indexBuffer = Engine.device.makeBuffer(bytes: indices, length: UInt32.stride(indices.count), options: [])
    }
}
