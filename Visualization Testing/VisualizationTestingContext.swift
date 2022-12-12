//
//  VisualizationTestingContext.swift
//  VisualizationTesting
//
//  Created by Stephen H. Gerstacker on 2022-11-03.
//  SPDX-License-Identifier: MIT
//

import Foundation
import QuartzCore
import Visualization

class VisualizationTestingContext: Solution2DContext {
    
    override var name: String {
        "Visualization Testing"
    }
    
    override func run() async throws {
        let boxSize = floor(CGFloat(width) / 3.0)
        
        let redBox = CGRect(x: 0.0, y: 0.0, width: boxSize, height: boxSize).insetBy(dx: 1.0, dy: 1.0)
        let greenBox = CGRect(x: boxSize, y: 0.0, width: boxSize, height: boxSize).insetBy(dx: 1.0, dy: 1.0)
        let blueBox = CGRect(x: boxSize * 2, y: 0.0, width: boxSize, height: boxSize).insetBy(dx: 1.0, dy: 1.0)
        
        let yellowBox = CGRect(x: 0.0, y: boxSize, width: boxSize, height: boxSize).insetBy(dx: 1.0, dy: 1.0)
        let magentaBox = CGRect(x: boxSize, y: boxSize, width: boxSize, height: boxSize).insetBy(dx: 1.0, dy: 1.0)
        let cyanBox = CGRect(x: boxSize * 2, y: boxSize, width: boxSize, height: boxSize).insetBy(dx: 1.0, dy: 1.0)
        
        let whiteBox = CGRect(x: 0.0, y: boxSize * 2, width: boxSize, height: boxSize).insetBy(dx: 1.0, dy: 1.0)
        let grayBox = CGRect(x: boxSize, y: boxSize * 2, width: boxSize, height: boxSize).insetBy(dx: 1.0, dy: 1.0)
        let blackBox = CGRect(x: boxSize * 2, y: boxSize * 2, width: boxSize, height: boxSize).insetBy(dx: 1.0, dy: 1.0)
        
        let textColor = CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        let font1 = NativeFont.boldSystemFont(ofSize: boxSize * 0.5)
        let font2 = NativeFont.boldSystemFont(ofSize: boxSize * 0.25)
        let font3 = NativeFont.systemFont(ofSize: boxSize * 0.5)
        
        for t in stride(from: 0.0, through: 100.0, by: 0.01) {
            let alphaValue = (cos(t) + 1.0) / 2.0
            
            let (context, pixelBuffer) = try nextContext()
            
            let redColor = CGColor(red: 1.0 * alphaValue, green: 0.0, blue: 0.0, alpha: 1.0)
            let greenColor = CGColor(red: 0.0, green: 1.0 * alphaValue, blue: 0.0, alpha: 1.0)
            let blueColor = CGColor(red: 0.0, green: 0.0, blue: 1.0 * alphaValue, alpha: 1.0)
            
            let yellowColor = CGColor(red: 1.0 * alphaValue, green: 1.0 * alphaValue, blue: 0.0, alpha: 1.0)
            let magentaColor = CGColor(red: 1.0 * alphaValue, green: 0.0, blue: 1.0 * alphaValue, alpha: 1.0)
            let cyanColor = CGColor(red: 0.0, green: 1.0 * alphaValue, blue: 1.0 * alphaValue, alpha: 1.0)
            
            let whiteColor = CGColor(red: 1.0 * alphaValue, green: 1.0 * alphaValue, blue: 1.0 * alphaValue, alpha: 1.0)
            let grayColor = CGColor(red: 0.5 * alphaValue, green: 0.5 * alphaValue, blue: 0.5 * alphaValue, alpha: 1.0)
            let blackColor = CGColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
            
            let backgroundRect = CGRect(x: 0, y: 0, width: context.width, height: context.height)
            
            context.setFillColor(blackColor)
            context.fill(backgroundRect)
            
            fill(rect: redBox, color: redColor, in: context)
            fill(rect: greenBox, color: greenColor, in: context)
            fill(rect: blueBox, color: blueColor, in: context)
            
            fill(rect: yellowBox, color: yellowColor, in: context)
            fill(rect: magentaBox, color: magentaColor, in: context)
            fill(rect: cyanBox, color: cyanColor, in: context)
            
            fill(rect: whiteBox, color: whiteColor, in: context)
            fill(rect: grayBox, color: grayColor, in: context)
            fill(rect: blackBox, color: blackColor, in: context)
            
            draw(text: "1", color: textColor, font: font1, rect: redBox, in: context)
            draw(text: "2", color: textColor, font: font1, rect: greenBox, in: context)
            draw(text: "3", color: textColor, font: font1, rect: blueBox, in: context)
            
            draw(text: "One", color: textColor, font: font2, rect: yellowBox, in: context)
            draw(text: "Two", color: textColor, font: font2, rect: magentaBox, in: context)
            draw(text: "Three", color: textColor, font: font2, rect: cyanBox, in: context)
            
            draw(text: "🍄", color: textColor, font: font3, rect: whiteBox, in: context)
            draw(text: "🐙", color: textColor, font: font3, rect: grayBox, in: context)
            draw(text: "🦊", color: textColor, font: font3, rect: blackBox, in: context)

            submit(context: context, pixelBuffer: pixelBuffer)
        }
    }
}
