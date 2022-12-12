//
//  SolutionRenderer.swift
//  Advent of Code 2022 Common
//
//  Created by Stephen H. Gerstacker on 2022-11-03.
//  SPDX-License-Identifier: MIT
//

import Foundation
import Metal
import MetalKit

fileprivate let MaxOutstandingFrameCount = 3

class SolutionRenderer {
    
    private struct Vertex {
        let position: SIMD2<Float>
        let textureCoordinate: SIMD2<Float>
        
        init(x: Float, y: Float, u: Float, v: Float) {
            position = SIMD2<Float>(x, y)
            textureCoordinate = SIMD2<Float>(u, v)
        }
    }
    
    let metalDevice: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let pipelineState: MTLRenderPipelineState
    private let textureCache: CVMetalTextureCache
    private let vertexBuffer: MTLBuffer
    
    private var screenSize: SIMD2<Float> = .zero
    private var textureSize: SIMD2<Float> = .zero
    
    private let verticesSize: Int
    private let verticesStride: Int
    private var verticesBufferOffset: Int
    
    private var nextPixelBuffer: CVPixelBuffer? = nil
    private var nextPixelBufferLock = NSLock()
    
    private var currentMetalTexture: CVMetalTexture? = nil
    private var currentTexture: MTLTexture? = nil
    private var currentPixelBuffer: CVPixelBuffer? = nil
    
    private var frameIndex: Int = 0
    private var frameSemaphore = DispatchSemaphore(value: MaxOutstandingFrameCount)
    
    init() {
        metalDevice = MTLCreateSystemDefaultDevice()!
        commandQueue = metalDevice.makeCommandQueue()!
        
        let bundle = Bundle(for: SolutionRenderer.self)
        let library = try! metalDevice.makeDefaultLibrary(bundle: bundle)
        let vertexFunction = library.makeFunction(name: "VertexShader")
        let fragmentFunction = library.makeFunction(name: "FragmentShader")
        
        let vertexDescriptor = MTLVertexDescriptor()
        
        vertexDescriptor.attributes[0].format = .float2
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        
        vertexDescriptor.attributes[1].format = .float2
        vertexDescriptor.attributes[1].offset = MemoryLayout<Float>.stride * 2
        vertexDescriptor.attributes[1].bufferIndex = 0
        
        vertexDescriptor.layouts[0].stride = MemoryLayout<Float>.stride * 4
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.label = "Solution Pipeline"
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        
        pipelineState = try! metalDevice.makeRenderPipelineState(descriptor: pipelineDescriptor)
        
        var textureCache: CVMetalTextureCache? = nil
        CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, metalDevice, nil, &textureCache)
        
        self.textureCache = textureCache!
        
        verticesSize = MemoryLayout<Float>.size * 2
        verticesStride = align(verticesSize, upTo: 256)
        verticesBufferOffset = 0
        
        vertexBuffer = metalDevice.makeBuffer(length: verticesStride * MaxOutstandingFrameCount, options: .storageModeShared)!
    }
    
    func draw(drawable: MTLDrawable, renderPassDescriptor: MTLRenderPassDescriptor) {
        // Don't render if the screen dimensions contain 0
        guard screenSize.x > 0 && screenSize.y > 0 else { return }
        
        // Prepare the render pass
        guard let commandBuffer = commandQueue.makeCommandBuffer() else { return }
        
        commandBuffer.label = "Solution Draw Command Buffer"
        
        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }
        
        encoder.label = "Solution Render Command Encoder"
        
        frameSemaphore.wait()
        
        // Quickly swap pixel buffers to prevent too long of a lock
        nextPixelBufferLock.lock()
        let potentialPixelBuffer = nextPixelBuffer
        nextPixelBuffer = nil
        nextPixelBufferLock.unlock()
        
        // Create the next texture if it's needed
        if let pixelBuffer = potentialPixelBuffer {
            currentPixelBuffer = pixelBuffer
            
            // NOTE: You must nil this, as the creation method below overwrites pointers and
            // doesn't free the previous value
            currentMetalTexture = nil
            
            CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, textureCache, pixelBuffer, nil, .bgra8Unorm, CVPixelBufferGetWidth(pixelBuffer), CVPixelBufferGetHeight(pixelBuffer), 0, &currentMetalTexture)
            
            if let currentMetalTexture {
                currentTexture = CVMetalTextureGetTexture(currentMetalTexture)
            } else {
                currentTexture = nil
            }
            
            if let currentTexture {
                textureSize = SIMD2<Float>(Float(currentTexture.width), Float(currentTexture.height))
            } else {
                textureSize = .zero
            }
        }
        
        // Present the texture if it exists
        if let currentTexture, textureSize.x > 0 && textureSize.y > 0 {
            let screenAspectRatio = screenSize.x / screenSize.y
            let textureAspectRatio = textureSize.x / textureSize.y
            
            let textureFitSize: SIMD2<Float>
            
            if textureAspectRatio > screenAspectRatio {
                textureFitSize = SIMD2<Float>(screenSize.x, screenSize.x / textureAspectRatio)
            } else {
                textureFitSize = SIMD2<Float>(screenSize.y * textureAspectRatio, screenSize.y)
            }
            
            let textureOffset = (screenSize - textureFitSize) / screenSize
            
            var vertices: [Float] = [
                //         x                       y             u    v
                -1.0 + textureOffset.x,  1.0 - textureOffset.y, 0.0, 0.0,
                 1.0 - textureOffset.x,  1.0 - textureOffset.y, 1.0, 0.0,
                -1.0 + textureOffset.x, -1.0 + textureOffset.y, 0.0, 1.0,
                 1.0 - textureOffset.x, -1.0 + textureOffset.y, 1.0, 1.0,
            ]
            
            verticesBufferOffset = (frameIndex % MaxOutstandingFrameCount) * verticesStride
            
            let verticesData = vertexBuffer.contents().advanced(by: verticesBufferOffset)
            verticesData.copyMemory(from: &vertices, byteCount: verticesStride)
            
            encoder.setRenderPipelineState(pipelineState)
            encoder.setFragmentTexture(currentTexture, index: 0)
            encoder.setVertexBuffer(vertexBuffer, offset: verticesBufferOffset, index: 0)
            
            encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        }
        
        // Finish the render pass
        encoder.endEncoding()
        
        commandBuffer.addCompletedHandler { [weak self] _ in
            guard let self else { return }
            
            self.frameSemaphore.signal()
        }
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
        
        frameIndex += 1
    }
    
    func resize(_ size: CGSize) {
        screenSize = SIMD2<Float>(Float(size.width), Float(size.height))
    }
    
    func setNextPixelBuffer(_ pixelBuffer: CVPixelBuffer) {
        nextPixelBufferLock.lock()
        nextPixelBuffer = pixelBuffer
        nextPixelBufferLock.unlock()
    }
}
