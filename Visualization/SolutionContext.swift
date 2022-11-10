//
//  SolutionContext.swift
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

open class SolutionContext: ObservableObject {
    
    // MARK: - Properties
    
    @Published public var width: Int
    @Published public var height: Int
    @Published public var frameRate: Double
    
    @Published public var isPrepapred: Bool = false
    
    let renderer = SolutionRenderer()
    
    open var name: String {
        fatalError("Solution context name not set")
    }
    
    private var writer: AVAssetWriter? = nil
    private var writerInput: AVAssetWriterInput? = nil
    private var writerAdaptor: AVAssetWriterInputPixelBufferAdaptor? = nil
    private var writerQueue: DispatchQueue = DispatchQueue(label: "us.gerstacker.advent-of-code.asset-writer")
    
    private let writerReadyCondition = NSCondition()
    
    private var currentFrameTime: CMTime = .zero
    private var frameTimeStep: CMTime
    private var lastPixelBuffer: CVPixelBuffer? = nil
    
    private var cancellables: [AnyCancellable] = []
    
    
    // MARK: - Initialization
    
    public init(width: Int, height: Int, frameRate: Double) {
        precondition(width % 2 == 0)
        precondition(height % 2 == 0)
        
        self.width = width
        self.height = height
        self.frameRate = frameRate
        
        frameTimeStep = CMTime(seconds: 1.0 / frameRate, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
    }
    
    public func prepare(url: URL) async throws {
        await MainActor.run {
            isPrepapred = false
        }
        
        // Remove the previous recording if it exists
        if FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) {
            try FileManager.default.removeItem(at: url)
        }
        
        // Build the asset writer and its inputs
        let writer = try AVAssetWriter(url: url, fileType: .mp4)
        
        let videoSettings: [String:Any] = [
            AVVideoCodecKey: AVVideoCodecType.hevc,
            AVVideoWidthKey: NSNumber(value: width),
            AVVideoHeightKey: NSNumber(value: height)
        ]
        
        let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        
        let sourceAttributes: [String:Any] = [
            String(kCVPixelBufferPixelFormatTypeKey): NSNumber(value: kCVPixelFormatType_32BGRA),
            String(kCVPixelBufferMetalCompatibilityKey): NSNumber(value: true)
        ]
        
        let writerAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: writerInput, sourcePixelBufferAttributes: sourceAttributes)
        
        guard writer.canAdd(writerInput) else {
            throw SolutionError.apiError("Cannot add input to writer")
        }

        writer.add(writerInput)
        
        guard writer.startWriting() else {
            if let error = writer.error {
                throw SolutionError.wrapped("Could not start writing", error)
            } else {
                throw SolutionError.apiError("Could not start writing for an unknown reason")
            }
        }
        
        // Store the asset writer objects
        self.writer = writer
        self.writerInput = writerInput
        self.writerAdaptor = writerAdaptor
        
        // Start the session
        writer.startSession(atSourceTime: currentFrameTime)
        
        writerInput
            .publisher(for: \.isReadyForMoreMediaData)
            .sink { [weak self] isReady in
                guard let self else { return }
                guard isReady else { return }
                
                self.writerReadyCondition.lock()
                self.writerReadyCondition.signal()
                self.writerReadyCondition.unlock()
            }
            .store(in: &cancellables)
        
        await MainActor.run {
            isPrepapred = true
        }
    }
    
    // MARK: - Drawing
    
    public func complete() async throws {
        guard let writer else { return }
        guard let writerInput else { return }
    
        writerInput.markAsFinished()
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            writer.finishWriting {
                if writer.status == .failed {
                    if let error = writer.error {
                        continuation.resume(throwing: SolutionError.wrapped("Failed to finish writing", error))
                    } else {
                        continuation.resume(throwing: SolutionError.apiError("Failed to finish writing for an unknown reason"))
                    }
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
    
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
    
    private func submit(pixelBuffer: CVPixelBuffer) {
        self.lastPixelBuffer = pixelBuffer
        
        renderer.setNextPixelBuffer(pixelBuffer)
        
        guard let writerInput = self.writerInput else { return }
        guard let writerAdaptor = self.writerAdaptor else { return }
        
        self.writerReadyCondition.lock()
        
        while !writerInput.isReadyForMoreMediaData {
            self.writerReadyCondition.wait()
        }
        
        self.writerReadyCondition.unlock()
        
        writerAdaptor.append(pixelBuffer, withPresentationTime: self.currentFrameTime)
        self.currentFrameTime = CMTimeAdd(self.currentFrameTime, self.frameTimeStep)
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
    
    // MARK: - Running
    
    open func run() async throws {
        throw SolutionError.apiError("Subclasses must implement their own run method")
    }
}
