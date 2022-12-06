//
//  ShipyardContext.swift
//  Day 05 - Visualized
//
//  Created by Stephen Gerstacker on 2022-12-05.
//  Copyright © 2022 Stephen H. Gerstacker. All rights reserved.
//

import Foundation
import QuartzCore
import Visualization
import simd

class ShipyardContext: Solution3DContext {
    
    private let craneMode: Shipyard.CraneMode = .model9000
    private let inputData: String = InputData
    
    private var crateUnitScale: simd_float4x4 = matrix_identity_float4x4
    private var maxStacks: Int = 0
    private var maxHeight: Int = .min
    private var left: Float = 0.0
    private var bottom: Float = 0.0
    
    override var name: String {
        "Day 05"
    }
    
    override func run() async throws {
        // Load the initial assets needed to build the nodes
        try loadMesh(name: "Crate", fromResource: "Wooden_Crate")
        crateUnitScale = unitScale(forMesh: "Crate")
        
        // Run the simulation one time to get the maximum height and load all the nodes
        let testShipyard = Shipyard(mode: craneMode, shouldDump: false)
        
        for line in inputData.components(separatedBy: "\n") {
            let previousMode = testShipyard.parserMode
            testShipyard.parseLine(line)
            
            if testShipyard.parserMode == .moves && previousMode == .crates {
                for (stackIndex, stack) in testShipyard.stacks.enumerated() {
                    let numberText = String(stackIndex + 1)
                    
                    createTexture(name: "Number \(stackIndex + 1)", width: 512, height: 512) { context in
                        let rect = CGRect(x: 0, y: 0, width: context.width, height: context.height)
                        let font = NativeFont(name: "Chalkduster", size: 160.0)
                        let color = CGColor.white
                        
                        let finalRect = CGRect(x: rect.origin.x, y: CGFloat(context.height) - rect.origin.y - rect.size.height, width: rect.size.width, height: rect.size.height)
                        
                        let textAttributed = NSAttributedString(string: numberText)
                        
                        let cfText = CFAttributedStringCreateMutableCopy(kCFAllocatorDefault, numberText.count, textAttributed)!
                        let cfTextLength = CFAttributedStringGetLength(cfText)
                        
                        let textRange = CFRange(location: 0, length: cfTextLength)
                        
                        CFAttributedStringSetAttribute(cfText, textRange, kCTFontAttributeName, font)
                        CFAttributedStringSetAttribute(cfText, textRange, kCTForegroundColorAttributeName, color)
                        
                        let maxSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
                        let frameSetter = CTFramesetterCreateWithAttributedString(cfText)
                        let textSize = CTFramesetterSuggestFrameSizeWithConstraints(frameSetter, textRange, nil, maxSize, nil)
                        
                        let xOffset = (finalRect.width - textSize.width) / 2.0
                        let yOffset = (finalRect.height - textSize.height) / 2.0
                        
                        let centeredFrame = finalRect.insetBy(dx: xOffset, dy: yOffset)
                        
                        let path = CGMutablePath()
                        path.addRect(centeredFrame)
                        
                        let ctFrame = CTFramesetterCreateFrame(frameSetter, textRange, path, nil)
                        
                        CTFrameDraw(ctFrame, context)
                    }
                    
                    try loadPlaneMesh(name: "Number Plane \(stackIndex + 1)", extents: SIMD3<Float>(1, 0, 1), emissiveTexture: "Number \(stackIndex + 1)")
                    
                    addNode(name: "Number \(stackIndex + 1)", mesh: "Number Plane \(stackIndex + 1)")
                    
                    for crate in stack {
                        let letterName = "Letter \(crate.value)"
                        
                        if !textureExists(name: letterName) {
                            createTexture(name: letterName, width: 256, height: 256) { context in
                                let rect = CGRect(x: 0, y: 0, width: context.width, height: context.height)
                                let font = NativeFont(name: "Chalkduster", size: 80.0)
                                let color = CGColor.white
                                
                                let finalRect = CGRect(x: rect.origin.x, y: CGFloat(context.height) - rect.origin.y - rect.size.height, width: rect.size.width, height: rect.size.height)
                                
                                let textAttributed = NSAttributedString(string: crate.value)
                                
                                let cfText = CFAttributedStringCreateMutableCopy(kCFAllocatorDefault, crate.value.count, textAttributed)!
                                let cfTextLength = CFAttributedStringGetLength(cfText)
                                
                                let textRange = CFRange(location: 0, length: cfTextLength)
                                
                                CFAttributedStringSetAttribute(cfText, textRange, kCTFontAttributeName, font)
                                CFAttributedStringSetAttribute(cfText, textRange, kCTForegroundColorAttributeName, color)
                                
                                let maxSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
                                let frameSetter = CTFramesetterCreateWithAttributedString(cfText)
                                let textSize = CTFramesetterSuggestFrameSizeWithConstraints(frameSetter, textRange, nil, maxSize, nil)
                                
                                let xOffset = (finalRect.width - textSize.width) / 2.0
                                let yOffset = (finalRect.height - textSize.height) / 2.0
                                
                                let centeredFrame = finalRect.insetBy(dx: xOffset, dy: yOffset)
                                
                                let path = CGMutablePath()
                                path.addRect(centeredFrame)
                                
                                let ctFrame = CTFramesetterCreateFrame(frameSetter, textRange, path, nil)
                                
                                CTFrameDraw(ctFrame, context)
                            }
                            
                            try loadPlaneMesh(name: "Letter Plane \(crate.value)", extents: SIMD3<Float>(2, 2, 0), baseColorTexture: letterName)
                        }
                        
                        addNode(name: "Crate \(crate.id)", mesh: "Crate", batch: "Crate")
                        addNode(name: "Crate \(crate.id) Letter", mesh: "Letter Plane \(crate.value)", parent: "Crate \(crate.id)")
                        
                        let rotate = simd_float4x4(rotateAbout: SIMD3<Float>(1, 0, 0), byAngle: .pi)
                        let translate = simd_float4x4(translate: SIMD3<Float>(0, 0, 1.0))
                        let transform = translate * rotate
                        
                        updateNode(name: "Crate \(crate.id) Letter", transform: transform)
                    }
                }
                
                maxStacks = testShipyard.stacks.count
            }
            
            if testShipyard.parserMode == .moves {
                let currentMaxHeight = testShipyard.stacks.map { $0.count }.max() ?? 0
                maxHeight = max(currentMaxHeight, maxHeight)
            }
        }
    
        // Complete the scene
        left = (Float(maxStacks) / -2.0) + 0.5
        bottom = (Float(maxHeight) / -2.0) + 0.5
        
        addDirectLight(name: "Sun", lookAt: SIMD3<Float>(0, 0, 0), from: SIMD3<Float>(1, -1, 1), up: SIMD3<Float>(0, 1, 0), intensity: 1)
        
        addPointLight(name: "Point 1", intensity: 200)
        updateLight(name: "Point 1", transform: simd_float4x4(translate: SIMD3<Float>(0, bottom, 10)))
        
        addPointLight(name: "Point 2", intensity: 200)
        updateLight(name: "Point 2", transform: simd_float4x4(translate: SIMD3<Float>(0, -bottom, 10)))
        
        addPointLight(name: "Point 3", intensity: 200)
        updateLight(name: "Point 3", transform: simd_float4x4(translate: SIMD3<Float>(0, 0, 10)))
        
        updateCamera(eye: SIMD3<Float>(0, 0, 20), lookAt: SIMD3<Float>(0, bottom, -30), up: SIMD3<Float>(0, 1, 0))
        
        for stackIndex in (0 ..< testShipyard.stacks.count) {
            updateNode(
                name: "Number \(stackIndex + 1)",
                transform: simd_float4x4(translate: SIMD3<Float>(left + Float(stackIndex), bottom - 0.5, 1)),
                baseColor: SIMD4<Float>(0, 0, 0, 1)
            )
        }
        
        // Run the simulation again, this time rendering the results
        let shipyard = Shipyard(mode: .model9000, shouldDump: false)
        
        for line in inputData.components(separatedBy: "\n") {
            shipyard.parseLine(line)
            
            if shipyard.parserMode == .moves {
                let currentMaxHeight = shipyard.stacks.map { $0.count }.max() ?? 0
                
                if !shipyard.lastMoves.isEmpty {
                    // Set the stage for the non-moving crates
                    update(shipyard: shipyard)
                    
                    // Set the stage for the moving crates to their original spots
                    for lastMove in shipyard.lastMoves {
                        for (crateIndex, crate) in lastMove.crates.enumerated() {
                            let scale = crateUnitScale
                            let rotation = matrix_identity_float4x4
                            let translation = simd_float4x4(translate: SIMD3<Float>(left + Float(lastMove.sourceColumn), bottom + Float(lastMove.sourceRow + crateIndex), 0.0))
                            
                            let transform = translation * rotation * scale
                            
                            let name = "Crate \(crate.id)"
                            updateNode(name: name, transform: transform)
                        }
                    }
                    
                    for lastMove in shipyard.lastMoves {
                        try animate(crates: lastMove.crates, startX: lastMove.sourceColumn, startY: lastMove.sourceRow, endX: lastMove.sourceColumn, endY: currentMaxHeight)
                        try animate(crates: lastMove.crates, startX: lastMove.sourceColumn, startY: currentMaxHeight, endX: lastMove.targetColumn, endY: currentMaxHeight)
                        try animate(crates: lastMove.crates, startX: lastMove.targetColumn, startY: currentMaxHeight, endX: lastMove.targetColumn, endY: lastMove.targetRow)
                    }
                } else {
                    update(shipyard: shipyard)
                    
                    for _ in 0 ..< 60 {
                        try snapshot()
                    }
                }
            }
        }
    }
    
