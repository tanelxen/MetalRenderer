//
//  NavigationGraph.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 24.12.2022.
//

import MetalKit

final class NavigationGraph
{
    weak var scene: Q3MapScene?
    
    private var waypoints: [Waypoint] = []
    private var links: [Link] = []
    
    private var nearest = -1
    
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
        guard let scene = self.scene else { return }
        
        var tested: [Bool] = Array.init(repeating: false, count: waypoints.count)
        
        for (i, start) in waypoints.enumerated()
        {
            tested[i] = true
            
            let startPos = start.transform.position
            
            for (j, end) in waypoints.enumerated()
            {
                if tested[j] { continue }
                
                let endPod = end.transform.position
                
                if scene.trace(start: startPos, end: endPod)
                {
                    let dist = length(endPod - startPos)
                    let link = Link(start: start, end: end, distance: dist)
                    
                    links.append(link)
                }
            }
        }
        
        for link in links
        {
            let startIndex = waypoints.firstIndex(of: link.start)!
            let endIndex = waypoints.firstIndex(of: link.end)!
            
            link.start.add(neighbor: endIndex, distance: link.distance)
            link.end.add(neighbor: startIndex, distance: link.distance)
        }
        
        print("Links were built")
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
    
    func findNearest(from start: float3) -> Int?
    {
        guard let scene = self.scene else { return nil }
        
        var shortest: Float = 999999
        var nearest = -1
        
        for (index, waypoint) in waypoints.enumerated()
        {
            let end = waypoint.transform.position
            
            if scene.trace(start: start, end: end)
            {
                let dist = length(end - start)
                
                if dist < shortest
                {
                    shortest = dist
                    nearest = index
                }
            }
        }
        
        if nearest != -1
        {
            return nearest
        }
        
        return nil
    }
    
    func makeRoute(from startPos: float3, to endPos: float3) -> [float3]
    {
        guard let start = findNearest(from: startPos) else { return [] }
        guard let goal = findNearest(from: endPos) else { return [] }
        
        typealias Edge = (Float, Int)
                
        var queue = Queue<Edge>()
        queue.push((0, start))
        
        var cost_visited: [Int: Float] = [start: 0]
        var visited: [Int: Int?] = [start: nil]
        
        while let (_, cur_node) = queue.pop()
        {
            if cur_node == goal
            {
                break
            }
            
            let neighbors = waypoints[cur_node].neighbors
            
            for (neigh_cost, neigh_node) in neighbors
            {
                let new_cost = (cost_visited[cur_node] ?? 0) + neigh_cost
                
                if cost_visited[neigh_node] == nil || new_cost < cost_visited[neigh_node]!
                {
                    let neigh_pos = waypoints[neigh_node].transform.position
                    let priority = new_cost + length(endPos - neigh_pos)
                    
                    queue.push((priority, neigh_node))
                    
                    cost_visited[neigh_node] = new_cost
                    visited[neigh_node] = cur_node
                }
            }
        }
        
        var indiciesPath = [goal]
        
        var cur_node = goal

        while cur_node != start
        {
            cur_node = visited[cur_node]!!
            indiciesPath.append(cur_node)
        }
        
        var path = indiciesPath.reversed().map({ waypoints[$0].transform.position })
        path.append(endPos)
        
        return path
    }
    
    func render(with encoder: MTLRenderCommandEncoder?)
    {
        for (index, waypoint) in waypoints.enumerated()
        {
            waypoint.transform.updateModelMatrix()
            
            var modelConstants = ModelConstants()
            modelConstants.modelMatrix = waypoint.transform.matrix
            modelConstants.color = (index == nearest) ? float3(0, 0, 1) : float3(1, 0, 0)
            
            encoder?.setVertexBytes(&modelConstants, length: ModelConstants.stride, index: 2)
            
            waypoint.render(with: encoder)
        }
        
        var modelConstants = ModelConstants()
        modelConstants.color = float3(1, 1, 0)
        
        encoder?.setVertexBytes(&modelConstants, length: ModelConstants.stride, index: 2)
        
        for link in links
        {
            link.render(with: encoder)
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

struct Link
{
    let start: Waypoint
    let end: Waypoint
    let distance: Float
    
    private var _verticesBuffer: MTLBuffer!
    
    init(start: Waypoint, end: Waypoint, distance: Float)
    {
        self.start = start
        self.end = end
        self.distance = distance
        
        let _vertices = [
            start.transform.position,
            end.transform.position
        ]
        
        _verticesBuffer = Engine.device.makeBuffer(bytes: _vertices, length: MemoryLayout<float3>.stride * 2, options: [])
    }
    
    func render(with encoder: MTLRenderCommandEncoder?)
    {
        guard _verticesBuffer != nil else { return }

        encoder?.setVertexBuffer(_verticesBuffer, offset: 0, index: 0)
        
        encoder?.drawPrimitives(type: .line, vertexStart: 0, vertexCount: 2)
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

struct Queue<T>
{
    private var elements: [T] = []

    mutating func push(_ value: T)
    {
        elements.append(value)
    }

    mutating func pop() -> T?
    {
        guard !elements.isEmpty else { return nil }
        return elements.removeFirst()
    }

    var head: T? {
        return elements.first
    }

    var tail: T? {
        return elements.last
    }
}
