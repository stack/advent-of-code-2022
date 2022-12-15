//
//  Point.swift
//  Utilities
//
//  Created by Stephen H. Gerstacker on 2022-11-03.
//  SPDX-License-Identifier: MIT
//

import Foundation

public struct Point: Hashable {
    public var x: Int
    public var y: Int

    public init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }

    public var cardinalNeighbors: [Point] {
        var neighbors: [Point] = []

        neighbors.append(Point(x: x - 1, y: y))
        neighbors.append(Point(x: x + 1, y: y))
        neighbors.append(Point(x: x, y: y - 1))
        neighbors.append(Point(x: x, y: y + 1))

        return neighbors
    }
    
    public var allNeighbors: [Point] {
        var neighbors: [Point] = []
        
        for yOffset in -1...1 {
            for xOffset in -1...1 {
                if xOffset == 0 && yOffset == 0 { continue }
                
                neighbors.append(Point(x: x + xOffset, y: y + yOffset))
            }
        }
        
        return neighbors
    }

    public static var zero: Point {
        return Point(x: 0, y: 0)
    }
    
    public func manhattenDistance(to other: Point) -> Int {
        return abs(x - other.x) + abs(y - other.y)
    }
}

extension Point: Comparable {
    public static func < (lhs: Point, rhs: Point) -> Bool {
        if lhs.x < rhs.x {
            return true
        } else if lhs.x > rhs.x {
            return false
        } else {
            return lhs.y < rhs.y
        }
    }
}
extension Point: CustomDebugStringConvertible {
    public var debugDescription: String {
        "(\(x),\(y))"
    }
}

extension Point: CustomStringConvertible {
    public var description: String {
        "(\(x),\(y))"
    }
}
