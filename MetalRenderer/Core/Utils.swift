//
//  Utils.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 21.01.2022.
//

import Foundation

enum Utils
{
    static func timeProfile(_ label: String, closure: () -> Void)
    {
        let start = CFAbsoluteTimeGetCurrent()

        closure()

        let diff = (CFAbsoluteTimeGetCurrent() - start) * 1000
        print("\(label) \(diff) ms")
    }
}
