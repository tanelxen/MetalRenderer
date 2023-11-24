//
//  Q3Types.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 07.02.2022.
//

import Foundation
import simd

public typealias float2 = SIMD2<Float>
public typealias float3 = SIMD3<Float>

public struct Q3Vertex
{
    public var position: float3 = .zero
    public var textureCoord: float2 = .zero
    public var lightmapCoord: float2 = .zero
    public var color: float3 = .zero
}

func +(left: Q3Vertex, right: Q3Vertex) -> Q3Vertex
{
    return Q3Vertex(
        position: left.position + right.position,
        textureCoord: left.textureCoord + right.textureCoord,
        lightmapCoord: left.lightmapCoord + right.lightmapCoord
    )
}

func *(left: Q3Vertex, right: Float) -> Q3Vertex
{
    return Q3Vertex(
        position: left.position * right,
        textureCoord: left.textureCoord * right,
        lightmapCoord: left.lightmapCoord * right
    )
}

public typealias Q3Lightmap = Array<(UInt8, UInt8, UInt8, UInt8)>

public enum Q3FaceType: Int
{
    case polygon = 1
    case patch = 2
    case mesh = 3
    case billboard = 4
}

public struct Q3Texture
{
    public let texureName: String
    public let surfaceFlags: Int32
    public let contentFlags: Int32
}

public struct Q3Face
{
    public let textureName: String
    public let lightmapIndex: Int
    public let vertexIndices: Array<UInt32>
    public let type: Q3FaceType
}

public struct Q3Plane
{
    public let normal: float3
    public let distance: Float
}

public struct Q3Brush
{
    public let brushside: Int
    public let numBrushsides: Int
    public let texture: Int
}

public struct Q3BrushSide
{
    public let plane: Int
    public let texture: Int
}

public struct Q3Node
{
    public let plane: Int
    public let child: [Int]    // front, back
    public let mins: float3
    public let maxs: float3
}

public struct Q3Leaf
{
    public let cluster: Int
    public let area: Int
    public let mins: float3
    public let maxs: float3
    public let leafface: Int
    public let n_leaffaces: Int
    public let leafbrush: Int
    public let n_leafbrushes: Int
}

public struct Q3Model
{
    public let mins: float3
    public let maxs: float3
    public let face: Int
    public let n_faces: Int
    public let brush: Int
    public let n_brushes: Int
}

public struct Q3LightProbe
{
    public let ambient: float3      // [r, g, b]
    public let directional: float3  // [r, g, b]
    public let direction: float3    // [x, y, z]
}

enum Lumps: Int
{
    case entities       // Game-related object descriptions.
    case textures       // Surface descriptions.
    case planes         // Planes used by map geometry.
    case nodes          // BSP tree nodes.
    case leafs          // BSP tree leaves.
    case leaffaces      // Lists of face indices, one list per leaf.
    case leafbrushes    // Lists of brush indices, one list per leaf.
    case models         // Descriptions of rigid world geometry in map.
    case brushes        // Convex polyhedra used to describe solid space.
    case brushsides     // Brush surfaces.
    case vertexes       // Vertices used to describe faces.
    case meshverts      // Lists of offsets, one list per mesh.
    case effects        // List of special map effects.
    case faces          // Surface geometry.
    case lightmaps      // Packed lightmap data.
    case lightvols      // Local illumination data.
    case visdata        // Cluster-cluster visibility data.
}

struct Q3DirectoryEntry
{
    var offset: Int32 = 0
    var length: Int32 = 0
}

struct Q3PolygonFace
{
    let indices: Array<UInt32>
    
    init(meshverts: [UInt32], firstVertex: Int, firstMeshvert: Int, meshvertCount: Int)
    {
        let meshvertIndices = firstMeshvert..<(firstMeshvert + meshvertCount)
        indices = meshvertIndices.map { meshverts[$0] + UInt32(firstVertex) }
    }
}

struct Q3PatchFace
{
    var vertices: Array<Q3Vertex> = []
    fileprivate var indices: Array<UInt32> = []
    
    init(vertices: Array<Q3Vertex>, firstVertex: Int, vertexCount: Int, size: (Int, Int))
    {
        let numPatchesX = ((size.0) - 1) / 2
        let numPatchesY = ((size.1) - 1) / 2
        let numPatches = numPatchesX * numPatchesY
        
        for patchNumber in 0 ..< numPatches
        {
            // Find the x & y of this patch in the grid
            let xStep = patchNumber % numPatchesX
            let yStep = patchNumber / numPatchesX
            
            // Initialise the vertex grid
            var vertexGrid: [[Q3Vertex]] = Array(
                repeating: Array(
                    repeating: Q3Vertex(),
                    count: Int(size.1)
                ),
                count: Int(size.0)
            )
            
            var gridX = 0
            var gridY = 0
            
            for index in firstVertex..<(firstVertex + vertexCount)
            {
                // Place the vertices from the face in the vertex grid
                vertexGrid[gridX][gridY] = vertices[index]
                
                gridX += 1
                
                if gridX == Int(size.0) {
                    gridX = 0
                    gridY += 1
                }
            }
            
            let vi = 2 * xStep
            let vj = 2 * yStep
            var controlVertices: [Q3Vertex] = []
            
            for i in 0..<3 {
                for j in 0..<3 {
                    controlVertices.append(vertexGrid[Int(vi + j)][Int(vj + i)])
                }
            }
            
            let bezier = Bezier(controls: controlVertices)
            
            self.indices.append(
                contentsOf: bezier.indices.map { i in i + UInt32(self.vertices.count) }
            )
            
            self.vertices.append(contentsOf: bezier.vertices)
        }
    }
    
    func offsetIndices(_ offset: UInt32) -> Array<UInt32>
    {
        return self.indices.map { $0 + offset }
    }
}
