//
//  main.swift
//  Day 22
//
//  Created by Stephen Gerstacker on 2022-12-22.
//  SPDX-License-Identifier: MIT
//

import Algorithms
import Foundation
import Utilities

enum Direction: Hashable {
    case left
    case right
    case up
    case down
    
    var clockwise: Direction {
        switch self {
        case .left: return .up
        case .up: return .right
        case .right: return .down
        case .down: return .left
        }
    }
    
    func rotatedClockwise(_ times: Int) -> Direction {
        var current = self
        
        for _ in 0 ..< (times % 4) {
            current = current.clockwise
        }
        
        return current
    }
    
    func turn(_ turn: Turn) -> Direction {
        switch turn {
        case .clockwise:
            switch self {
            case .left: return .up
            case .up: return .right
            case .right: return .down
            case .down: return .left
            }
        case .counterClockwise:
            switch self {
            case .left: return .down
            case .down: return .right
            case .right: return .up
            case .up: return .left
            }
        }
    }
}

enum Turn {
    case clockwise
    case counterClockwise
}

enum Instruction {
    case move(Int)
    case turn(Turn)
}

class Solver1 {

    enum Tile {
        case empty
        case open
        case wall
    }
    
    private let instructions: [Instruction]
    private let map: [[Tile]]
    private let rowRanges: [ClosedRange<Int>]
    private let columnRanges: [ClosedRange<Int>]
    private let width: Int
    private let height: Int
    
    init(data: String) {
        var instructions: [Instruction] = []
        var map: [[Tile]] = []
        var rowRanges: [ClosedRange<Int>] = []
        var columnRanges: [ClosedRange<Int>] = []
        
        var finishedBoard = false
        
        for line in data.components(separatedBy: "\n") {
            guard !line.isEmpty else {
                finishedBoard = true
                continue
            }
            
            guard !finishedBoard else {
                for match in line.matches(of: /(\d+|[A-Z])/) {
                    if let value = Int(match.output.1) {
                        instructions.append(.move(value))
                    } else if match.output.1 == "L" {
                        instructions.append(.turn(.counterClockwise))
                    } else if match.output.1 == "R" {
                        instructions.append(.turn(.clockwise))
                    } else {
                        fatalError("Unhandled instruction: \(match.output)")
                    }
                }
                
                break
            }
            
            let rowTiles: [Tile] = line.map {
                switch $0 {
                case " ": return .empty
                case ".": return .open
                case "#": return .wall
                default:
                    fatalError("Unhandled tile: \($0)")
                }
            }
            
            map.append(rowTiles)
        }
        
        let width = map.map { $0.count }.max() ?? 0
        
        for rowIndex in 0 ..< map.count {
            let row = map[rowIndex]
            
            if row.count < width {
                let padding = [Tile](repeating: .empty, count: width - row.count)
                map[rowIndex].append(contentsOf: padding)
            }
            
            let startIndex = row.firstIndex { $0 != .empty } ?? 0
            let endIndex = row.lastIndex { $0 != .empty } ?? 0
            let range = startIndex ... endIndex
            
            rowRanges.append(range)
        }
        
        for columnIndex in 0 ..< map[0].count {
            let column = map.map { $0[columnIndex] }
            
            let startIndex = column.firstIndex { $0 != .empty } ?? 0
            let endIndex = column.lastIndex { $0 != .empty } ?? 0
            let range = startIndex ... endIndex
            
            columnRanges.append(range)
        }
        
        self.instructions = instructions
        self.map = map
        self.rowRanges = rowRanges
        self.columnRanges = columnRanges
        self.width = width
        self.height = map.count
    }
    
