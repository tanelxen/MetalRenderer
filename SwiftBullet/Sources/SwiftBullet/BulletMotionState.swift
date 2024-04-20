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
    private var transform = BulletTransform()

    public init(transform: BulletTransform)
    {
        self.transform = transform
    }

    public func getWorldTransform() -> BulletTransform
    {
        return transform
    }

    public func setWorldTransform(_ transform: BulletTransform)
    {
        self.transform = transform
    }
}
