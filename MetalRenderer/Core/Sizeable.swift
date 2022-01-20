//
//  Sizeable.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 13.01.2022.
//

import Foundation

protocol sizeable
{
    static func size(_ count: Int) -> Int
    static func stride(_ count: Int) -> Int
}

extension sizeable
{
    static var size: Int
    {
        MemoryLayout<Self>.size
    }
    
    static var stride: Int
    {
        MemoryLayout<Self>.stride
    }
    
    static func size(_ count: Int) -> Int
    {
        MemoryLayout<Self>.size * count
    }
    
    static func stride(_ count: Int) -> Int
    {
        MemoryLayout<Self>.stride * count
    }
}

extension UInt32: sizeable { }
extension Int32: sizeable { }
extension Float: sizeable { }
extension SIMD2: sizeable { }
extension SIMD3: sizeable { }
extension SIMD4: sizeable { }

//extension matrix_float4x4: sizeable { }