    func run() -> Int {
        var currentPosition = Point(x: rowRanges[0].lowerBound, y: 0)
        var currentDirection = Direction.right
        var remainingInstructions = instructions
        var path: [Point:Direction] = [currentPosition: currentDirection]
        
        while !remainingInstructions.isEmpty {
            let instruction = remainingInstructions.removeFirst()
            
            if case .turn(let turn) = instruction {
                currentDirection = currentDirection.turn(turn)
                path[currentPosition] = currentDirection
            } else if case .move(let distance) = instruction {
                var remainingDistance = distance
                
                while remainingDistance > 0 {
                    guard let (nextPosition, nextDirection) = nextPosition(from: currentPosition, facing: currentDirection) else {
                        break
                    }
                    
                    currentPosition = nextPosition
                    currentDirection = nextDirection
                    
                    path[currentPosition] = currentDirection
                    
                    remainingDistance -= 1
                }
            }
        }

        let facingScore: Int
        
        switch currentDirection {
        case .right: facingScore = 0
        case .down: facingScore = 1
        case .left: facingScore = 2
        case .up: facingScore = 3
        }
        
        let rowScore = (currentPosition.y + 1) * 1000
        let columnScore = (currentPosition.x + 1) * 4
        
        return rowScore + columnScore + facingScore
    }
    
    private func nextPosition(from currentPosition: Point, facing direction: Direction) -> (Point, Direction)? {
        var nextPosition = currentPosition
        
        switch direction {
        case .up:
            nextPosition.y -= 1
            
            if nextPosition.y < 0 { nextPosition.y = height - 1 }
            
            let columnRange = columnRanges[nextPosition.x]
            if !columnRange.contains(nextPosition.y) { nextPosition.y = columnRange.upperBound }
        case .down:
            nextPosition.y += 1
            
            if nextPosition.y > height { nextPosition.y = 0 }
            
            let columnRange = columnRanges[nextPosition.x]
            if !columnRange.contains(nextPosition.y) { nextPosition.y = columnRange.lowerBound }
        case .left:
            nextPosition.x -= 1
            
            if nextPosition.x < 0 { nextPosition.x = width - 1 }
            
            let rowRange = rowRanges[nextPosition.y]
            if !rowRange.contains(nextPosition.x) { nextPosition.x = rowRange.upperBound }
        case .right:
            nextPosition.x += 1
            
            if nextPosition.x > width { nextPosition.x = 0 }
            
            let rowRange = rowRanges[nextPosition.y]
            if !rowRange.contains(nextPosition.x) { nextPosition.x = rowRange.lowerBound }
        }
        
        let nextTile = map[nextPosition.y][nextPosition.x]
        
        guard nextTile == .open else {
            return nil
        }
        
        return (nextPosition, direction)
    }
}

class Solver2 {
    
    enum Tile {
        case open
        case wall
    }
    
    class Face {
        let id: Point
        var map: [[Tile]]
        
        var left: Face? = nil
        var leftRotation: Int = 0
        
        var up: Face? = nil
        var upRotation: Int = 0
        
        var right: Face? = nil
        var rightRotation: Int = 0
        
        var down: Face? = nil
        var downRotation: Int = 0
        
        init(id: Point, size: Int) {
            self.id = id
            map = [[Tile]](repeating: [Tile](repeating: .open, count: size), count: size)
        }
    }
    
    struct PathItem: Hashable {
        let face: Point
        let position: Point
    }
    
    struct Test {
        let sourceFace: ReferenceWritableKeyPath<Solver2.Face, Solver2.Face?>
        let sourceRotation: ReferenceWritableKeyPath<Solver2.Face, Int>
        let sourceRotationValue: Int
        
        let otherFace: ReferenceWritableKeyPath<Solver2.Face, Solver2.Face?>
        let otherRotation: ReferenceWritableKeyPath<Solver2.Face, Int>
        let otherRotationValue: Int
        
        let points: [(Int, Int)]
    }
    
    var faces: [Point:Face] = [:]
    var firstFace: Face? = nil
    
    private let instructions: [Instruction]
    
    let faceDimension: Int
    let layoutFacesX: Int
    let layoutFacesY: Int
    let layoutFacesMax: Int
    
    let shouldPrint: Bool
    
