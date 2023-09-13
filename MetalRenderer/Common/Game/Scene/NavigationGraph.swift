//
//  NavigationGraph.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 24.12.2022.
//

import MetalKit
import Quake3BSP

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
        
        Debug.shared.addCube(
            transform: waypoint.transform,
            color: float3(1, 0, 0)
        )
    }
    
    func remove(at index: Int)
    {
        waypoints.remove(at: index)
    }
    
    func build()
    {
        linkVisibleNodes()
        rejectInlineLinks()
        rejectUnreachableLinks()
        
        print("Links were built")
        
        // DEBUG
        for link in links
        {
            Debug.shared.addLine(start: link.start.transform.position,
                                 end: link.end.transform.position,
                                 color: float3(1, 1, 0))
        }
    }
    
    func getWaypointsTransforms() -> [Transform]
    {
        return waypoints.map { $0.transform }
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
        do
        {
            let url = ResourceManager.URLInDocuments(for: "\(named).nav")
            let data = try Data(contentsOf: url)
            
            let decoder = JSONDecoder()
            let graph = try decoder.decode(NavigationGraph.self, from: data)
            
            waypoints = graph.waypoints
            
            for waypoint in waypoints
            {
                Debug.shared.addCube(
                    transform: waypoint.transform,
                    color: float3(1, 0, 0)
                )
            }
            
            print("Navigation Graph was loaded from", url)
        }
        catch
        {
            print(error.localizedDescription)
        }
    }
    
    func save(named: String)
    {
        do
        {
            let jsonEncoder = JSONEncoder()
            let jsonData = try jsonEncoder.encode(self)
            
            let url = ResourceManager.URLInDocuments(for: "\(named).nav")
            try jsonData.write(to: url)
            
            print("Navigation Graph was saved to", url)
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
    
//    func findIntersectedByRay(start: float3, dir: float3, dist: Float) -> Int
//    {
//        var index = -1
//        
//        for (i, waypoint) in waypoints.enumerated()
//        {
//            let mins = waypoint.transform.position + waypoint.minBounds
//            let maxs = waypoint.transform.position + waypoint.maxBounds
//            
//            if intersection(orig: start, dir: dir, mins: mins, maxs: maxs, t: dist)
//            {
//                index = i
//                break
//            }
//        }
//        
//        return index
//    }
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

struct Link
{
    let start: Waypoint
    let end: Waypoint
    let distance: Float
    
    init(start: Waypoint, end: Waypoint, distance: Float)
    {
        self.start = start
        self.end = end
        self.distance = distance
    }
}

private struct Queue<T>
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

private class TestHull
{
    var transform = Transform()
    
    var flags: UInt = 0
    var ground_normal: float3?
    
    let mins = float3( -16, -16, 0 )
    let maxs = float3( 16, 16, 72 )
    
    let STEP_SIZE: Float = 16
    let stepsize: Float = 16
}

private let FL_ONGROUND: UInt         = 1 << 9    // At rest / on the ground
private let FL_PARTIALGROUND: UInt    = 1 << 10   // not all corners are valid