    private func animate(crates: [Shipyard.Crate], startX: Int, startY: Int, endX: Int, endY: Int) throws {
        let xDistance = endX - startX
        let yDistance = endY - startY
        let distance = sqrt(Float(xDistance * xDistance) + Float(yDistance * yDistance))
        
        let timePerUnit: Float = 0.1
        let totalTime = timePerUnit * distance
        let totalFrames = Int(round(totalTime * Float(frameRate)))
        
        for frame in (0 ..< totalFrames) {
            let progress = Float(frame) / Float(totalFrames)
            let curvedProgress = easeInOutQuad(progress)
            
            let xOffset = lerp(start: Float(startX), end: Float(endX), percent: curvedProgress)
            
            for (crateIndex, crate) in crates.enumerated() {
                let yOffset = lerp(start: Float(startY + crateIndex), end: Float(endY + crateIndex), percent: curvedProgress)
                
                let scale = crateUnitScale
                let rotation = matrix_identity_float4x4
                let translation = simd_float4x4(translate: SIMD3<Float>(left + xOffset, bottom + yOffset, 0.0))
                
                let transform = translation * rotation * scale
                
                let crateName = "Crate \(crate.id)"
                updateNode(name: crateName, transform: transform)
            }
            
            try snapshot()
        }
    }
    
    private func update(shipyard: Shipyard) {
        for (stackIndex, stack) in shipyard.stacks.enumerated() {
            for (crateIndex, crate) in stack.enumerated() {
                let scale = crateUnitScale
                let rotation = matrix_identity_float4x4
                let translation = simd_float4x4(translate: SIMD3<Float>(left + Float(stackIndex), bottom + Float(crateIndex), 0.0))

                let transform = translation * rotation * scale
                
                let name = "Crate \(crate.id)"
                updateNode(name: name, transform: transform)
            }
        }
    }
}
