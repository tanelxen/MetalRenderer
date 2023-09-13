//
//  GameTime.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 13.01.2022.
//

import Foundation

enum GameTime
{
    static private (set) var deltaTime: Float = 0.0
    
    static private var totalGameTime: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()

    public static func update()
    {
        let newTime = CFAbsoluteTimeGetCurrent()
        
        deltaTime = Float(newTime - totalGameTime)
        totalGameTime = newTime
        
//        print(deltaTime)
    }
}
