//
//  Entity.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 02.06.2024.
//

protocol Entity: AnyObject
{
    var isSelected: Bool { get set }
    var transform: Transform { get set }
    
    func render(with renderer: ForwardRenderer)
}

class InfoPlayerStart: Entity
{
    var isSelected: Bool = false
    var transform: Transform = Transform(position: [0, 56, 0])
    
    private lazy var box = MTKGeometry(.box, extents: [32, 56, 32])
    private lazy var arrow = MTKGeometry(.box, extents: [1, 8, 1])
    
    func render(with renderer: ForwardRenderer)
    {
        var renderItem = RenderItem(mtkMesh: box)
        
        renderItem.transform = transform
        renderItem.isSupportLineMode = false
        renderItem.tintColor = [1, 0, 1, 1]
        
        renderer.add(item: renderItem)
        
        if true
        {
            var renderItem = RenderItem(mtkMesh: arrow)
            
            let transform2 = Transform(position: transform.position + [0, 0, 20])
            transform2.parent = float4x4(
                simd_quatf(
                    from: [0, 1, 0],
                    to: transform.rotation.forward
                )
            )
            
            renderItem.transform = transform2
            renderItem.isSupportLineMode = false
            renderItem.tintColor = [0, 0, 1, 1]
            
            renderer.add(item: renderItem)
        }
    }
}
