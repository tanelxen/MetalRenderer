//
//  BinaryReader.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 07.02.2022.
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
        let range = NSRange(location: position, length: length)
        let strData = data.subdata(with: range)
        
        position += length
        
        return strData.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) in
            let pointer = ptr.baseAddress!.assumingMemoryBound(to: CChar.self)
            return String(cString: pointer, encoding: .ascii) ?? ""
        }
    }
    
    private func getNumber<T>() -> T
    {
        let value = (data.bytes + position).bindMemory(to: T.self, capacity: 1).pointee
        position += MemoryLayout<T>.size
        
        return value
    }
}