    init(data: String, shouldPrint: Bool = false) {
        // Determine the dimensions of the faces and layout
        var layoutWidth: Int = .min
        var layoutHeight: Int = 0
        
        for line in data.components(separatedBy: "\n") {
            guard !line.isEmpty else { break }
            
            layoutWidth = max(layoutWidth, line.count)
            layoutHeight += 1
        }
        
        faceDimension = gcd(layoutWidth, layoutHeight)
        layoutFacesX = layoutWidth / faceDimension
        layoutFacesY = layoutHeight / faceDimension
        layoutFacesMax = 4
    
        let instructionLine = data.components(separatedBy: "\n").last!
        
        var instructions: [Instruction] = []
        
        for match in instructionLine.matches(of: /(\d+|[A-Z])/) {
            if let value = Int(match.output.1) {
                instructions.append(.move(value))
            } else if match.output.1 == "L" {
                instructions.append(.turn(.counterClockwise))
            } else if match.output.1 == "R" {
                instructions.append(.turn(.clockwise))
            } else {
                fatalError("Unhandled instruction: \(match.output)")
            }
        }
        
        self.instructions = instructions
        self.shouldPrint = shouldPrint
        
        // Place the faces
        buildFaces(data: data)
        placeNeighbors()
    }
    
    private func buildFaces(data: String) {
        for (allDataRow, line) in data.components(separatedBy: "\n").enumerated() {
            guard !line.isEmpty else { break }
            
            let faceRow = allDataRow / faceDimension
            let dataRow = allDataRow % faceDimension
            
            for (faceColumn, row) in line.chunks(ofCount: faceDimension).enumerated() {
                guard row.first != " " else {
                    continue
                }
                
                let tileRow: [Tile] = row.map { $0 == "." ? .open : .wall }
                let faceIndex = Point(x: faceColumn, y: faceRow)
                
                let face = faces[faceIndex] ?? Face(id: faceIndex, size: faceDimension)
                face.map[dataRow] = tileRow
                
                if firstFace == nil {
                    firstFace = face
                }
                
                faces[faceIndex] = face
            }
        }
    }
    
