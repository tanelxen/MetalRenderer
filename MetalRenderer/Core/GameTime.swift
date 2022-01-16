//
//  GameTime.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 13.01.2022.
//

enum GameTime
{
    static private (set) var totalGameTime: Float = 0.0
    static private (set) var deltaTime: Float = 0.0
    
    public static func update(deltaTime: Float)
    {
        self.deltaTime = deltaTime
        self.totalGameTime += deltaTime
    }
}
