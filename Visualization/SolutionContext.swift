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
    var writerAdaptor: AVAssetWriterInputPixelBufferAdaptor? = nil
    private var writerQueue: DispatchQueue = DispatchQueue(label: "us.gerstacker.advent-of-code.asset-writer")
    
    private let writerReadyCondition = NSCondition()
    
    private var currentFrameTime: CMTime = .zero
    private var frameTimeStep: CMTime
    
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
    
    func submit(pixelBuffer: CVPixelBuffer) {
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
    
    // MARK: - Running
    
    open func run() async throws {
        throw SolutionError.apiError("Subclasses must implement their own run method")
    }
}
