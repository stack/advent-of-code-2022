//
//  main.swift
//  Day 07
//
//  Created by Stephen H. Gerstacker on 2022-12-07.
//  Copyright © 2022 Stephen H. Gerstacker. All rights reserved.
//

import Foundation

class Node {
    let name: String
    let size: Int
    
    var totalSize: Int
    
    var children: [Node]
    var parent: Node?
    
    var isDirectory: Bool {
        size == 0
    }
    
    init(name: String, size: Int) {
        self.name = name
        self.size = size
        
        totalSize = 0
        
        children = []
        parent = nil
    }
}

class FileSystem {
    
    let rootNode = Node(name: "/", size: 0)
    
    let cdRootRegex = /^\$ cd \/$/
    let cdUpRegex   = /^\$ cd \.\.$/
    let cdRegex     = /^\$ cd (.+)$/
    let dirRegex    = /^dir (.+)$/
    let fileRegex   = /^(\d+) (.+)$/
    
    init(data: String) {
        var currentNode = rootNode
        
        for line in data.components(separatedBy: "\n") {
            if let _ = line.firstMatch(of: cdRootRegex) {
                currentNode = rootNode
            } else if let _ = line.firstMatch(of: cdUpRegex) {
                currentNode = currentNode.parent!
            } else if let match = line.firstMatch(of: cdRegex) {
                for child in currentNode.children {
                    if child.name == match.1 {
                        currentNode = child
                    }
                }
            } else if let match = line.firstMatch(of: dirRegex) {
                let node = Node(name: String(match.1), size: 0)
                currentNode.children.append(node)
                node.parent = currentNode
            } else if let match = line.firstMatch(of: fileRegex) {
                let node = Node(name: String(match.2), size: Int(match.1)!)
                
                currentNode.children.append(node)
                node.parent = currentNode
                
                var upperNode = node.parent
                
                while upperNode != nil {
                    upperNode!.totalSize += node.size
                    upperNode = upperNode!.parent
                }
            }
        }
    }
    
    func findSmall() -> Int {
        var remainingDirectories = [rootNode]
        var matchingDirectories: [Node] = []
        
        while !remainingDirectories.isEmpty {
            let nextDirectory = remainingDirectories.removeFirst()
            
            if nextDirectory.totalSize <= 100000 {
                matchingDirectories.append(nextDirectory)
            }
            
            let nextChildren = nextDirectory.children.filter(\.isDirectory)
            remainingDirectories.append(contentsOf: nextChildren)
        }
        
        for directory in matchingDirectories {
            print("\(directory.name): \(directory.totalSize)")
        }
        
        let total = matchingDirectories.map(\.totalSize).reduce(0, +)
        
        return total
    }
    
    func findDeletable() -> Int {
        let totalSize = 70000000
        let unusedSpace = totalSize - rootNode.totalSize
        let requiredSize = 30000000
        
        var remainingDirectories = [rootNode]
        var matchingDirectories: [Node] = []
        
        while !remainingDirectories.isEmpty {
            let nextDirectory = remainingDirectories.removeFirst()
            
            if unusedSpace + nextDirectory.totalSize >= requiredSize {
                matchingDirectories.append(nextDirectory)
            }
            
            let nextChildren = nextDirectory.children.filter(\.isDirectory)
            remainingDirectories.append(contentsOf: nextChildren)
        }
        
        let toDelete = matchingDirectories.map(\.totalSize).min()!
        
        return toDelete
    }
}

let filesystem = FileSystem(data: InputData)

let smallTotal = filesystem.findSmall()
print("Small Total: \(smallTotal)")

let sizeToDelete = filesystem.findDeletable()
print("To Delete: \(sizeToDelete)")