    private func placeNeighbors() {
        let tests = [
            // Direct Neighbors
            Test(sourceFace: \.left,  sourceRotation: \.leftRotation,  sourceRotationValue: 0, otherFace: \.right, otherRotation: \.rightRotation, otherRotationValue: 0, points: [(-1, 0)]),
            Test(sourceFace: \.right, sourceRotation: \.rightRotation, sourceRotationValue: 0, otherFace: \.left,  otherRotation: \.leftRotation,  otherRotationValue: 0, points: [( 1, 0)]),
            Test(sourceFace: \.up,    sourceRotation: \.upRotation,    sourceRotationValue: 0, otherFace: \.down,  otherRotation: \.downRotation,  otherRotationValue: 0, points: [(0, -1)]),
            Test(sourceFace: \.down,  sourceRotation: \.downRotation,  sourceRotationValue: 0, otherFace: \.up,    otherRotation: \.upRotation,    otherRotationValue: 0, points: [(0,  1)]),
            
            // Diagonal Neighbors
            Test(sourceFace: \.left,  sourceRotation: \.leftRotation,  sourceRotationValue: 3, otherFace: \.up,    otherRotation: \.upRotation,    otherRotationValue: 1, points: [( 0,  1), (-1,  1)]),
            Test(sourceFace: \.left,  sourceRotation: \.leftRotation,  sourceRotationValue: 1, otherFace: \.down,  otherRotation: \.downRotation,  otherRotationValue: 3, points: [( 0, -1), (-1, -1)]),
            Test(sourceFace: \.right, sourceRotation: \.rightRotation, sourceRotationValue: 1, otherFace: \.up,    otherRotation: \.upRotation,    otherRotationValue: 3, points: [( 0,  1), ( 1,  1)]),
            Test(sourceFace: \.right, sourceRotation: \.rightRotation, sourceRotationValue: 3, otherFace: \.down,  otherRotation: \.downRotation,  otherRotationValue: 1, points: [( 0, -1), ( 1, -1)]),
            Test(sourceFace: \.up,    sourceRotation: \.upRotation,    sourceRotationValue: 1, otherFace: \.left,  otherRotation: \.leftRotation,  otherRotationValue: 3, points: [( 1,  0), ( 1, -1)]),
            Test(sourceFace: \.up,    sourceRotation: \.upRotation,    sourceRotationValue: 3, otherFace: \.right, otherRotation: \.rightRotation, otherRotationValue: 1, points: [(-1,  0), (-1, -1)]),
            Test(sourceFace: \.down,  sourceRotation: \.downRotation,  sourceRotationValue: 3, otherFace: \.left,  otherRotation: \.leftRotation,  otherRotationValue: 1, points: [( 1,  0), ( 1,  1)]),
            Test(sourceFace: \.down,  sourceRotation: \.downRotation,  sourceRotationValue: 1, otherFace: \.right, otherRotation: \.rightRotation, otherRotationValue: 3, points: [(-1,  0), (-1,  1)]),
            
            // L Shape Neighbors
            Test(sourceFace: \.left,  sourceRotation: \.leftRotation,  sourceRotationValue: 2, otherFace: \.left,  otherRotation: \.leftRotation,  otherRotationValue: 2, points: [( 0,  1), ( 0,  2), (-1,  2)]),
            Test(sourceFace: \.left,  sourceRotation: \.leftRotation,  sourceRotationValue: 2, otherFace: \.left,  otherRotation: \.leftRotation,  otherRotationValue: 2, points: [( 0, -1), ( 0, -2), (-1, -2)]),
            Test(sourceFace: \.right, sourceRotation: \.rightRotation, sourceRotationValue: 2, otherFace: \.right, otherRotation: \.rightRotation, otherRotationValue: 2, points: [( 0,  1), ( 0,  2), ( 1,  2)]),
            Test(sourceFace: \.right, sourceRotation: \.rightRotation, sourceRotationValue: 2, otherFace: \.right, otherRotation: \.rightRotation, otherRotationValue: 2, points: [( 0, -1), ( 0, -2), ( 1, -2)]),
            Test(sourceFace: \.up,    sourceRotation: \.upRotation,    sourceRotationValue: 2, otherFace: \.up,    otherRotation: \.upRotation,    otherRotationValue: 2, points: [( 1,  0), ( 2,  0), ( 2, -1)]),
            Test(sourceFace: \.up,    sourceRotation: \.upRotation,    sourceRotationValue: 2, otherFace: \.up,    otherRotation: \.upRotation,    otherRotationValue: 2, points: [(-1,  0), (-2,  0), (-2, -1)]),
            Test(sourceFace: \.down,  sourceRotation: \.downRotation,  sourceRotationValue: 2, otherFace: \.down,  otherRotation: \.downRotation,  otherRotationValue: 2, points: [( 1,  0), ( 2,  0), ( 2,  1)]),
            Test(sourceFace: \.down,  sourceRotation: \.downRotation,  sourceRotationValue: 2, otherFace: \.down,  otherRotation: \.downRotation,  otherRotationValue: 2, points: [(-1,  0), (-2,  0), (-2,  1)]),
            
            // Z Shape Neighbors
            Test(sourceFace: \.left,  sourceRotation: \.leftRotation,  sourceRotationValue: 1, otherFace: \.down,  otherRotation: \.downRotation,  otherRotationValue: 3, points: [( 1,  0), ( 2,  0), ( 2,  1), ( 3,  1)]),
            Test(sourceFace: \.left,  sourceRotation: \.leftRotation,  sourceRotationValue: 3, otherFace: \.up,    otherRotation: \.upRotation,    otherRotationValue: 1, points: [( 1,  0), ( 2,  0), ( 2, -1), ( 3, -1)]),
            Test(sourceFace: \.right, sourceRotation: \.rightRotation, sourceRotationValue: 3, otherFace: \.down,  otherRotation: \.downRotation,  otherRotationValue: 1, points: [(-1,  0), (-2,  0), (-2,  1), (-3,  1)]),
            Test(sourceFace: \.right, sourceRotation: \.rightRotation, sourceRotationValue: 1, otherFace: \.up,    otherRotation: \.upRotation,    otherRotationValue: 3, points: [(-1,  0), (-2,  0), (-2, -1), (-3, -1)]),
            Test(sourceFace: \.up,    sourceRotation: \.upRotation,    sourceRotationValue: 1, otherFace: \.left,  otherRotation: \.leftRotation,  otherRotationValue: 3, points: [( 0,  1), ( 0,  2), (-1,  2), (-1,  3)]),
            Test(sourceFace: \.up,    sourceRotation: \.upRotation,    sourceRotationValue: 3, otherFace: \.right, otherRotation: \.rightRotation, otherRotationValue: 1, points: [( 0,  1), ( 0,  2), ( 1,  2), ( 1,  3)]),
            Test(sourceFace: \.down,  sourceRotation: \.downRotation,  sourceRotationValue: 1, otherFace: \.right, otherRotation: \.rightRotation, otherRotationValue: 3, points: [( 0, -1), ( 0, -2), ( 1, -2), ( 1, -3)]),
            Test(sourceFace: \.down,  sourceRotation: \.downRotation,  sourceRotationValue: 3, otherFace: \.left,  otherRotation: \.leftRotation,  otherRotationValue: 1, points: [( 0, -1), ( 0, -2), (-1, -2), (-1, -3)]),
            
            // Long Shape Neighbors
            Test(sourceFace: \.up,    sourceRotation: \.upRotation,    sourceRotationValue: 0, otherFace: \.down,  otherRotation: \.downRotation,  otherRotationValue: 0, points: [(-1, 0), (-1, 1), (-1, 2), (-2, 2), (-2, 3)])
        ]
        
        for (point, face) in faces {
            for (testIndex, test) in tests.enumerated() {
                if face[keyPath: test.sourceFace] == nil {
                    let otherFaces = test.points.compactMap {
                        let otherPoint = pointOffset(point, x: $0.0, y: $0.1)
                        let otherFace = faces[otherPoint]
                    
                        return otherFace
                    }
                    
                    guard otherFaces.count == test.points.count else { continue }
                    
                    let otherFace = otherFaces.last!
                    
                    face[keyPath: test.sourceFace] = otherFace
                    face[keyPath: test.sourceRotation] = test.sourceRotationValue
                    
                    otherFace[keyPath: test.otherFace] = face
                    otherFace[keyPath: test.otherRotation] = test.otherRotationValue
                }
            }
        }
        
        for (_, face) in faces {
            assert(face.left != nil)
            assert(face.up != nil)
            assert(face.right != nil)
            assert(face.down != nil)
        }
        
        for face in faces.values.sorted(by: { $0.id < $1.id }) {
            print("Face \(face.id)")
            
            print("-   Left: \(face.left!.id) x \(face.leftRotation)")
            print("-     Up: \(face.up!.id) x \(face.upRotation)")
            print("-  Right: \(face.right!.id) x \(face.rightRotation)")
            print("-   Down: \(face.down!.id) x \(face.downRotation)")
        }
    }
    
