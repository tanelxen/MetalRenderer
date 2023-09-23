//
//  File.swift
//  
//
//  Created by Fedor Artemenkov on 22.09.2023.
//

import Foundation
import GoldSrcMDL
//import OSLog

let url = FileUtils.getURL(path: "Assets/barney.mdl")!
let data = try! Data(contentsOf: url)

let start = CFAbsoluteTimeGetCurrent()

var model = GoldSrcMDL(data: data).valveModel

let diff = (CFAbsoluteTimeGetCurrent() - start) * 1000
print("Decoding \(diff) ms")
