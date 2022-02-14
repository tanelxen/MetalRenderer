//
//  HLModel.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 09.02.2022.
//

import Foundation

class HLModel
{
    private var buffer: BinaryReader
    
    init(data: Data)
    {
        buffer = BinaryReader(data: data)

//        let reader = MDLReader_Wrapper(data)
//
//        reader?.initModel()
//
//        if let header = reader?.getHeader()
//        {
//            print(charsToString(header.name))
//        }
        
        
    }
}

typealias Chars64 = (CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar,
                     CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar,
                     CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar,
                     CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar,
                     CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar,
                     CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar,
                     CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar,
                     CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar)

func charsToString(_ chars: Chars64) -> String
{
    var bytes = chars
    
    return withUnsafePointer(to: &bytes) { ptr -> String in
       return String(cString: UnsafeRawPointer(ptr).assumingMemoryBound(to: CChar.self))
    }
}

func charsToString(_ chars: (CChar, CChar, CChar, CChar)) -> String
{
    var bytes = chars
    
    return withUnsafePointer(to: &bytes) { ptr -> String in
       return String(cString: UnsafeRawPointer(ptr).assumingMemoryBound(to: CChar.self))
    }
}
