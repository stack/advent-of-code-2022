//
//  PriorityQueue.swift
//  Utilities
//
//  Created by Stephen H. Gerstacker on 2022-11-03.
//  Copyright © 2022 Stephen H. Gerstacker. All rights reserved.
//

import Foundation

public struct PriorityQueue<T> {
    public typealias Item = T

    var nodes: [(Item,Int)]

    public var isEmpty: Bool {
        return nodes.isEmpty
    }

    public init() {
        nodes = []
    }

    public mutating func removeAll() {
        nodes = []
    }

    public mutating func pop() -> Item? {
        if nodes.isEmpty {
            return nil
        }

        let item = nodes.removeFirst()
        return item.0
    }
    
    public mutating func popWithCost() -> (item: Item, cost: Int)? {
        if nodes.isEmpty {
            return nil
        }

        let item = nodes.removeFirst()
        return (item: item.0, cost: item.1)
    }

    public mutating func push(_ item: Item, priority: Int) {
        var insertIdx = -1

        for (idx, node) in nodes.enumerated() {
            if priority < node.1 {
                insertIdx = idx
                break
            }
        }

        if insertIdx == -1 {
            insertIdx = nodes.count
        }

        nodes.insert((item, priority), at: insertIdx)
    }
}

extension PriorityQueue: CustomStringConvertible {
    public var description: String {
        let parts = nodes.map { "(\($0.0), \($0.1))" }
        let joined = parts.joined(separator: ", ")

        return "[\(joined)]"
    }
}
