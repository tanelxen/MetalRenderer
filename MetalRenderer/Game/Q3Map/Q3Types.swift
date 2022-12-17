//
//  Q3Types.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 07.02.2022.
//

import Foundation
import simd

struct Q3Vertex
{
    var position: float4 = float4(0, 0, 0, 0)
    var normal: float4 = float4(0, 0, 0, 0)
    var color: float4 = float4(0, 0, 0, 0)
    var textureCoord: float2 = float2(0, 0)
    var lightmapCoord: float2 = float2(0, 0)
}

func +(left: Q3Vertex, right: Q3Vertex) -> Q3Vertex
{
    return Q3Vertex(
        position: left.position + right.position,
        normal: left.normal + right.normal,
        color: left.color + right.color,
        textureCoord: left.textureCoord + right.textureCoord,
        lightmapCoord: left.lightmapCoord + right.lightmapCoord
    )
}

func *(left: Q3Vertex, right: Float) -> Q3Vertex
{
    return Q3Vertex(
        position: left.position * right,
        normal: left.normal * right,
        color: left.color * right,
        textureCoord: left.textureCoord * right,
        lightmapCoord: left.lightmapCoord * right
    )
}

typealias Q3Lightmap = Array<(UInt8, UInt8, UInt8, UInt8)>

enum Q3FaceType: Int
{
    case polygon = 1
    case patch = 2
    case mesh = 3
    case billboard = 4
}

struct Q3Texture
{
    let texureName: String
    let surfaceFlags: Int32
    let contentFlags: Int32
}

struct Q3Face
{
    let textureName: String
    let lightmapIndex: Int
    let vertexIndices: Array<UInt32>
}

struct Q3Plane
{
    let normal: float3
    let distance: Float
}

struct Q3Brush
{
    let brushside: Int
    let numBrushsides: Int
    let texture: Int
}

struct Q3BrushSide
{
    let plane: Int
    let texture: Int
}

struct Q3Node
{
    let plane: Int
    let child: [Int]    // front, back
    let mins: float3
    let maxs: float3
}

struct Q3Leaf
{
    let cluster: Int
    let area: Int
    let mins: float3
    let maxs: float3
    let leafface: Int
    let n_leaffaces: Int
    let leafbrush: Int
    let n_leafbrushes: Int
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

// plane types are used to speed some tests
// 0-2 are axial planes
enum PlaneType: Int
{
    case PLANE_X = 0
    case PLANE_Y = 1
    case PLANE_Z = 2
    case PLANE_NON_AXIAL = 3
    
    init(normal: float3)
    {
        if normal.x == 1.0
        {
            self = .PLANE_X
        }
        else if normal.y == 1.0
        {
            self = .PLANE_Y
        }
        else if normal.z == 1.0
        {
            self = .PLANE_Z
        }
        else
        {
            self = .PLANE_NON_AXIAL
        }
    }
}
