//
//  Solution3DContext.swift
//  Visualization
//
//  Created by Stephen H. Gerstacker on 2022-11-12.
//  Copyright © 2022 Stephen H. Gerstacker. All rights reserved.
//

import AVFoundation
import Combine
import Foundation
import Metal
import MetalKit
import ModelIO
import Utilities

fileprivate let MaxOutstandingFrameCount = 3
fileprivate let MaxConstantsSize = 1024 * 1024
fileprivate let MinBufferAlignment = 256

fileprivate let DefaultAmbientColor = SIMD3<Float>(0.2, 0.2, 0.2)
fileprivate let DefaultDiffuseColor = SIMD3<Float>(0.8, 0.8, 0.8)
fileprivate let DefaultSpecularColor = SIMD3<Float>(1.0, 1.0, 1.0)
fileprivate let DefaultSpecularExponent: Float = 0.0

fileprivate struct Material {
    var ambientColor: SIMD3<Float>
    var diffuseColor: SIMD3<Float>
    var specularColor: SIMD3<Float>
    var specularExponent: Float
    
    init() {
        ambientColor = DefaultAmbientColor
        diffuseColor = DefaultDiffuseColor
        specularColor = DefaultSpecularColor
        specularExponent = DefaultSpecularExponent
    }
    
    init(ambientColor: SIMD3<Float>, diffuseColor: SIMD3<Float>, specularColor: SIMD3<Float>, specularExponent: Float) {
        self.ambientColor = ambientColor
        self.diffuseColor = diffuseColor
        self.specularColor = specularColor
        self.specularExponent = specularExponent
    }
}

fileprivate class Node {
    
    weak var parentNode: Node?
    private(set) var childNodes: [Node] = []
    
    var name: String = ""
    var mesh: MTKMesh?
    var texture: MTLTexture?
    var baseColor = SIMD3<Float>(1, 1, 1)
    var material: Material = Material()
    
    var transform: simd_float4x4 = matrix_identity_float4x4
    
    var worldTransform: simd_float4x4 {
        if let parentNode {
            return parentNode.worldTransform * transform
        } else {
            return transform
        }
    }
    
    var position: SIMD3<Float> {
        return worldTransform.columns.3.xyz
    }
    
    init() { }
    
    init(mesh: MTKMesh) {
        self.mesh = mesh
    }
    
    func addChildNode(_ node: Node) {
        childNodes.append(node)
        node.parentNode = self
    }
    
    func removeFromParent() {
        parentNode?.removeChildNode(self)
    }
    
    private func removeChildNode(_ node: Node) {
        childNodes.removeAll { $0 === node }
    }
}

fileprivate class Light {
    
    enum LightType : UInt32 {
        case ambient
        case directional
        case omni
    }
    
    var name: String = ""
    var type = LightType.directional
    var color = SIMD3<Float>(1, 1, 1)
    var intensity: Float = 1.0

    var worldTransform: simd_float4x4 = matrix_identity_float4x4

    var position: SIMD3<Float> {
        return worldTransform.columns.3.xyz
    }

    var direction: SIMD3<Float> {
        return -worldTransform.columns.2.xyz
    }

    var projectionMatrix: simd_float4x4 {
        let width: Float = 1.5
        let depth: Float = 10.0
        
        return simd_float4x4(
            orthographicProjectionWithLeft: -width,
            top: width,
            right: width,
            bottom: -width,
            near: 0,
            far: depth
        )
    }
}

fileprivate struct NodeConstants {
    var modelMatrix: float4x4
    var baseColor: simd_float3
    var ambientColor: simd_float3
    var diffuseColor: simd_float3
    var specularColor: simd_float3
    var specularExponent: Float
}

fileprivate struct FrameConstants {
    var projectionMatrix: float4x4
    var viewMatrix: float4x4
    var lightCount: UInt32
}

fileprivate struct LightConstants {
    var viewProjectionMatrix: simd_float4x4
    var intensity: simd_float3
    var position: simd_float3
    var direction: simd_float3
    var type: UInt32
}