    private func pointOffset(_ point: Point, x: Int, y: Int) -> Point {
        var newPoint = Point(x: point.x + x, y: point.y + y)
        
        if newPoint.x < 0 { newPoint.x = layoutFacesMax - 1 }
        if newPoint.y < 0 { newPoint.y = layoutFacesMax - 1 }
        if newPoint.x >= layoutFacesMax { newPoint.x = 0 }
        if newPoint.y >= layoutFacesMax { newPoint.y = 0 }
        
        return newPoint
    }
    
    func run() -> Int {
        var currentFace = firstFace!
        var currentPosition = Point(x: 0, y: 0)
        var currentDirection = Direction.right
        var remainingInstructions = instructions
        var path: Set<PathItem> = []
        var pathTable: [PathItem:Direction] = [:]
        
        let initialPathItem = PathItem(face: currentFace.id, position: currentPosition)
        path.insert(initialPathItem)
        pathTable[initialPathItem] = currentDirection
        
        if shouldPrint {
            print()
            printState(path: pathTable)
        }
        
        while !remainingInstructions.isEmpty {
            let instruction = remainingInstructions.removeFirst()
            
            if case .turn(let turn) = instruction {
                currentDirection = currentDirection.turn(turn)
                
                let pathItem = PathItem(face: currentFace.id, position: currentPosition)
                pathTable[pathItem] = currentDirection
                path.insert(pathItem)
                
                if shouldPrint {
                    print()
                    printState(path: pathTable)
                }
            } else if case .move(let distance) = instruction {
                var remainingDistance = distance
                
                while remainingDistance > 0 {
                    guard let (nextPosition, nextFace, nextDirection) = nextPosition(from: currentPosition, on: currentFace, facing: currentDirection) else {
                        break
                    }
                    
                    currentPosition = nextPosition
                    currentFace = nextFace
                    currentDirection = nextDirection
                    
                    let pathItem = PathItem(face: currentFace.id, position: currentPosition)
                    pathTable[pathItem] = currentDirection
                    path.insert(pathItem)
                    
                    remainingDistance -= 1
                    
                    if shouldPrint {
                        print()
                        printState(path: pathTable)
                    }
                }
            }
        }

        let facingScore: Int
        
        switch currentDirection {
        case .right: facingScore = 0
        case .down: facingScore = 1
        case .left: facingScore = 2
        case .up: facingScore = 3
        }
        
        let overallPosition = Point(
            x: (faceDimension * currentFace.id.x) + currentPosition.x,
            y: (faceDimension * currentFace.id.y) + currentPosition.y
        )
        
        let rowScore = (overallPosition.y + 1) * 1000
        let columnScore = (overallPosition.x + 1) * 4
        
        return rowScore + columnScore + facingScore
    }
    
