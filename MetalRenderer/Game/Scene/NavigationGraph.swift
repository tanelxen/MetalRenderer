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
    
    private let testHull = TestHull()
    private var testHullWay: [float3] = []
    
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
        testHull.setup()
        linkVisibleNodes()
        rejectInlineLinks()
        rejectUnreachableLinks()
        
        print("Links were built")
    }
    
    private func linkVisibleNodes()
    {
        guard let scene = self.scene else { return }
        
        links = []
        waypoints.forEach { $0.neighbors = [] }
        
        var tested: [Bool] = Array.init(repeating: false, count: waypoints.count)
        
        for (i, start) in waypoints.enumerated()
        {
            tested[i] = true
            
            let startPos = start.transform.position
            
            for (j, end) in waypoints.enumerated()
            {
                if tested[j] { continue }
                
                let endPod = end.transform.position
                let dist = length(endPod - startPos)
                
                if scene.trace(start: startPos, end: endPod)
                {
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
    }
    
    private func rejectInlineLinks()
    {
        for i in 0 ..< waypoints.count
        {
            let srcNode = waypoints[i]
            
            for (_, j) in srcNode.neighbors
            {
                let checkNode = waypoints[j]
                
                var dirToCheckNode = checkNode.transform.position - srcNode.transform.position
                let distToCheckNode = length(dirToCheckNode)
                
                dirToCheckNode = normalize(dirToCheckNode)
                
                for (_, k) in srcNode.neighbors
                {
                    if k == j { continue }
                    
                    let testNode = waypoints[k]
                    
                    var dirToTestNode = testNode.transform.position - srcNode.transform.position
                    let distToTestNode = length(dirToTestNode)
                    
                    dirToTestNode = normalize(dirToTestNode)
                    
                    if dot(dirToCheckNode, dirToTestNode) >= 0.968
                    {
                        if distToTestNode < distToCheckNode
                        {
                            print("REJECTED Node_\(j) through Node_\(k)")
                            
                            srcNode.neighbors.removeAll(where: { $0.1 == j })
                            
                            break
                        }
                    }
                }
            }
        }
        
        links = []
        
        for src in waypoints
        {
            for (dist, i) in src.neighbors
            {
                let dest = waypoints[i]
                let link = Link(start: src, end: dest, distance: dist)
                
                links.append(link)
            }
        }
    }
    
    private func rejectUnreachableLinks()
    {
        for i in 0 ..< waypoints.count
        {
            let srcNode = waypoints[i]
            
            for (dist, j) in srcNode.neighbors
            {
                let saveFlags = testHull.flags
                testHull.transform.position = srcNode.transform.position
                
                let destNode = waypoints[j]
                
                var dir = normalize(destNode.transform.position - srcNode.transform.position)
                dir.z = 0
//                let yaw = atan2(dir.y, dir.x).degrees
                
                var isFailed = false
                var step: Float = 0
                
                while step < dist, !isFailed
                {
                    var stepSize = testHull.STEP_SIZE
                    
                    if (step + stepSize) >= (dist - 1)
                    {
                        stepSize = (dist - step) - 1
                    }
                    
                    if !moveTest(testHull: testHull, move: dir * stepSize)
                    {
                        isFailed = true
                        break
                    }
                    
                    step += testHull.STEP_SIZE
                }
                
                if !isFailed
                {
                    // Если где-то заплутали, провалились и прошли больше, чем ожидалось
                    let wayLength = length(testHull.transform.position - destNode.transform.position)
                    isFailed = wayLength > 64
                }
                
                if isFailed
                {
                    print("REJECTED unreachable Node_\(i) through Node_\(j)")
                    srcNode.neighbors.removeAll(where: { $0.1 == j })
                    
                    testHull.flags = saveFlags
                }
            }
        }
        
        links = []
        
        for src in waypoints
        {
            for (dist, i) in src.neighbors
            {
                let dest = waypoints[i]
                let link = Link(start: src, end: dest, distance: dist)
                
                links.append(link)
            }
        }
    }
    
    private func moveTest(testHull ent: TestHull, move: float3) -> Bool
    {
        let oldorg = ent.transform.position
        
        testHullWay.append(oldorg)
        
        let neworg = oldorg + move
        let neworgUp = neworg + float3(0, 0, ent.stepsize)
        let neworgDown = neworg + float3(0, 0, -ent.stepsize)
        
        var trace = scene!.trace(start: neworgUp, end: neworgDown, mins: ent.mins, maxs: ent.maxs)

        // Наш AABB не может пройти с запасом сверху и снизу
        if trace.allsolid { return false }
        
        // Сверху есть преграда, возможно мы проходим впритык
        if trace.startsolid
        {
            // Попробуем не подниматься и повторить
            trace = scene!.trace(start: neworg, end: neworgDown, mins: ent.mins, maxs: ent.maxs)

            if trace.allsolid || trace.startsolid { return false }
        }
        
        // Свободно прошли
        if trace.fraction == 1.0
        {
            if ent.flags & FL_PARTIALGROUND != 0
            {
                ent.transform.position += move
                //SV_LinkEdict( ent, true )
                ent.flags &= ~FL_ONGROUND
                
                return true
            }
            
            return false
        }
        else
        {
            ent.transform.position = trace.endpos

            if checkBottom(testHull: ent) == false
            {
                if ent.flags & FL_PARTIALGROUND != 0
                {
//                    if( relink ) SV_LinkEdict( ent, true )
                    return true
                }

                ent.transform.position = oldorg
                return false
            }
            else
            {
                ent.flags &= ~FL_PARTIALGROUND
                ent.ground_normal = trace.plane?.normal
//                if( relink ) SV_LinkEdict( ent, true )

                return true
            }
        }
    }
    
    private func checkBottom(testHull ent: TestHull) -> Bool
    {
//        let start = ent.transform.position
//        let end = start + float3(0, 0, -1)
//
//        let trace = scene!.trace(start: start, end: end, mins: ent.mins, maxs: ent.maxs)
//
//        if trace.fraction == 1
//        {
//            return false
//        }
        
        return true
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
        for waypoint in waypoints
        {
            waypoint.transform.updateModelMatrix()
            
            var modelConstants = ModelConstants()
            modelConstants.modelMatrix = waypoint.transform.matrix
            modelConstants.color = float3(1, 0, 0)
            
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
        
//        for position in testHullWay
//        {
//            testHull.transform.position = position
//            testHull.transform.updateModelMatrix()
//
//            testHull.render(with: encoder)
//        }
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

class TestHull
{
    var transform = Transform()
    
    var flags: UInt = 0
    var ground_normal: float3?
    
    let mins = float3( -16, -16, 0 )
    let maxs = float3( 16, 16, 72 )
    
    let STEP_SIZE: Float = 16
    let stepsize: Float = 16
    
    private var _vertices: [float3] = []
    private var _indicies: [UInt16] = []
    
    private var _verticesBuffer: MTLBuffer!
    private var _indiciesBuffer: MTLBuffer!
    
    func setup()
    {
//        let center = (mins + maxs) * 0.5
        let minBounds = mins// - center
        let maxBounds = maxs// - center
        
        _vertices = [
            float3(minBounds.x, maxBounds.y, maxBounds.z), //frontLeftTop       0
            float3(minBounds.x, minBounds.y, maxBounds.z), //frontLeftBottom    1
            float3(maxBounds.x, maxBounds.y, maxBounds.z), //frontRightTop      2
            float3(maxBounds.x, minBounds.y, maxBounds.z), //frontRightBottom   3
            float3(minBounds.x, maxBounds.y, minBounds.z), //backLeftTop        4
            float3(minBounds.x, minBounds.y, minBounds.z), //backLeftBottom     5
            float3(maxBounds.x, maxBounds.y, minBounds.z), //backRightTop       6
            float3(maxBounds.x, minBounds.y, minBounds.z), //backRightBottom    7
        ]
        
        _indicies = [
            0, 1,
            2, 3,
            4, 5,
            6, 7,
            
            0, 2,
            1, 3,
            4, 6,
            5, 7,
            
            0, 4,
            1, 5,
            2, 6,
            3, 7
        ]
        
        _verticesBuffer = Engine.device.makeBuffer(bytes: _vertices, length: MemoryLayout<float3>.stride * _vertices.count, options: [])
        _indiciesBuffer = Engine.device.makeBuffer(bytes: _indicies, length: MemoryLayout<UInt16>.size * _indicies.count, options: [])
    }
    
    func render(with encoder: MTLRenderCommandEncoder?)
    {
        guard _verticesBuffer != nil else { return }
        
        var modelConstants = ModelConstants()
        modelConstants.color = float3(0, 0, 1)
        modelConstants.modelMatrix = transform.matrix
        
        encoder?.setVertexBytes(&modelConstants, length: ModelConstants.stride, index: 2)
        
        encoder?.setVertexBuffer(_verticesBuffer, offset: 0, index: 0)

        encoder?.drawIndexedPrimitives(type: .line,
                                       indexCount: _indicies.count,
                                       indexType: .uint16,
                                       indexBuffer: _indiciesBuffer,
                                       indexBufferOffset: 0)
    }
}

private let FL_ONGROUND: UInt         = 1 << 9    // At rest / on the ground
private let FL_PARTIALGROUND: UInt    = 1 << 10   // not all corners are valid
