//
//  File.swift
//  
//
//  Created by Fedor Artemenkov on 31.03.2024.
//

import ObjCBullet
import Foundation
import simd

public class BulletMotionState
{
    var transform = BulletTransform()

    init(transform: BulletTransform)
    {
        self.transform = transform
    }

    func getWorldTransform() -> BulletTransform
    {
        return transform
    }

    func setWorldTransform(_ transform: BulletTransform)
    {
        self.transform = transform
    }
}