fileprivate struct ShadowConstants {
    var modelViewProjectionMatrix: simd_float4x4
}

open class Solution3DContext: SolutionContext {
    
    // MARK: - Properties
    
    private var meshBufferAllocator: MTKMeshBufferAllocator!
    private var mdlVertexDescriptor: MDLVertexDescriptor!
    private var vertexDescriptor: MTLVertexDescriptor!
    
    private var textureLoader: MTKTextureLoader!
    private var textureOptions: [MTKTextureLoader.Option:Any]!
    private var textureCache: CVMetalTextureCache!
    
    private var meshes: [String:MTKMesh] = [:]
    private var meshTextures: [String:MTLTexture] = [:]
    private var meshMaterials: [String:Material] = [:]
    
    private var textures: [String:MTLTexture] = [:]
    
    private var pointOfView: Node!
    private var nodesTable: [String:Node] = [:]
    private var nodes: [Node] = []
    private var lightsTable: [String:Light] = [:]
    private var lights: [Light] = []
    
    private var commandQueue: MTLCommandQueue!
    private var constantBuffer: MTLBuffer!
    private var pipelineState: MTLRenderPipelineState!
    private var depthStencilState: MTLDepthStencilState!
    private var samplerState: MTLSamplerState!
    
    private let sampleCount = 4
    private var msaaTextures: [MTLTexture]!
    private var msaaDepthTextures: [MTLTexture]!
    private var depthTextures: [MTLTexture]!
    
    private var currentConstantBufferOffset = 0
    private var frameConstantsOffset = 0
    private var lightConstantsOffset = 0
    private var nodeConstantsOffset: [Int] = []
    private let frameSemaphor = DispatchSemaphore(value: MaxOutstandingFrameCount)
    private var frameIndex = 0
    
    
    // MARK: - Initialization
    
    public override init(width: Int, height: Int, frameRate: Double) {
        super.init(width: width, height: height, frameRate: frameRate)
        
        let device = renderer.metalDevice
        
        meshBufferAllocator = MTKMeshBufferAllocator(device: device)
        
        mdlVertexDescriptor = MDLVertexDescriptor()
        mdlVertexDescriptor.vertexAttributes[0].name = MDLVertexAttributePosition
        mdlVertexDescriptor.vertexAttributes[0].format = .float3
        mdlVertexDescriptor.vertexAttributes[0].offset = 0
        mdlVertexDescriptor.vertexAttributes[0].bufferIndex = 0
        mdlVertexDescriptor.vertexAttributes[1].name = MDLVertexAttributeNormal
        mdlVertexDescriptor.vertexAttributes[1].format = .float3
        mdlVertexDescriptor.vertexAttributes[1].offset = 12
        mdlVertexDescriptor.vertexAttributes[1].bufferIndex = 0
        mdlVertexDescriptor.vertexAttributes[2].name = MDLVertexAttributeTextureCoordinate
        mdlVertexDescriptor.vertexAttributes[2].format = .float2
        mdlVertexDescriptor.vertexAttributes[2].offset = 24
        mdlVertexDescriptor.vertexAttributes[2].bufferIndex = 0
        mdlVertexDescriptor.bufferLayouts[0].stride = 32
        
        vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(mdlVertexDescriptor)!
        
        textureLoader = MTKTextureLoader(device: device)
        textureOptions = [
            .textureUsage : MTLTextureUsage.shaderRead.rawValue,
            .textureStorageMode : MTLStorageMode.private.rawValue,
            .origin : MTKTextureLoader.Origin.bottomLeft.rawValue
        ]
        
        var textureCache: CVMetalTextureCache? = nil
        CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &textureCache)
        
        self.textureCache = textureCache!
        
        pointOfView = Node()
        
        commandQueue = device.makeCommandQueue()!
        commandQueue.label = "Solution 3D Command Queue"
        
        constantBuffer = device.makeBuffer(length: MaxConstantsSize, options: .storageModeShared)!
        constantBuffer.label = "Solution 3D Constant Buffer"
        