    private func nextPosition(from currentPosition: Point, on face: Face, facing direction: Direction) -> (Point, Face, Direction)? {
        var nextPosition = currentPosition
        var nextFace = face
        var nextDirection = direction
        
        switch direction {
        case .up:
            nextPosition.y -= 1
            
            if nextPosition.y < 0 {
                nextPosition.y = 0
                
                for _ in 0 ..< face.upRotation {
                    let temp = nextPosition.x
                    nextPosition.x = nextPosition.y
                    nextPosition.y = temp
                    
                    nextPosition.x = faceDimension - nextPosition.x - 1
                    
                    nextDirection = nextDirection.clockwise
                }
                
                print("Jump up from \(face.id) to \(face.up!.id)")
                
                nextFace = face.up!
                
                switch nextDirection {
                case .left: nextPosition.x = faceDimension - 1
                case .up: nextPosition.y = faceDimension - 1
                case .right: nextPosition.x = 0
                case .down: nextPosition.y = 0
                }
                
                print("-   \(currentPosition) to \(nextPosition)")
                print("-   \(direction) to \(nextDirection)")
            }
        case .down:
            nextPosition.y += 1
            
            if nextPosition.y >= faceDimension {
                nextPosition.y = faceDimension - 1
                
                for _ in 0 ..< face.downRotation {
                    let temp = nextPosition.x
                    nextPosition.x = nextPosition.y
                    nextPosition.y = temp
                    
                    nextPosition.x = faceDimension - nextPosition.x - 1
                    
                    nextDirection = nextDirection.clockwise
                }
                
                print("Jump down from \(face.id) to \(face.down!.id)")
                
                nextFace = face.down!
                
                switch nextDirection {
                case .left: nextPosition.x = faceDimension - 1
                case .up: nextPosition.y = faceDimension - 1
                case .right: nextPosition.x = 0
                case .down: nextPosition.y = 0
                }
                
                print("-   \(currentPosition) to \(nextPosition)")
                print("-   \(direction) to \(nextDirection)")
            }
        case .left:
            nextPosition.x -= 1
            
            if nextPosition.x < 0 {
                nextPosition.x = 0
                
                for _ in 0 ..< face.leftRotation {
                    let temp = nextPosition.x
                    nextPosition.x = nextPosition.y
                    nextPosition.y = temp
                    
                    nextPosition.x = faceDimension - nextPosition.x - 1
                    
                    nextDirection = nextDirection.clockwise
                }
                
                print("Jump left from \(face.id) to \(face.left!.id)")
                
                nextFace = face.left!
                
                switch nextDirection {
                case .left: nextPosition.x = faceDimension - 1
                case .up: nextPosition.y = faceDimension - 1
                case .right: nextPosition.x = 0
                case .down: nextPosition.y = 0
                }
                
                print("-   \(currentPosition) to \(nextPosition)")
                print("-   \(direction) to \(nextDirection)")
            }
        case .right:
            nextPosition.x += 1
            
            if nextPosition.x >= faceDimension {
                nextPosition.x = faceDimension - 1
                
                for _ in 0 ..< face.rightRotation {
                    let temp = nextPosition.x
                    nextPosition.x = nextPosition.y
                    nextPosition.y = temp
                    
                    nextPosition.x = faceDimension - nextPosition.x - 1
                    
                    nextDirection = nextDirection.clockwise
                }
                
                print("Jump right from \(face.id) to \(face.right!.id)")
                
                nextFace = face.right!
                
                switch nextDirection {
                case .left: nextPosition.x = faceDimension - 1
                case .up: nextPosition.y = faceDimension - 1
                case .right: nextPosition.x = 0
                case .down: nextPosition.y = 0
                }
                
                print("-   \(currentPosition) to \(nextPosition)")
                print("-   \(direction) to \(nextDirection)")
            }
        }
        
        let nextTile = nextFace.map[nextPosition.y][nextPosition.x]
        
        guard nextTile == .open else {
            return nil
        }
        
        return (nextPosition, nextFace, nextDirection)
    }
    
