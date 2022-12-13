//
//  Solution3DContext.swift
//  Visualization
//
//  Created by Stephen H. Gerstacker on 2022-11-12.
//  SPDX-License-Identifier: MIT
//

import AVFoundation
import Combine
import Foundation
import Metal
import MetalKit
import ModelIO
import Utilities

fileprivate let MaxOutstandingFrameCount = 3
fileprivate let MinBufferAlignment = 256

public let DefaultBaseColor = SIMD4<Float>(1, 1, 1, 1)
public let DefaultMetallicFactor: Float = 0
public let DefaultRoughnessFactor: Float = 0.5
public let DefaultEmissiveColor = SIMD4<Float>(0, 0, 0, 1)
public let DefaultOpacityValue: Float = 1.0

fileprivate struct VertexBufferIndex {
    static let vertexAttributes = 0
    static let nodeConstants = 8
    static let frameConstants = 9
    static let lightConstants = 10
}

fileprivate struct FragmentBufferIndex {
    static let frameConstants = 0
    static let lightConstants = 1
    static let materialConstants = 2
}

fileprivate struct FragmentTextureIndex {
    static let baseColor = 0
    static let emissive = 1
    static let normal = 2
    static let metalness = 3
    static let roughness = 4
    static let ambientOcclusion = 5
}

// MARK: - Renderer Uniforms

fileprivate struct NodeConstants {
    var modelMatrix: float4x4
    var normalMatrix: float3x3
}

fileprivate struct MaterialConstants {
    var baseColor: SIMD4<Float>
    var emissiveColor: SIMD4<Float>
    var metallicFactor: Float
    var roughnessFactor: Float
    var occlusionWeight: Float
    var opacity: Float
}

fileprivate struct FrameConstants {
    var viewMatrix: float4x4
    var viewProjectionMatrix: float4x4
    var lightCount: UInt32
}

fileprivate struct LightConstants {
    var position: SIMD4<Float>
    var direction: SIMD4<Float>
    var intensity: SIMD4<Float>
}

open class Solution3DContext: SolutionContext {
    
    // MARK: - Properties
    
    private var meshBufferAllocator: MTKMeshBufferAllocator!
    private var mdlVertexDescriptor: MDLVertexDescriptor!
    private var vertexDescriptor: MTLVertexDescriptor!
    
    private var textureLoader: MTKTextureLoader!
    private var textureOptions: [MTKTextureLoader.Option:Any]!
    private var textureCache: CVMetalTextureCache!
    
    private var nodesTable: [String:SolutionNode] = [:]
    private var nodes: [SolutionNode] = []
    private var batchNodes: [String:[SolutionNode]] = [:]
    
    private var meshesTable: [String:SolutionMesh] = [:]
    
    private var textures: [String:MTLTexture] = [:]
    
    private var pointOfView: simd_float4x4 = matrix_identity_float4x4
    private var lightsTable: [String:SolutionLight] = [:]
    private var lights: [SolutionLight] = []
    
    private var perspectiveNear: Float = 0.01
    private var perspectiveFar: Float = 1000
    private var perspectiveAngle: Float = .pi / 3
    
    private var commandQueue: MTLCommandQueue!
    private var constantBuffer: MTLBuffer!
    private var pipelineState: MTLRenderPipelineState!
    private var depthStencilState: MTLDepthStencilState!
    private let maxConstantsSize: Int
    
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
    
    public override convenience init(width: Int, height: Int, frameRate: Double) {
        self.init(width: width, height: height, frameRate: frameRate, maxConstantsSize: 1024 * 1024 * 3)
    }
    
    public init(width: Int, height: Int, frameRate: Double, maxConstantsSize: Int = 1024 * 1024 * 3) {
        self.maxConstantsSize = maxConstantsSize
        
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
        mdlVertexDescriptor.vertexAttributes[1].offset = MemoryLayout<Float>.size * 3
        mdlVertexDescriptor.vertexAttributes[1].bufferIndex = 0
        mdlVertexDescriptor.vertexAttributes[2].name = MDLVertexAttributeTangent
        mdlVertexDescriptor.vertexAttributes[2].format = .float4
        mdlVertexDescriptor.vertexAttributes[2].offset = MemoryLayout<Float>.size * 6
        mdlVertexDescriptor.vertexAttributes[2].bufferIndex = 0
        mdlVertexDescriptor.vertexAttributes[3].name = MDLVertexAttributeTextureCoordinate
        mdlVertexDescriptor.vertexAttributes[3].format = .float2
        mdlVertexDescriptor.vertexAttributes[3].offset = MemoryLayout<Float>.size * 10
        mdlVertexDescriptor.vertexAttributes[3].bufferIndex = 0
        mdlVertexDescriptor.bufferLayouts[0].stride = MemoryLayout<Float>.size * 12
        
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
        
        commandQueue = device.makeCommandQueue()!
        commandQueue.label = "Solution 3D Command Queue"
        
        constantBuffer = device.makeBuffer(length: maxConstantsSize, options: .storageModeShared)!
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
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
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
    }
    
