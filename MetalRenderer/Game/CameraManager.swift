//
//  CameraManager.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 19.02.2022.
//

import Foundation

class CameraManager
{
    static var shared = CameraManager()
    
    var mainCamera: Camera
    
    private init()
    {
        mainCamera = DebugCamera()
    }
    
    func update()
    {
        mainCamera.update()
    }
}
