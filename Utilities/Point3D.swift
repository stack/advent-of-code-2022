//
//  Point3D.swift
//  Utilities
//
//  Created by Stephen H. Gerstacker on 2022-12-18.
//  SPDX-License-Identifier: MIT
//

import Foundation

public struct Point3D: Hashable {
    public var x: Int
    public var y: Int
    public var z: Int
    
    public init(x: Int, y: Int, z: Int) {
        self.x = x
        self.y = y
        self.z = z
    }
    
    public var cardinalNeighbors: [Point3D] {
        let neighbors: [Point3D] = [
            Point3D(x: x - 1, y: y,     z: z),
            Point3D(x: x + 1, y: y,     z: z),
            Point3D(x: x,     y: y - 1, z: z),
            Point3D(x: x,     y: y + 1, z: z),
            Point3D(x: x,     y: y,     z: z - 1),
            Point3D(x: x,     y: y,     z: z + 1),
        ]
        
        return neighbors
    }
    
    public static var zero: Point3D {
        return Point3D(x: 0, y: 0, z: 0)
    }
    
    public func manhattenDistance(to other: Point3D) -> Int {
        return abs(x - other.x) + abs(y - other.y) + abs(z - other.z)
    }
    
    public static func +(lhs: Point3D, rhs: Point3D) -> Point3D {
        return Point3D(x: lhs.x + rhs.x, y: lhs.y + rhs.y, z: lhs.z + rhs.z)
    }
    
    public static func -(lhs: Point3D, rhs: Point3D) -> Point3D {
        return Point3D(x: lhs.x - rhs.x, y: lhs.y - rhs.y, z: lhs.z - rhs.z)
    }
}

extension Point3D: Comparable {
    public static func < (lhs: Point3D, rhs: Point3D) -> Bool {
        if lhs.x < rhs.x {
            return true
        } else if lhs.x > rhs.x {
            return false
        } else if lhs.y < rhs.y {
            return true
        } else if lhs.y > rhs.y {
            return true
        } else {
            return lhs.z < rhs.z
        }
    }
}

extension Point3D: CustomDebugStringConvertible {
    public var debugDescription: String {
        "(\(x),\(y),\(z)"
    }
}

extension Point3D: CustomStringConvertible {
    public var description: String {
        "(\(x),\(y),\(z)"
    }
}
