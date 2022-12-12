//
//  main.swift
//  Day 08
//
//  Created by Stephen H. Gerstacker on 2022-12-08.
//  SPDX-License-Identifier: MIT
//

import Foundation

struct Tree: Hashable {
    let height: Int
    let x: Int
    let y: Int
}

let inputData = InputData
var grid = inputData.components(separatedBy: "\n").enumerated().map { rowIndex, row in
    row.enumerated().map { columnIndex, height in
        Tree(height: Int(height.asciiValue! - 48), x: columnIndex, y: rowIndex)
    }
}

let gridHeight = grid.count
let gridWidth = grid[0].count

// MARK: - Part 1

var visibleTrees: Set<Tree> = []

for x in 0 ..< gridWidth {
    // Going down
    var maxHeight = -1
    for y in 0 ..< gridHeight {
        let tree = grid[y][x]
        
        if tree.height > maxHeight {
            visibleTrees.insert(tree)
            maxHeight = tree.height
        }
    }
    
    // Going Up
    maxHeight = -1
    for y in (0 ..< gridHeight).reversed() {
        let tree = grid[y][x]
        
        if tree.height > maxHeight {
            visibleTrees.insert(tree)
            maxHeight = tree.height
        }
    }
}

for y in 0 ..< gridHeight {
    // Going right
    var maxHeight = -1
    for x in 0 ..< gridWidth {
        let tree = grid[y][x]
        
        if tree.height > maxHeight {
            visibleTrees.insert(tree)
            maxHeight = tree.height
        }
    }
    
    // Going left
    maxHeight = -1
    for x in (0 ..< gridWidth).reversed() {
        let tree = grid[y][x]
        
        if tree.height > maxHeight {
            visibleTrees.insert(tree)
            maxHeight = tree.height
        }
    }
}

for row in grid {
    let value = row.map { visibleTrees.contains($0) ? String($0.height) : " " }.joined()
    print(value)
}

print()
print("Total Visible: \(visibleTrees.count)")

// MARK: - Part 2

var bestScore = -1
var bestTree = Tree(height: -1, x: -1, y: -1)

for (rowIndex, row) in grid.enumerated() {
    for (columnIndex, tree) in row.enumerated() {
        print("Looking at \(columnIndex), \(rowIndex): \(tree)")
        
        var scenicScore = 1
        
        // Go up
        var index = rowIndex - 1
        var distance = 0
        
        while index >= 0 {
            let neighbor = grid[index][columnIndex]
            distance += 1
            
            if neighbor.height >= tree.height {
                break
            }
            
            index -= 1
        }
        
        scenicScore *= distance
        
        print("-   Score Up: \(scenicScore)")
        
        // Go down
        index = rowIndex + 1
        distance = 0
        
        while index < grid.count {
            let neighbor = grid[index][columnIndex]
            distance += 1
            
            if neighbor.height >= tree.height {
                break
            }
            
            index += 1
        }
        
        scenicScore *= distance
        
        print("-   Score Down: \(scenicScore)")
        
        // Go left
        index = columnIndex - 1
        distance = 0
        
        while index >= 0 {
            let neighbor = grid[rowIndex][index]
            distance += 1
            
            if neighbor.height >= tree.height {
                break
            }
            
            index -= 1
        }
        
        scenicScore *= distance
        
        print("-   Score Left: \(scenicScore)")
        
        // Go right
        index = columnIndex + 1
        distance = 0
        while index < grid[0].count {
            let neighbor = grid[rowIndex][index]
            distance += 1
            
            if neighbor.height >= tree.height {
                break
            }
            
            index += 1
        }
        
        scenicScore *= distance
        
        print("-   Score Right: \(scenicScore)")
        
        if scenicScore > bestScore {
            print("!!! New Best: \(scenicScore): \(tree)")
            
            bestScore = scenicScore
            bestTree = tree
        }
    }
}

print("Best Score: \(bestScore)")
print("Best Tree: \(bestTree)")

