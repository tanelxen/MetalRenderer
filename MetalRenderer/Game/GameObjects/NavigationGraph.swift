//
//  NavigationGraph.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 24.12.2022.
//

import MetalKit

final class NavigationGraph
{
    private var waypoints: [Waypoint] = []
    
    func add(_ waypoint: Waypoint)
    {
        waypoints.append(waypoint)
    }
    
    func remove(at index: Int)
    {
        waypoints.remove(at: index)
    }
    
    func build()
    {
        
    }
    
    func load(named: String)
    {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        let pathWithFileName = documentDirectory.appendingPathComponent("\(named).nav")
        
        let decoder = JSONDecoder()

        do
        {
            let data = try Data(contentsOf: pathWithFileName)
            let graph = try decoder.decode(NavigationGraph.self, from: data)
            
            waypoints = graph.waypoints
        }
        catch
        {
            print(error.localizedDescription)
        }
    }
    
    func save(named: String)
    {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        let pathWithFileName = documentDirectory.appendingPathComponent("\(named).nav")
        
        let jsonEncoder = JSONEncoder()
        
        do
        {
            let jsonData = try jsonEncoder.encode(self)
            try jsonData.write(to: pathWithFileName)
            print("Navigation Graph was saved at", pathWithFileName)
        }
        catch
        {
            print(error.localizedDescription)
        }
    }
    
    func render(with encoder: MTLRenderCommandEncoder?)
    {
        for waypoint in waypoints
        {
            waypoint.transform.updateModelMatrix()
            
            var modelConstants = ModelConstants(modelMatrix: waypoint.transform.matrix)
            encoder?.setVertexBytes(&modelConstants, length: ModelConstants.stride, index: 2)
            
            waypoint.render(with: encoder)
        }
    }
    
    func findIntersectedByRay(start: float3, dir: float3, dist: Float) -> Int
    {
        var index = -1
        
        for (i, waypoint) in waypoints.enumerated()
        {
            let mins = waypoint.transform.position + waypoint.minBounds
            let maxs = waypoint.transform.position + waypoint.maxBounds
            
            if intersection(orig: start, dir: dir, mins: mins, maxs: maxs, t: dist)
            {
                index = i
                break
            }
        }
        
        return index
    }
}

extension NavigationGraph: Codable
{
    enum CodingKeys: String, CodingKey {
        case waypoints
    }
    
    convenience init(from decoder: Decoder) throws
    {
        self.init()
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        waypoints = try values.decode([Waypoint].self, forKey: .waypoints)
    }

    func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(waypoints, forKey: .waypoints)
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