        let bundle = Bundle(for: Solution3DContext.self)
        let library = try! device.makeDefaultLibrary(bundle: bundle)
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.rasterSampleCount = sampleCount
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        pipelineDescriptor.vertexFunction = library.makeFunction(name: "SolutionVertex")
        pipelineDescriptor.fragmentFunction = library.makeFunction(name: "SolutionFragment")
        pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .one
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
        pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        pipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
        pipelineDescriptor.label = "Main Pipeline"
        
        pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        
        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.depthCompareFunction = .less
        depthStencilDescriptor.isDepthWriteEnabled = true
        
        depthStencilState = device.makeDepthStencilState(descriptor: depthStencilDescriptor)!
        
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.normalizedCoordinates = true
        samplerDescriptor.magFilter = .linear
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.mipFilter = .linear
        samplerDescriptor.sAddressMode = .repeat
        samplerDescriptor.tAddressMode = .repeat
        
        samplerState = device.makeSamplerState(descriptor: samplerDescriptor)!
        
        let msaaTextureDescriptor = MTLTextureDescriptor()
        msaaTextureDescriptor.textureType = .type2DMultisample
        msaaTextureDescriptor.sampleCount = sampleCount
        msaaTextureDescriptor.pixelFormat = .bgra8Unorm
        msaaTextureDescriptor.width = width
        msaaTextureDescriptor.height = height
        msaaTextureDescriptor.storageMode = .private
        msaaTextureDescriptor.usage = .renderTarget
        
        msaaTextures = (0 ..< MaxOutstandingFrameCount).map { _ in
            device.makeTexture(descriptor: msaaTextureDescriptor)!
        }
        
        let msaaDepthTextureDescriptor = MTLTextureDescriptor()
        msaaDepthTextureDescriptor.textureType = .type2DMultisample
        msaaDepthTextureDescriptor.sampleCount = sampleCount
        msaaDepthTextureDescriptor.pixelFormat = .depth32Float
        msaaDepthTextureDescriptor.width = width
        msaaDepthTextureDescriptor.height = height
        msaaDepthTextureDescriptor.storageMode = .private
        msaaDepthTextureDescriptor.usage = .renderTarget
        
        msaaDepthTextures = (0 ..< MaxOutstandingFrameCount).map { _ in
            device.makeTexture(descriptor: msaaDepthTextureDescriptor)!
        }
        
        let depthTextureDescriptor = MTLTextureDescriptor()
        depthTextureDescriptor.textureType = .type2D
        depthTextureDescriptor.sampleCount = 1
        depthTextureDescriptor.pixelFormat = .depth32Float
        depthTextureDescriptor.width = width
        depthTextureDescriptor.height = height
        depthTextureDescriptor.storageMode = .private
        depthTextureDescriptor.usage = .renderTarget
        
        depthTextures = (0 ..< MaxOutstandingFrameCount).map { _ in
            device.makeTexture(descriptor: depthTextureDescriptor)!
        }
        
