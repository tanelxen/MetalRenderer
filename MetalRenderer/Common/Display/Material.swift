//
//  Material.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 24.04.2024.
//

import MetalKit

struct Material
{
    let pipelineState: MTLRenderPipelineState
}

enum RenderTechnique
{
    case basic
    case brush
    case grid
    case dot
}