    private func printState(path: [PathItem:Direction]) {
        for faceY in 0 ..< layoutFacesY {
            for y in 0 ..< faceDimension {
                var line = ""
                
                for faceX in 0 ..< layoutFacesX {
                    let facePoint = Point(x: faceX, y: faceY)
                    
                    if let face = faces[facePoint] {
                        for x in 0 ..< faceDimension {
                            let point = Point(x: x, y: y)
                            let pathItem = PathItem(face: face.id, position: point)
                            
                            if let direction = path[pathItem] {
                                switch direction {
                                case .left: line += "<"
                                case .up: line += "^"
                                case .right: line += ">"
                                case .down: line += "v"
                                }
                            } else {
                                line += face.map[y][x] == .open ? "." : "#"
                            }
                        }
                    } else {
                        line += String(repeating: " ", count: faceDimension)
                    }
                }
                
                print(line)
            }
        }
    }
}

print("== Part 1 ==")

let (sampleSolver1, sample1ParseDuration) = benchmark { Solver1(data: SampleData) }
let (sample1Password, sample1RunDuration) = benchmark { sampleSolver1.run() }

print()
print("Sample Password: \(sample1Password)")
print("-   Parse: \(sample1ParseDuration.formatted(.benchmark))")
print("-     Run: \(sample1RunDuration.formatted(.benchmark))")
print("-   Total: \((sample1ParseDuration + sample1RunDuration).formatted(.benchmark))")

let (inputSolver1, input1ParseDuration) = benchmark { Solver1(data: InputData) }
let (input1Password, input1RunDuration) = benchmark { inputSolver1.run() }

print()
print("Input Password: \(input1Password)")
print("-   Parse: \(input1ParseDuration.formatted(.benchmark))")
print("-     Run: \(input1RunDuration.formatted(.benchmark))")
print("-   Total: \((input1ParseDuration + input1RunDuration).formatted(.benchmark))")

print()
print("== Part 2 ==")

let (sampleSolver2, sample2ParseDuration) = benchmark { Solver2(data: SampleData) }
let (sample2Password, sample2RunDuration) = benchmark { sampleSolver2.run() }

print()
print("Sample Password: \(sample2Password)")
print("-   Parse: \(sample2ParseDuration.formatted(.benchmark))")
print("-     Run: \(sample2RunDuration.formatted(.benchmark))")
print("-   Total: \((sample2ParseDuration + sample2RunDuration).formatted(.benchmark))")

let (inputSolver2, input2ParseDuration) = benchmark { Solver2(data: InputData, shouldPrint: false) }
let (input2Password, input2RunDuration) = benchmark { inputSolver2.run() }

print()
print("Input Password: \(input2Password)")
print("-   Parse: \(input2ParseDuration.formatted(.benchmark))")
print("-     Run: \(input2RunDuration.formatted(.benchmark))")
print("-   Total: \((input2ParseDuration + input2RunDuration).formatted(.benchmark))")