    // MARK: - Asset Management (New)
    
    public func createTexture(name: String, width: Int, height: Int, draw: (CGContext) -> Void) {
        let rowAlignment = renderer.metalDevice.minimumTextureBufferAlignment(for: .rgba8Unorm)
        let bytesPerRow = align(width * 4, upTo: rowAlignment)
        let pageSize = Int(getpagesize())
        let allocationSize = align(bytesPerRow * height, upTo: pageSize)
        
        var data: UnsafeMutableRawPointer? = nil
        posix_memalign(&data, pageSize, allocationSize)
        memset(data!, 0, allocationSize)
        
        let context = CGContext(
            data: data,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        
        draw(context)
        
        let buffer = renderer.metalDevice.makeBuffer(bytes: data!, length: allocationSize, options: .storageModeShared)!
        
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.pixelFormat = .rgba8Unorm
        textureDescriptor.width = width
        textureDescriptor.height = height
        textureDescriptor.storageMode = .shared
        textureDescriptor.usage = .shaderRead
        
        let texture = buffer.makeTexture(descriptor: textureDescriptor, offset: 0, bytesPerRow: context.bytesPerRow)
        
        textures[name] = texture
    }
    
    public func loadMesh(name: String, fromResource resource: String) throws {
        guard let url = Bundle.main.url(forResource: resource, withExtension: "usdz") else {
            throw SolutionError.apiError("No mesh resource for \(name)")
        }
        
        let mdlAsset = MDLAsset(url: url, vertexDescriptor: nil, bufferAllocator: meshBufferAllocator)
        mdlAsset.loadTextures()
        
        for sourceMesh in mdlAsset.childObjects(of: MDLMesh.self) as! [MDLMesh] {
            let hasTextureCoordinates = sourceMesh.vertexAttributeData(forAttributeNamed: MDLVertexAttributeTextureCoordinate) != nil
            let hasNormals = sourceMesh.vertexAttributeData(forAttributeNamed: MDLVertexAttributeNormal) != nil
            
            if hasTextureCoordinates && hasNormals {
                sourceMesh.addOrthTanBasis(
                    forTextureCoordinateAttributeNamed: MDLVertexAttributeTextureCoordinate,
                    normalAttributeNamed: MDLVertexAttributeNormal,
                    tangentAttributeNamed: MDLVertexAttributeTangent
                )
            }
            
            sourceMesh.vertexDescriptor = mdlVertexDescriptor
        }
        
        var maxBounds = SIMD3<Float>(repeating: -.infinity)
        var minBounds = SIMD3<Float>(repeating: .infinity)
        
        var submeshes: [SolutionSubmesh] = []
        
        let (mdlMeshes, mtkMeshes) = try MTKMesh.newMeshes(asset: mdlAsset, device: renderer.metalDevice)
        
        for (mdlMesh, mtkMesh) in zip(mdlMeshes, mtkMeshes) {
            maxBounds.x = max(maxBounds.x, mdlMesh.boundingBox.maxBounds.x)
            maxBounds.y = max(maxBounds.y, mdlMesh.boundingBox.maxBounds.y)
            maxBounds.z = max(maxBounds.z, mdlMesh.boundingBox.maxBounds.z)
            
            minBounds.x = min(minBounds.x, mdlMesh.boundingBox.minBounds.x)
            minBounds.y = min(minBounds.y, mdlMesh.boundingBox.minBounds.y)
            minBounds.z = min(minBounds.z, mdlMesh.boundingBox.minBounds.z)
            
            var materials: [SolutionMaterial] = []
            
            for mdlSubmesh in mdlMesh.submeshes as! [MDLSubmesh] {
                if let mdlMaterial = mdlSubmesh.material {
                    let material = SolutionMaterial(material: mdlMaterial, device: renderer.metalDevice)
                    materials.append(material)
                }
            }
            
            let submesh = SolutionSubmesh(mtkMesh: mtkMesh, materials: materials)
            submeshes.append(submesh)
        }
        
        let mesh = SolutionMesh(name: name, bounds: maxBounds - minBounds, submeshes: submeshes)
        meshesTable[name] = mesh
    }
    
    private func loadSimpleMesh(name: String,
                                bounds: SIMD3<Float>,
                                mtkMesh: MTKMesh,
                                baseColor: SIMD4<Float> = DefaultBaseColor, baseColorTexture: String? = nil,
                                emissiveColor: SIMD4<Float> = DefaultEmissiveColor, emissiveTexture: String? = nil,
                                metallicFactor: Float = DefaultMetallicFactor, metallicTexture: String? = nil,
                                roughnessFactor: Float = DefaultRoughnessFactor, roughnessTexture: String? = nil,
                                ambientOcclusionTexture: String? = nil, normalTexture: String? = nil,
                                opacity: Float = DefaultOpacityValue)
    {
        var material = SolutionMaterial()
        material.baseColor = baseColor
        material.emissiveColor = emissiveColor
        material.metallicFactor = metallicFactor
        material.roughnessFactor = roughnessFactor
        material.opacity = opacity
        
        if let baseColorTexture { material.baseColorTexture = textures[baseColorTexture] }
        if let emissiveTexture { material.emissiveTexture = textures[emissiveTexture] }
        if let metallicTexture { material.metallicTexture = textures[metallicTexture] }
        if let roughnessTexture { material.roughnessTexture = textures[roughnessTexture] }
        if let ambientOcclusionTexture { material.ambientOcclusionTexture = textures[ambientOcclusionTexture] }
        if let normalTexture { material.normalTexture = textures[normalTexture] }
        
        let submesh = SolutionSubmesh(mtkMesh: mtkMesh, materials: [material])
        let mesh = SolutionMesh(name: name, bounds: bounds, submeshes: [submesh])
        
        meshesTable[name] = mesh
    }
    
    public func loadBoxMesh(name: String, extents: SIMD3<Float> = .one, inwardNormals: Bool = false,
                            baseColor: SIMD4<Float> = DefaultBaseColor, baseColorTexture: String? = nil,
                            emissiveColor: SIMD4<Float> = DefaultEmissiveColor, emissiveTexture: String? = nil,
                            metallicFactor: Float = DefaultMetallicFactor, metallicTexture: String? = nil,
                            roughnessFactor: Float = DefaultRoughnessFactor, roughnessTexture: String? = nil,
                            ambientOcclusionTexture: String? = nil, normalTexture: String? = nil,
                            opacity: Float = DefaultOpacityValue) throws
    {
        let mdlMesh = MDLMesh(boxWithExtent: extents, segments: SIMD3<UInt32>(1, 1, 1), inwardNormals: inwardNormals, geometryType: .triangles, allocator: meshBufferAllocator)
        
        mdlMesh.addOrthTanBasis(
            forTextureCoordinateAttributeNamed: MDLVertexAttributeTextureCoordinate,
            normalAttributeNamed: MDLVertexAttributeNormal,
            tangentAttributeNamed: MDLVertexAttributeTangent
        )
        
        mdlMesh.vertexDescriptor = mdlVertexDescriptor
        
        let mtkMesh = try MTKMesh(mesh: mdlMesh, device: renderer.metalDevice)
        
        loadSimpleMesh(
            name: name,
            bounds: mdlMesh.boundingBox.maxBounds - mdlMesh.boundingBox.minBounds,
            mtkMesh: mtkMesh,
            baseColor: baseColor,
            baseColorTexture: baseColorTexture,
            emissiveColor: emissiveColor,
            emissiveTexture: emissiveTexture,
            metallicFactor: metallicFactor,
            metallicTexture: metallicTexture,
            roughnessFactor: roughnessFactor,
            roughnessTexture: roughnessTexture,
            ambientOcclusionTexture: ambientOcclusionTexture,
            normalTexture: normalTexture,
            opacity: opacity
        )
    }
    
    public func loadPlaneMesh(name: String, extents: SIMD3<Float> = .one,
                              baseColor: SIMD4<Float> = DefaultBaseColor, baseColorTexture: String? = nil,
                              emissiveColor: SIMD4<Float> = DefaultEmissiveColor, emissiveTexture: String? = nil,
                              metallicFactor: Float = DefaultMetallicFactor, metallicTexture: String? = nil,
                              roughnessFactor: Float = DefaultRoughnessFactor, roughnessTexture: String? = nil,
                              ambientOcclusionTexture: String? = nil, normalTexture: String? = nil,
                              opacity: Float = DefaultOpacityValue) throws
    {
        let mdlMesh = MDLMesh(planeWithExtent: extents, segments: SIMD2<UInt32>(1, 1), geometryType: .triangles, allocator: meshBufferAllocator)
        
        mdlMesh.addOrthTanBasis(
            forTextureCoordinateAttributeNamed: MDLVertexAttributeTextureCoordinate,
            normalAttributeNamed: MDLVertexAttributeNormal,
            tangentAttributeNamed: MDLVertexAttributeTangent
        )
        
        mdlMesh.vertexDescriptor = mdlVertexDescriptor
        
        let mtkMesh = try MTKMesh(mesh: mdlMesh, device: renderer.metalDevice)
        
        loadSimpleMesh(
            name: name,
            bounds: mdlMesh.boundingBox.maxBounds - mdlMesh.boundingBox.minBounds,
            mtkMesh: mtkMesh,
            baseColor: baseColor,
            baseColorTexture: baseColorTexture,
            emissiveColor: emissiveColor,
            emissiveTexture: emissiveTexture,
            metallicFactor: metallicFactor,
            metallicTexture: metallicTexture,
            roughnessFactor: roughnessFactor,
            roughnessTexture: roughnessTexture,
            ambientOcclusionTexture: ambientOcclusionTexture,
            normalTexture: normalTexture,
            opacity: opacity
        )
    }
    
    public func loadSphereMesh(name: String, extents: SIMD3<Float> = SIMD3<Float>(0.5, 0.5, 0.5), segments: SIMD2<UInt32> = SIMD2<UInt32>(24, 24), inwardNormals: Bool = false,
                               baseColor: SIMD4<Float> = DefaultBaseColor, baseColorTexture: String? = nil,
                               emissiveColor: SIMD4<Float> = DefaultEmissiveColor, emissiveTexture: String? = nil,
                               metallicFactor: Float = DefaultMetallicFactor, metallicTexture: String? = nil,
                               roughnessFactor: Float = DefaultRoughnessFactor, roughnessTexture: String? = nil,
                               ambientOcclusionTexture: String? = nil, normalTexture: String? = nil,
                               opacity: Float = DefaultOpacityValue) throws
    {
        let mdlMesh = MDLMesh(sphereWithExtent: extents, segments: segments, inwardNormals: inwardNormals, geometryType: .triangles, allocator: meshBufferAllocator)
        
        mdlMesh.addOrthTanBasis(
            forTextureCoordinateAttributeNamed: MDLVertexAttributeTextureCoordinate,
            normalAttributeNamed: MDLVertexAttributeNormal,
            tangentAttributeNamed: MDLVertexAttributeTangent
        )
        
        mdlMesh.vertexDescriptor = mdlVertexDescriptor
        
        let mtkMesh = try MTKMesh(mesh: mdlMesh, device: renderer.metalDevice)
        
        loadSimpleMesh(
            name: name,
            bounds: mdlMesh.boundingBox.maxBounds - mdlMesh.boundingBox.minBounds,
            mtkMesh: mtkMesh,
            baseColor: baseColor,
            baseColorTexture: baseColorTexture,
            emissiveColor: emissiveColor,
            emissiveTexture: emissiveTexture,
            metallicFactor: metallicFactor,
            metallicTexture: metallicTexture,
            roughnessFactor: roughnessFactor,
            roughnessTexture: roughnessTexture,
            ambientOcclusionTexture: ambientOcclusionTexture,
            normalTexture: normalTexture,
            opacity: opacity
        )
    }
    
    public func loadTexture(name: String, resource: String, withExtension ext: String) throws {
        guard let url = Bundle.main.url(forResource: resource, withExtension: ext) else {
            throw SolutionError.apiError("No texture resource for \(name)")
        }
        
        let texture = try textureLoader.newTexture(URL: url, options: textureOptions)
        
        textures[name] = texture
    }
    
    public func textureExists(name: String) -> Bool {
        let texture = textures[name]
        
        return texture != nil
    }
    
    // MARK: - Node Management
    
    public func addNode(name: String, mesh: String, parent parentName: String? = nil, batch: String? = nil) {
        guard let mesh = meshesTable[mesh] else { return }
        
        let node = SolutionNode(name: name, mesh: mesh, batch: batch)
        nodesTable[name] = node
        
        if let batch {
            var existingNodes = batchNodes[batch] ?? []
            existingNodes.append(node)
            
            batchNodes[batch] = existingNodes
        } else {
            nodes.append(node)
        }
        
        if let parentName, let parentNode = nodesTable[parentName] {
            parentNode.addChild(node)
        }
    }
    
    public func removeNode(name: String) {
        guard let node = nodesTable[name] else { return }
        
        for childNode in node.children {
            removeNode(name: childNode.name)
        }
        
        nodesTable.removeValue(forKey: name)
        nodes.removeAll(where: { $0 === node })
        
        if let batch = node.batch {
            batchNodes[batch]?.removeAll(where: { $0 === node })
        }
    }
    
    public func updateNode(name: String, transform: simd_float4x4? = nil, submeshIndex: Int = 0, materialIndex: Int = 0, baseColor: SIMD4<Float>? = nil, metallicFactor: Float? = nil, roughnessFactor: Float? = nil, emissiveColor: SIMD4<Float>? = nil, opacity: Float? = nil) {
        guard let node = nodesTable[name] else {
            return
        }
        
        if let transform { node.transform = transform }
        
        if let baseColor { node.mesh.submeshes[submeshIndex].materails[materialIndex].baseColor = baseColor }
        if let metallicFactor { node.mesh.submeshes[submeshIndex].materails[materialIndex].metallicFactor = metallicFactor }
        if let roughnessFactor { node.mesh.submeshes[submeshIndex].materails[materialIndex].roughnessFactor = roughnessFactor }
        if let emissiveColor { node.mesh.submeshes[submeshIndex].materails[materialIndex].emissiveColor = emissiveColor }
        if let opacity { node.mesh.submeshes[submeshIndex].materails[materialIndex].opacity = opacity }
    }
    
    // MARK: - Light & Camera Management
    
    public func addDirectLight(name: String, lookAt target: SIMD3<Float>, from origin: SIMD3<Float>, up: SIMD3<Float>, color: SIMD3<Float> = SIMD3<Float>(1, 1, 1), intensity: Float = 1.0) {
        let light = SolutionLight()
        light.name = name
        light.type = .directional
        light.worldTransform = simd_float4x4(lookAt: target, from: origin, up: up)
        light.color = color
        light.intensity = intensity
        
        lightsTable[name] = light
        lights.append(light)
    }
    
    public func addPointLight(name: String, color: SIMD3<Float> = SIMD3<Float>(1, 1, 1), intensity: Float = 1.0) {
        let light = SolutionLight()
        light.name = name
        light.type = .omni
        light.color = color
        light.intensity = intensity
        
        lightsTable[name] = light
        lights.append(light)
    }
    
    public func removeLight(name: String) {
        lightsTable.removeValue(forKey: name)
        lights.removeAll(where: { $0.name == name })
    }
    
    public func updateCamera(eye: SIMD3<Float>, lookAt: SIMD3<Float>, up: SIMD3<Float>) {
        pointOfView = simd_float4x4(lookAt: lookAt, from: eye, up: up)
    }
    
    public func updateLight(name: String, transform: simd_float4x4, intensity: Float? = nil, color: SIMD3<Float>? = nil) {
        guard let light = lightsTable[name] else { return }
        
        light.worldTransform = transform
        if let intensity { light.intensity = intensity }
        if let color { light.color = color }
    }
    
    public func updatePerspective(near: Float, far: Float, angle: Float) {
        perspectiveNear = near
        perspectiveFar = far
        perspectiveAngle = angle
    }
    
    // MARK: - Drawing
    
    public override func complete() async throws {
        for _ in 0 ..< MaxOutstandingFrameCount {
            frameSemaphor.wait()
        }
        
        try await super.complete()
    }
    
    private func drawNodesBatched(encoder: MTLRenderCommandEncoder) {
        let nodeLayout = MemoryLayout<NodeConstants>.self
        let materialLayout = MemoryLayout<MaterialConstants>.self
        
        var nodeIndex = nodes.count
        let batchKeys = batchNodes.keys.sorted()
        
        for batchKey in batchKeys {
            let nodes = batchNodes[batchKey]!
            
            guard let firstNode = nodes.first else { continue }
            
            encoder.pushDebugGroup("Batch \(batchKey)")
            
            encoder.setVertexBufferOffset(nodeConstantsOffset[nodeIndex], index: VertexBufferIndex.nodeConstants)
            
            var offset = nodeConstantsOffset[nodeIndex] + (nodeLayout.stride * nodes.count)
            
            for submesh in firstNode.mesh.submeshes {
                for (vertexBufferIndex, vertexBuffer) in submesh.mtkMesh.vertexBuffers.enumerated() {
                    encoder.setVertexBuffer(vertexBuffer.buffer, offset: vertexBuffer.offset, index: vertexBufferIndex)
                }
                
                for (mtkSubmeshIndex, mtkSubmesh) in submesh.mtkMesh.submeshes.enumerated() {
                    let material = submesh.materails[mtkSubmeshIndex]
                    
                    encoder.setFragmentTexture(material.baseColorTexture, index: FragmentTextureIndex.baseColor)
                    encoder.setFragmentTexture(material.emissiveTexture, index: FragmentTextureIndex.emissive)
                    encoder.setFragmentTexture(material.normalTexture, index: FragmentTextureIndex.normal)
                    encoder.setFragmentTexture(material.metallicTexture, index: FragmentTextureIndex.metalness)
                    encoder.setFragmentTexture(material.roughnessTexture, index: FragmentTextureIndex.roughness)
                    encoder.setFragmentTexture(material.ambientOcclusionTexture, index: FragmentTextureIndex.ambientOcclusion)
                    
                    encoder.setFragmentBufferOffset(offset, index: FragmentBufferIndex.materialConstants)
                    let indexBuffer = mtkSubmesh.indexBuffer
                    
                    encoder.drawIndexedPrimitives(
                        type: mtkSubmesh.primitiveType,
                        indexCount: mtkSubmesh.indexCount,
                        indexType: mtkSubmesh.indexType,
                        indexBuffer: indexBuffer.buffer,
                        indexBufferOffset: indexBuffer.offset,
                        instanceCount: nodes.count
                    )
                    
                    offset += materialLayout.stride
                }
            }
            
            encoder.popDebugGroup()
            
            nodeIndex += 1
        }
    }
    
    private func drawNodesSingle(encoder: MTLRenderCommandEncoder) {
        let nodeLayout = MemoryLayout<NodeConstants>.self
        let materialLayout = MemoryLayout<MaterialConstants>.self
        
        for (nodeIndex, node) in nodes.enumerated() {
            encoder.pushDebugGroup("Node \(node.name)")
            
            encoder.setVertexBufferOffset(nodeConstantsOffset[nodeIndex], index: VertexBufferIndex.nodeConstants)
            
            var offset = nodeConstantsOffset[nodeIndex] + nodeLayout.stride
            
            for submesh in node.mesh.submeshes {
                for (vertexBufferIndex, vertexBuffer) in submesh.mtkMesh.vertexBuffers.enumerated() {
                    encoder.setVertexBuffer(vertexBuffer.buffer, offset: vertexBuffer.offset, index: vertexBufferIndex)
                }
                
                for (mtkSubmeshIndex, mtkSubmesh) in submesh.mtkMesh.submeshes.enumerated() {
                    let material = submesh.materails[mtkSubmeshIndex]
                    
                    encoder.setFragmentTexture(material.baseColorTexture, index: FragmentTextureIndex.baseColor)
                    encoder.setFragmentTexture(material.emissiveTexture, index: FragmentTextureIndex.emissive)
                    encoder.setFragmentTexture(material.normalTexture, index: FragmentTextureIndex.normal)
                    encoder.setFragmentTexture(material.metallicTexture, index: FragmentTextureIndex.metalness)
                    encoder.setFragmentTexture(material.roughnessTexture, index: FragmentTextureIndex.roughness)
                    encoder.setFragmentTexture(material.ambientOcclusionTexture, index: FragmentTextureIndex.ambientOcclusion)
                    
                    encoder.setFragmentBufferOffset(offset, index: FragmentBufferIndex.materialConstants)
                    let indexBuffer = mtkSubmesh.indexBuffer
                    
                    encoder.drawIndexedPrimitives(
                        type: mtkSubmesh.primitiveType,
                        indexCount: mtkSubmesh.indexCount,
                        indexType: mtkSubmesh.indexType,
                        indexBuffer: indexBuffer.buffer,
                        indexBufferOffset: indexBuffer.offset,
                        instanceCount: 1
                    )
                    
                    offset += materialLayout.stride
                }
            }
            
            encoder.popDebugGroup()
        }
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
        
        encoder.setVertexBuffer(constantBuffer, offset: 0, index: VertexBufferIndex.nodeConstants)
        encoder.setVertexBuffer(constantBuffer, offset: frameConstantsOffset, index: VertexBufferIndex.frameConstants)
        encoder.setVertexBuffer(constantBuffer, offset: lightConstantsOffset, index: VertexBufferIndex.lightConstants)
        
        encoder.setFragmentBuffer(constantBuffer, offset: 0, index: FragmentBufferIndex.materialConstants)
        encoder.setFragmentBuffer(constantBuffer, offset: frameConstantsOffset, index: FragmentBufferIndex.frameConstants)
        encoder.setFragmentBuffer(constantBuffer, offset: lightConstantsOffset, index: FragmentBufferIndex.lightConstants)
        
        drawNodesBatched(encoder: encoder)
        drawNodesSingle(encoder: encoder)
        
        encoder.endEncoding()
    }
    
    private func snapshotInternal() throws {
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
        
        let lightAllocations = updateLightConstants()
        let frameAllocations = updateFrameConstants()
        let nodesAllocations = updateNodeConstants()
        
        let totalAllocations = lightAllocations + frameAllocations + nodesAllocations
        
        if totalAllocations > maxConstantsSize / MaxOutstandingFrameCount {
            fatalError("Insufficient constant storage: frame consumed \(totalAllocations) bytes of total \(maxConstantsSize) bytes")
        } else {
            // print("Allocated \(totalAllocations) inside of \(MaxConstantsSize / MaxOutstandingFrameCount)")
        }
        
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
    
    public func snapshot() throws {
        try autoreleasepool {
            try snapshotInternal()
        }
    }
    
    private func updateFrameConstants() -> Int {
        let aspectRatio = Float(width) / Float(height)
        let projectionMatrix = simd_float4x4(
            perspectiveProjectionFoVY: perspectiveAngle,
            aspectRatio: aspectRatio,
            near: perspectiveNear,
            far: perspectiveFar
        )
        
        let cameraMatrix = pointOfView
        let viewMatrix = cameraMatrix.inverse
        let viewProjectionMatrix = projectionMatrix * viewMatrix
        
        var constants = FrameConstants(
            viewMatrix: viewMatrix,
            viewProjectionMatrix: viewProjectionMatrix,
            lightCount: UInt32(lightsTable.count)
        )
        
        let constantsLayout = MemoryLayout<FrameConstants>.self
        frameConstantsOffset = allocateConstantStorage(size: constantsLayout.size, alignment: constantsLayout.stride)

        let constantsPointer = constantBuffer.contents().advanced(by: frameConstantsOffset)
        constantsPointer.copyMemory(from: &constants, byteCount: constantsLayout.size)
        
        return constantsLayout.stride
    }
    
    private func updateLightConstants() -> Int {
        let cameraMatrix = pointOfView
        let viewMatrix = cameraMatrix.inverse
        
        let lightLayout = MemoryLayout<LightConstants>.self
        lightConstantsOffset = allocateConstantStorage(size: lightLayout.stride * lightsTable.count, alignment: lightLayout.stride)
        let lightsBufferPointer = constantBuffer.contents().advanced(by: lightConstantsOffset).assumingMemoryBound(to: LightConstants.self)
        
        for (lightIndex, light) in lights.enumerated() {
            let lightModelViewMatrix = viewMatrix * light.worldTransform
            let lightPosition = lightModelViewMatrix.columns.3.xyz
            let lightDirection = lightModelViewMatrix.columns.2.xyz
            let directionW: Float = light.type == .directional ? 0.0 : 1.0
            
            lightsBufferPointer[lightIndex] = LightConstants(
                position: SIMD4<Float>(lightPosition, 1.0),
                direction: SIMD4<Float>(lightDirection, directionW),
                intensity: SIMD4<Float>(light.color * light.intensity, 1.0)
            )
        }
        
        return lightLayout.stride * lightsTable.count
    }
    
    private func updateNodeConstants() -> Int {
        nodeConstantsOffset.removeAll(keepingCapacity: true)

        let singleAllocation = updateNodeConstantsSingle()
        let batchAllocation = updateNodeConstantsBatched()
        
        return singleAllocation + batchAllocation
    }
    
    private func updateNodeConstantsSingle() -> Int {
        var allocations = 0
        
        let nodeLayout = MemoryLayout<NodeConstants>.self
        let materialLayout = MemoryLayout<MaterialConstants>.self
        
        for node in nodes {
            let modelMatrix = node.worldTransform
            let modelViewMatrix = pointOfView.inverse * modelMatrix
            let normalMatrix = modelViewMatrix.upperLeft3x3.transpose.inverse
            
            var nodeConstants = NodeConstants(modelMatrix: modelMatrix, normalMatrix: normalMatrix)
            
            let totalMaterials = node.mesh.submeshes.reduce(0) { $0 + $1.materails.count }
            let totalSize = nodeLayout.stride + (materialLayout.stride * totalMaterials)
            let totalStride = align(totalSize, upTo: 256)
            
            let offset = allocateConstantStorage(size: totalSize, alignment: totalStride)
            var constantsPointer = constantBuffer.contents().advanced(by: offset)
            constantsPointer.copyMemory(from: &nodeConstants, byteCount: nodeLayout.stride)
            constantsPointer = constantsPointer.advanced(by: nodeLayout.stride)
            
            allocations += totalStride
            
            for submesh in node.mesh.submeshes {
                for material in submesh.materails {
                    var materialConstants = MaterialConstants(
                        baseColor: material.baseColor,
                        emissiveColor: material.emissiveColor,
                        metallicFactor: material.metallicFactor,
                        roughnessFactor: material.roughnessFactor,
                        occlusionWeight: 1.0,
                        opacity: material.opacity
                    )
                    
                    constantsPointer.copyMemory(from: &materialConstants, byteCount: materialLayout.stride)
                    constantsPointer = constantsPointer.advanced(by: materialLayout.stride)
                }
            }
            
            nodeConstantsOffset.append(offset)
        }
        
        return allocations
    }
    
    private func updateNodeConstantsBatched() -> Int {
        var allocations = 0
        
        let nodeLayout = MemoryLayout<NodeConstants>.self
        let materialLayout = MemoryLayout<MaterialConstants>.self
        
        let batchKeys = batchNodes.keys.sorted()
        
        for batchKey in batchKeys {
            let nodes = batchNodes[batchKey]!
            
            guard let firstNode = nodes.first else { continue } // At least 1 node is required for the common material
            
            var nodeConstants = nodes.map { node in
                let modelMatrix = node.worldTransform
                let modelViewMatrix = pointOfView.inverse * modelMatrix
                let normalMatrix = modelViewMatrix.upperLeft3x3.transpose.inverse
                
                return NodeConstants(modelMatrix: modelMatrix, normalMatrix: normalMatrix)
            }
            
            let totalMaterials = firstNode.mesh.submeshes.reduce(0) { $0 + $1.materails.count }
            let totalSize = (nodeLayout.stride * nodes.count) + (materialLayout.stride * totalMaterials)
            let totalStride = totalSize
            
            let offset = allocateConstantStorage(size: totalSize, alignment: totalStride)
            var constantsPointer = constantBuffer.contents().advanced(by: offset)
            constantsPointer.copyMemory(from: &nodeConstants, byteCount: nodeLayout.stride * nodes.count)
            constantsPointer = constantsPointer.advanced(by: nodeLayout.stride * nodes.count)
            
            allocations += totalStride
            
            for submesh in firstNode.mesh.submeshes {
                for material in submesh.materails {
                    var materialConstants = MaterialConstants(
                        baseColor: material.baseColor,
                        emissiveColor: material.emissiveColor,
                        metallicFactor: material.metallicFactor,
                        roughnessFactor: material.roughnessFactor,
                        occlusionWeight: 1.0,
                        opacity: material.opacity
                    )
                    
                    constantsPointer.copyMemory(from: &materialConstants, byteCount: materialLayout.stride)
                    constantsPointer = constantsPointer.advanced(by: materialLayout.stride)
                }
            }
            
            nodeConstantsOffset.append(offset)
        }
        
        return allocations
    }
    
    // MARK: - Utilities
    
    func allocateConstantStorage(size: Int, alignment: Int) -> Int {
        let effectiveAlignment = lcm(alignment, MinBufferAlignment)
        var allocationOffset = align(currentConstantBufferOffset, upTo: effectiveAlignment)
        
        if (allocationOffset + size >= maxConstantsSize) {
            allocationOffset = 0
        }
        
        currentConstantBufferOffset = allocationOffset + size
        
        return allocationOffset
    }
    
    public func easeInOutQuad(_ progress: Float) -> Float {
        let result = progress < 0.5 ? 2 * progress * progress : 1 - pow(-2 * progress + 2, 2) / 2
        return result
    }
    
    public func easeInOutSine(_ progress: Float) -> Float {
        let result = -(cos(.pi * progress) - 1) / 2
        return result
    }
    
    public func easeInQuad(_ progress: Float) -> Float {
        return progress * progress
    }
    
    public func easeInSine(_ progress: Float) -> Float {
        let result = 1 - cos((progress * .pi) / 2.0)
        return result
    }
    
    public func easeOutBack(_ progress: Float) -> Float {
        let c1: Float = 1.70158
        let c3 = c1 + 1
        
        return 1.0 + c3 * pow(progress - 1.0, 3.0) + c1 * pow(progress - 1.0, 2.0)
    }
    
    public func easeOutQuad(_ progress: Float) -> Float {
        return 1.0 - (1.0 - progress) * (1.0 - progress)
    }
    
    public func easeOutSine(_ progress: Float) -> Float {
        let result = sin((progress * .pi) / 2.0)
        return result
    }
    
    public func lerp(start: Float, end: Float, percent: Float) -> Float {
        let result = start + (end - start) * percent
        return result
    }
    
    public func linear(_ progress: Float) -> Float {
        return progress
    }
    
    public func unitScale(forMesh meshName: String) -> simd_float4x4 {
        guard let mesh = meshesTable[meshName] else {
            return matrix_identity_float4x4
        }
        
        return mesh.unitScale
    }
}
