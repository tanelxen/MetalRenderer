//
//  EditableMesh+Codable.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 25.05.2024.
//

import Foundation

extension Vert: Codable
{
    private enum CodingKeys: String, CodingKey {
        case position
    }
    
    func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(position, forKey: .position)
    }
    
    convenience init(from decoder: Decoder) throws
    {
        self.init(.zero)
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        position = try values.decode(float3.self, forKey: .position)
    }
}

extension Face: Codable
{
    private enum CodingKeys: String, CodingKey {
        case name, verts, isGhost
    }
    
    func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(verts, forKey: .verts)
        try container.encode(isGhost, forKey: .isGhost)
    }
    
    convenience init(from decoder: Decoder) throws
    {
        self.init("")
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        name = try values.decode(String.self, forKey: .name)
        verts = try values.decode([Vert].self, forKey: .verts)
        
        if let isGhost = try? values.decode(Bool.self, forKey: .isGhost)
        {
            self.isGhost = isGhost
        }
    }
}

extension EditableMesh: Codable
{
    private enum CodingKeys: String, CodingKey {
        case faces, isRoom
    }
    
    func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(faces, forKey: .faces)
        try container.encode(isRoom, forKey: .isRoom)
    }
    
    convenience init(from decoder: Decoder) throws
    {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let faces = try values.decode([Face].self, forKey: .faces)
        
        self.init(faces: faces)
        
        if let isRoom = try? values.decode(Bool.self, forKey: .isRoom)
        {
            self.isRoom = isRoom
        }
    }
}
