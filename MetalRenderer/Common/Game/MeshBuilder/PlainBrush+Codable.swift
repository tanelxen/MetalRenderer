//
//  PlainBrush+Codable.swift
//  Sandbox
//
//  Created by Fedor Artemenkov on 09.06.2024.
//

import Foundation

extension PlainBrush: Codable
{
    private enum CodingKeys: String, CodingKey {
        case planes, isRoom
    }
    
    func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(planes, forKey: .planes)
        try container.encode(isRoom, forKey: .isRoom)
    }
    
    convenience init(from decoder: Decoder) throws
    {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        let planes = try values.decode([Plane].self, forKey: .planes)
        
        self.init(planes: planes)
        
        if let isRoom = try? values.decode(Bool.self, forKey: .isRoom)
        {
            self.isRoom = isRoom
        }
    }
}

extension Plane: Codable
{
    private enum CodingKeys: String, CodingKey {
        case normal, distance
    }
    
    func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(normal, forKey: .normal)
        try container.encode(distance, forKey: .distance)
    }
    
    init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.normal = try container.decode(float3.self, forKey: .normal)
        self.distance = try container.decode(Float.self, forKey: .distance)
    }
}

//extension BrushFace: Codable
//{
//    private enum CodingKeys: String, CodingKey {
//        case planeIndex
//    }
//
//    func encode(to encoder: Encoder) throws
//    {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encode(planeIndex, forKey: .planeIndex)
//    }
//
//    convenience init(from decoder: Decoder) throws
//    {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        let index = try container.decode(Int.self, forKey: .planeIndex)
//
//        self.init(planeIndex: index)
//    }
//}
