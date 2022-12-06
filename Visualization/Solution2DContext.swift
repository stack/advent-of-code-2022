//
//  Solution2DContext.swift
//  Advent of Code 2022 Common
//
//  Created by Stephen H. Gerstacker on 2022-11-03.
//  Copyright © 2022 Stephen H. Gerstacker. All rights reserved.
//

import AVFoundation
import Combine
import Foundation
import Utilities

#if os(macOS)
import AppKit

public typealias NativeColor = NSColor
public typealias NativeFont = NSFont

#else
import UIKit

public typealias NativeColor = UIColor
public typealias NativeFont = UIFont

#endif

open class Solution2DContext: SolutionContext {
    
    // MARK: - Properties
    
    private var lastPixelBuffer: CVPixelBuffer? = nil
    
    // MARK: - Drawing
    
    public func discard(context: CGContext, pixelBuffer: CVPixelBuffer) {
        CVPixelBufferUnlockBaseAddress(pixelBuffer, [])
    }
    
    public func nextContext() throws -> (CGContext, CVPixelBuffer) {
        guard let pool = writerAdaptor?.pixelBufferPool else {
            throw SolutionError.apiError("No pixel buffer pool available")
        }
        
        var pixelBuffer: CVPixelBuffer? = nil
        CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pool, &pixelBuffer)
        
        guard let pixelBuffer else {
            throw SolutionError.apiError("Pixel buffer pool is out of pixel buffers")
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        
        let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let stride = CVPixelBufferGetBytesPerRow(pixelBuffer)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        guard let context = CGContext(
            data: baseAddress,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: stride,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue + CGBitmapInfo.byteOrder32Little.rawValue
        ) else {
            throw SolutionError.apiError("Failed to create context from pixel buffer")
        }
        
        context.setAllowsFontSmoothing(true)
        context.setShouldSmoothFonts(true)
        
        return (context, pixelBuffer)
    }
    
    public func repeatLastFrame() {
        guard let pixelBuffer = lastPixelBuffer else { return }
        
        submit(pixelBuffer: pixelBuffer)
    }
    
    public func submit(context: CGContext, pixelBuffer: CVPixelBuffer) {
        CVPixelBufferUnlockBaseAddress(pixelBuffer, [])
        
        submit(pixelBuffer: pixelBuffer)
    }
    
    override func submit(pixelBuffer: CVPixelBuffer) {
        self.lastPixelBuffer = pixelBuffer
        
        super.submit(pixelBuffer: pixelBuffer)
    }
    
    // MARK: - Drawing Utilities
    
    public func draw(text: String, color: CGColor, font: NativeFont, rect: CGRect, in context: CGContext) {
        let finalRect = CGRect(x: rect.origin.x, y: CGFloat(context.height) - rect.origin.y - rect.size.height, width: rect.size.width, height: rect.size.height)
        
        let textAttributed = NSAttributedString(string: text)
        
        let cfText = CFAttributedStringCreateMutableCopy(kCFAllocatorDefault, text.count, textAttributed)!
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
    
    public func fill(rect: CGRect, color: CGColor, in context: CGContext) {
        let finalRect = CGRect(x: rect.origin.x, y: CGFloat(context.height) - rect.origin.y - rect.size.height, width: rect.size.width, height: rect.size.height)
        
        context.setFillColor(color)
        context.fill(finalRect)
    }
    
    public func stroke(rect: CGRect, color: CGColor, in context: CGContext) {
        let finalRect = CGRect(x: rect.origin.x, y: CGFloat(context.height) - rect.origin.y - rect.size.height, width: rect.size.width, height: rect.size.height)
        
        context.setStrokeColor(color)
        context.stroke(finalRect)
    }
}
