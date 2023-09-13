//
//  Waypoint.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 24.12.2022.
//

import Foundation
import MetalKit

final class Waypoint
{
    var transform: Transform = {
        let transform = Transform()
        transform.scale = float3(16, 16, 16)
        return transform
    }()
    
    var neighbors: [(Float, Int)] = []
    
    private (set) var minBounds: float3 = float3(-8, -8, -8)
    private (set) var maxBounds: float3 = float3(8, 8, 8)
    
    func add(neighbor: Int, distance: Float)
    {
        neighbors.append((distance, neighbor))
    }
}

extension Waypoint: Codable
{
    enum CodingKeys: String, CodingKey {
        case position
    }
    
    convenience init(from decoder: Decoder) throws
    {
        self.init()
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        transform.position = try values.decode(float3.self, forKey: .position)
    }

    func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(transform.position, forKey: .position)
    }
}

extension Waypoint: Hashable
{
    func hash(into hasher: inout Hasher)
    {
        let value = transform.position.hashValue
        hasher.combine(value)
    }
}

func ==(lhs: Waypoint, rhs: Waypoint) -> Bool
{
    return lhs.transform.position == rhs.transform.position
}
