//
//  BinaryReader.swift
//  Half-Life MDL
//
//  Created by Fedor Artemenkov on 15.02.2022.
//

import Foundation

class BinaryReader
{
    var position: Int
    var data: NSData
    
    init(data: Data)
    {
        position = 0
        self.data = data as NSData
    }
    
    func reset()
    {
        position = 0
    }
    
    func jump(_ addr: Int)
    {
        position = addr
    }
    
    func skip(_ length: Int)
    {
        position += length
    }
    
    func getInt8() -> Int8
    {
        return getNumber()
    }
    
    func getUInt8() -> UInt8
    {
        return getNumber()
    }
    
    func getInt16() -> Int16
    {
        return getNumber()
    }
    
    func getUInt16() -> UInt16
    {
        return getNumber()
    }
    
    func getInt32() -> Int32
    {
        return getNumber()
    }

    func getUInt32() -> UInt32
    {
        return getNumber()
    }
    
    func getFloat32() -> Float32
    {
        return getNumber()
    }
    
    func getASCII(_ length: Int) -> String
    {
        let pointer = (data.bytes + position).bindMemory(to: CChar.self, capacity: length)
        position += length * MemoryLayout<CChar>.size
        
        return String(cString: pointer, encoding: .ascii)!
    }
    
    fileprivate func getNumber<T>() -> T
    {
        let value = (data.bytes + position).bindMemory(to: T.self, capacity: 1).pointee
        position += MemoryLayout<T>.size
        
        return value
    }
    
    func readItems<T>(offset: Int, count: Int) -> Array<T>
    {
        let pointer = (data.bytes + offset).bindMemory(to: T.self, capacity: count)
        let buffer = UnsafeBufferPointer(start: pointer, count: count)
        
        return Array(buffer)
    }
    
    func readItems<T>(offset: Int32, count: Int32) -> Array<T>
    {
        return readItems(offset: Int(offset), count: Int(count))
    }
}