        try! loadSphereMesh(name: "_LightBulb", extents: SIMD3<Float>(0.2, 0.2, 0.2), segments: SIMD2<UInt32>(5, 5), inwardNormals: false)
    }
    
    
    // MARK: - Asset Management
    
    public func addAmbientLight(name: String, intensity: Float, color: SIMD3<Float> = SIMD3<Float>(1, 1, 1)) {
        let light = Light()
        light.type = .ambient
        light.intensity = intensity
        light.color = color
        
        lightsTable[name] = light
        lights.append(light)
    }
    
    public func addDirectLight(name: String, lookAt target: SIMD3<Float>, from origin: SIMD3<Float>, up: SIMD3<Float>, color: SIMD3<Float> = SIMD3<Float>(1, 1, 1)) {
        let light = Light()
        light.type = .directional
        light.worldTransform = simd_float4x4(lookAt: target, from: origin, up: up)
        light.color = color
        
        lightsTable[name] = light
        lights.append(light)
    }
    
    public func addNode(name: String, mesh meshName: String, texture textureName: String? = nil, baseColor: SIMD3<Float> = SIMD3<Float>(1, 1, 1), ambientColor: SIMD3<Float>? = nil, diffuseColor: SIMD3<Float>? = nil, specularColor: SIMD3<Float>? = nil, specularExponent: Float? = nil, parent: String? = nil) throws {
        guard let mesh = meshes[meshName] else {
            throw SolutionError.apiError("Node \(name) cannot find mesh \(meshName)")
        }
        
        guard var material = meshMaterials[meshName] else {
            throw SolutionError.apiError("Node \(name) cannot find mesh material \(meshName)")
        }
        
        if let ambientColor { material.ambientColor = ambientColor }
        if let diffuseColor { material.diffuseColor = diffuseColor }
        if let specularColor { material.specularColor = specularColor }
        if let specularExponent { material.specularExponent = specularExponent }
        
        var texture: MTLTexture? = nil
        
        if let textureName, let nodeTexture = textures[textureName] {
            texture = nodeTexture
        } else if let nodeTexture = meshTextures[meshName] {
            texture = nodeTexture
        } else {
            // TODO: Set default white texture
        }
        
        let node = Node(mesh: mesh)
        node.name = name
        node.texture = texture
        node.baseColor = baseColor
        node.material = material
        
        nodesTable[name] = node
        nodes.append(node)
        
        if let parent, let parentNode = nodesTable[parent] {
            parentNode.addChildNode(node)
        }
    }
    
    public func addPointLight(name: String, intensity: Float, color: SIMD3<Float> = SIMD3<Float>(1, 1, 1)) {
        let light = Light()
        light.type = .omni
        light.color = color
        light.intensity = intensity
        
        lightsTable[name] = light
        lights.append(light)
    }
    
    private func convertPropertyToColor(_ property: MDLMaterialProperty) -> SIMD3<Float> {
        if property.type == .color || property.type == .texture {
            if let color = property.color {
                let components = color.components!
                
                if color.numberOfComponents == 1 { // Grayscale
                    return SIMD3<Float>(Float(components[0]), Float(components[0]), Float(components[0]))
                } else if color.numberOfComponents == 3 || color.numberOfComponents == 4 {
                    return SIMD3<Float>(Float(components[0]), Float(components[1]), Float(components[2]))
                } else {
                    fatalError("Could not convert \(color.numberOfComponents) components to a color")
                }
            } else {
                return SIMD3<Float>(repeating: 1)
            }
        } else if property.type == .float {
            return SIMD3<Float>(property.floatValue, property.floatValue, property.floatValue)
        } else if property.type == .float3 {
            return property.float3Value
        } else {
            fatalError("Could not convert property of type \(property.type) to a color")
        }
    }
    
    public func loadBoxMesh(name: String, extents: SIMD3<Float>, inwardNormals: Bool) throws {
        let mdlMesh = MDLMesh(
            boxWithExtent: extents,
            segments: SIMD3<UInt32>(1, 1, 1),
            inwardNormals: inwardNormals,
            geometryType: .triangles,
            allocator: meshBufferAllocator
        )
        
        let mtkMesh = try MTKMesh(mesh: mdlMesh, device: renderer.metalDevice)
        
        meshes[name] = mtkMesh
        meshMaterials[name] = Material()
    }
    
    public func loadMesh(name: String, resource: String, withExtension ext: String) throws {
        guard let url = Bundle.main.url(forResource: resource, withExtension: ext) else {
            throw SolutionError.apiError("No mesh resource for \(name)")
        }
        
        let mdlAsset = MDLAsset(url: url, vertexDescriptor: mdlVertexDescriptor, bufferAllocator: meshBufferAllocator)
        mdlAsset.loadTextures()
        
        let meshes = mdlAsset.childObjects(of: MDLMesh.self) as? [MDLMesh]
        
        guard let mdlMesh = meshes?.first else {
            throw SolutionError.apiError("Mesh \(name) does not have any mesh children")
        }
        
        let firstSubmesh = mdlMesh.submeshes?.firstObject as? MDLSubmesh
        let meshMaterial = firstSubmesh?.material
        
        var texture: MTLTexture?
        var material = Material()
        
        if let property = meshMaterial?.property(with: .baseColor) {
            if property.type == .texture, let textureURL = property.urlValue {
                if let sampler = property.textureSamplerValue, let sourceTexture = sampler.texture {
                    texture = try textureLoader.newTexture(texture: sourceTexture, options: textureOptions)
                } else {
                    texture = try textureLoader.newTexture(URL: textureURL, options: textureOptions)
                }
            }
            
            material.diffuseColor = convertPropertyToColor(property)
        }
        
        if let property = meshMaterial?.property(with: .specular) {
            material.specularColor = convertPropertyToColor(property)
        }
        
        if let property = meshMaterial?.property(with: .specularExponent) {
            material.specularExponent = property.floatValue
        }
        
        if let property = meshMaterial?.property(with: .emission) {
            material.ambientColor = convertPropertyToColor(property)
        }
        
        let mesh = try! MTKMesh(mesh: mdlMesh, device: renderer.metalDevice)
        
        self.meshes[name] = mesh
        self.meshMaterials[name] = material
        
        if let texture {
            self.meshTextures[name] = texture
        }
    }
    
    public func loadPlaneMesh(name: String, extents: SIMD3<Float>) throws {
        let mdlMesh = MDLMesh(
            planeWithExtent: extents,
            segments: SIMD2<UInt32>(1, 1),
            geometryType: .triangles,
            allocator: meshBufferAllocator
        )
        
        let mtkMesh = try MTKMesh(mesh: mdlMesh, device: renderer.metalDevice)
        
        meshes[name] = mtkMesh
        meshMaterials[name] = Material()
    }
    
    public func loadSphereMesh(name: String, extents: SIMD3<Float>, segments: SIMD2<UInt32>, inwardNormals: Bool) throws {
        let mdlMesh = MDLMesh(
            sphereWithExtent: extents,
            segments: segments,
            inwardNormals: inwardNormals,
            geometryType: .triangles,
            allocator: meshBufferAllocator
        )
        
        let mtkMesh = try MTKMesh(mesh: mdlMesh, device: renderer.metalDevice)
        
        meshes[name] = mtkMesh
        meshMaterials[name] = Material()
    }
    
    public func loadTexture(name: String, resource: String, withExtension ext: String) throws {
        guard let url = Bundle.main.url(forResource: resource, withExtension: ext) else {
            throw SolutionError.apiError("No texture resource for \(name)")
        }
        
        let texture = try textureLoader.newTexture(URL: url, options: textureOptions)
        
        textures[name] = texture
    }
    
    public func removeLight(name: String) {
        lightsTable.removeValue(forKey: name)
        lights.removeAll(where: { $0.name == name })
    }
    
    public func removeNode(name: String) {
        let removedNode = nodesTable.removeValue(forKey: name)
        nodes.removeAll(where: { $0.name == name })
        
        if let removedNode {
            for child in removedNode.childNodes {
                removeNode(name: child.name)
            }
        }
    }
    
    public func updateCamera(eye: SIMD3<Float>, lookAt: SIMD3<Float>, up: SIMD3<Float>) {
        pointOfView.transform = simd_float4x4(lookAt: lookAt, from: eye, up: up)
    }
    
    public func updateLight(name: String, transform: simd_float4x4, intensity: Float? = nil, color: SIMD3<Float>? = nil) {
        guard let light = lightsTable[name] else { return }
        
        light.worldTransform = transform
        if let intensity { light.intensity = intensity }
        if let color { light.color = color }
    }
    
    public func updateNode(name: String, transform: simd_float4x4, baseColor: SIMD3<Float>? = nil, ambientColor: SIMD3<Float>? = nil, diffuseColor: SIMD3<Float>? = nil, specularColor: SIMD3<Float>? = nil, specularExponent: Float? = nil) {
        guard let node = nodesTable[name] else {
            return
        }
        
        node.transform = transform
        
        if let baseColor { node.baseColor = baseColor }
        if let ambientColor { node.material.ambientColor = ambientColor }
        if let diffuseColor { node.material.diffuseColor = diffuseColor }
        if let specularColor { node.material.specularColor = specularColor }
        if let specularExponent { node.material.specularExponent = specularExponent }
    }
    
    // MARK: - Drawing
    
    public override func complete() async throws {
        for _ in 0 ..< MaxOutstandingFrameCount {
            frameSemaphor.wait()
        }
        
        try await super.complete()
    }
    
    private func drawMainPass(target: MTLTexture, commandBuffer: MTLCommandBuffer) {
        let renderPassDescriptor = MTLRenderPassDescriptor()
        
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].texture = msaaTextures[frameIndex % MaxOutstandingFrameCount]
        renderPassDescriptor.colorAttachments[0].resolveTexture = target
        renderPassDescriptor.colorAttachments[0].storeAction = .multisampleResolve
        
        renderPassDescriptor.depthAttachment.loadAction = .clear
        renderPassDescriptor.depthAttachment.texture = msaaDepthTextures[frameIndex % MaxOutstandingFrameCount]
        renderPassDescriptor.depthAttachment.resolveTexture = depthTextures[frameIndex % MaxOutstandingFrameCount]
        renderPassDescriptor.depthAttachment.clearDepth = 1.0
        renderPassDescriptor.depthAttachment.storeAction = .multisampleResolve
        
        // Draw!
        let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        encoder.setRenderPipelineState(pipelineState)
        
        encoder.setDepthStencilState(depthStencilState)
        encoder.setFrontFacing(.counterClockwise)
        encoder.setCullMode(.back)
        
        encoder.setVertexBuffer(constantBuffer, offset: 0, index: 2)
        encoder.setVertexBuffer(constantBuffer, offset: frameConstantsOffset, index: 3)
        encoder.setFragmentBuffer(constantBuffer, offset: 0, index: 2)
        encoder.setFragmentBuffer(constantBuffer, offset: frameConstantsOffset, index: 3)
        encoder.setFragmentBuffer(constantBuffer, offset: lightConstantsOffset, index: 4)
        
        for (objectIndex, node) in nodes.enumerated() {
            guard let mesh = node.mesh else { continue }
            
            encoder.pushDebugGroup("Node \(node.name)")
            
            encoder.setVertexBufferOffset(nodeConstantsOffset[objectIndex], index: 2)
            encoder.setFragmentBufferOffset(nodeConstantsOffset[objectIndex], index: 2)
            
            for (i, meshBuffer) in mesh.vertexBuffers.enumerated() {
                encoder.setVertexBuffer(meshBuffer.buffer, offset: meshBuffer.offset, index: i)
            }
            
            encoder.setFragmentTexture(node.texture, index: 0)
            encoder.setFragmentSamplerState(samplerState, index: 0)
            
            for submesh in mesh.submeshes {
                let indexBuffer = submesh.indexBuffer
                    
                encoder.drawIndexedPrimitives(
                    type: submesh.primitiveType,
                    indexCount: submesh.indexCount,
                    indexType: submesh.indexType,
                    indexBuffer: indexBuffer.buffer,
                    indexBufferOffset: indexBuffer.offset
                )
            }
            
            encoder.popDebugGroup()
        }
        
        encoder.endEncoding()
    }
    
    private func updateFrameConstants() {
        let viewMatrix = pointOfView.transform.inverse
        
        let aspectRatio = Float(width) / Float(height)
        let projectionMatrix = simd_float4x4(
            perspectiveProjectionFoVY: .pi / 3,
            aspectRatio: aspectRatio,
            near: 0.01,
            far: 100
        )
        
        var constants = FrameConstants(projectionMatrix: projectionMatrix, viewMatrix: viewMatrix, lightCount: UInt32(lightsTable.count))
        
        let constantsLayout = MemoryLayout<FrameConstants>.self
        frameConstantsOffset = allocateConstantStorage(size: constantsLayout.size, alignment: constantsLayout.stride)

        let constantsPointer = constantBuffer.contents().advanced(by: frameConstantsOffset)
        constantsPointer.copyMemory(from: &constants, byteCount: constantsLayout.size)
    }
    
    private func updateLightConstants() {
        let lightLayout = MemoryLayout<LightConstants>.self
        lightConstantsOffset = allocateConstantStorage(size: lightLayout.stride * lightsTable.count, alignment: lightLayout.stride)
        let lightsBufferPointer = constantBuffer.contents().advanced(by: lightConstantsOffset).assumingMemoryBound(to: LightConstants.self)
        
        for (lightIndex, light) in lights.enumerated() {
            let shadowViewMatrix = light.worldTransform.inverse
            let shadowProjectionMatrix = light.projectionMatrix
            let shadowViewProjectionMatrix = shadowProjectionMatrix * shadowViewMatrix
            
            lightsBufferPointer[lightIndex] = LightConstants(
                viewProjectionMatrix: shadowViewProjectionMatrix,
                intensity: light.color * light.intensity,
                position: light.position,
                direction: light.direction,
                type: light.type.rawValue
            )
        }
    }
    
    private func updateNodeConstants() {
        let nodeLayout = MemoryLayout<NodeConstants>.self
        nodeConstantsOffset.removeAll(keepingCapacity: true)
        
        for node in nodes {
            var constants = NodeConstants(
                modelMatrix: node.worldTransform,
                baseColor: node.baseColor,
                ambientColor: node.material.ambientColor,
                diffuseColor: node.material.diffuseColor,
                specularColor: node.material.specularColor,
                specularExponent: node.material.specularExponent
            )
            
            let offset = allocateConstantStorage(size: nodeLayout.size, alignment: nodeLayout.stride)
            let constantsPointer = constantBuffer.contents().advanced(by: offset)
            constantsPointer.copyMemory(from: &constants, byteCount: nodeLayout.size)
            
            nodeConstantsOffset.append(offset)
        }
    }
    
    public func snapshot() throws {
        // Get the next CVPixelBuffer
        guard let pool = writerAdaptor?.pixelBufferPool else {
            throw SolutionError.apiError("No pixel buffer pool available")
        }
        
        var pixelBuffer: CVPixelBuffer? = nil
        CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pool, &pixelBuffer)
        
        guard let pixelBuffer else {
            throw SolutionError.apiError("Pixel buffer pool is out of pixel buffers")
        }
        
        // Get the Metal texture of the pixel buffer
        var cvMetalTexture: CVMetalTexture? = nil
        CVMetalTextureCacheCreateTextureFromImage(
            kCFAllocatorDefault,
            textureCache,
            pixelBuffer,
            nil,
            .bgra8Unorm,
            width,
            height,
            0,
            &cvMetalTexture
        )
        
        let metalTexture = CVMetalTextureGetTexture(cvMetalTexture!)!
        
        frameSemaphor.wait()
        
        updateLightConstants()
        updateFrameConstants()
        updateNodeConstants()
        
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            throw SolutionError.apiError("Could not get a command buffer for the render pass")
        }
        
        drawMainPass(target: metalTexture, commandBuffer: commandBuffer)
        
        // Clean up and submit
        commandBuffer.addCompletedHandler { [weak self] _ in
            guard let self else { return }
            
            self.submit(pixelBuffer: pixelBuffer)
            
            self.frameSemaphor.signal()
        }
        
        commandBuffer.commit()
        
        frameIndex += 1
    }
    
    // MARK: - Utilities
    
    func allocateConstantStorage(size: Int, alignment: Int) -> Int {
        let effectiveAlignment = lcm(alignment, MinBufferAlignment)
        var allocationOffset = align(currentConstantBufferOffset, upTo: effectiveAlignment)
        
        if (allocationOffset + size >= MaxConstantsSize) {
            allocationOffset = 0
        }
        
        currentConstantBufferOffset = allocationOffset + size
        
        return allocationOffset
    }
}
