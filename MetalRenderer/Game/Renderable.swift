//
//  Renderable.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 13.01.2022.
//

import MetalKit

protocol Renderable
{
    func doRender(with encoder: MTLRenderCommandEncoder?, useMaterials: Bool)
}
