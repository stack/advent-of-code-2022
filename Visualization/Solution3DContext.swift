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
fileprivate let MaxConstantsSize = 1024 * 1024 * 3
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

// MARK: - Scene Objects

fileprivate struct Material {
    var baseColor: SIMD4<Float> = DefaultBaseColor
    var baseColorTexture: MTLTexture? = nil
    
    var metallicFactor: Float = DefaultMetallicFactor
    var metallicTexture: MTLTexture? = nil
    
    var roughnessFactor: Float = DefaultRoughnessFactor
    var roughnessTexture: MTLTexture? = nil
    
    var normalTexture: MTLTexture? = nil
    var ambientOcclusionTexture: MTLTexture? = nil
    
    var emissiveColor: SIMD4<Float> = DefaultEmissiveColor
    var emissiveTexture: MTLTexture? = nil
    
    var opacity: Float = DefaultOpacityValue
    
    init() { }
    
    init(material sourceMaterial: MDLMaterial, device: MTLDevice) {
        baseColor = float4(for: .baseColor, in: sourceMaterial, defaultValue: DefaultBaseColor)
        baseColorTexture = texture(for: .baseColor, in: sourceMaterial, device: device)
        
        metallicFactor = float(for: .metallic, in: sourceMaterial, defaultValue: DefaultMetallicFactor)
        metallicTexture = texture(for: .metallic, in: sourceMaterial, device: device)
        
        roughnessFactor = float(for: .roughness, in: sourceMaterial, defaultValue: DefaultRoughnessFactor)
        roughnessTexture = texture(for: .roughness, in: sourceMaterial, device: device)
        
        normalTexture = texture(for: .tangentSpaceNormal, in: sourceMaterial, device: device)
        ambientOcclusionTexture = texture(for: .ambientOcclusion, in: sourceMaterial, device: device)
        
        emissiveColor = float4(for: .emission, in: sourceMaterial, defaultValue: DefaultEmissiveColor)
        emissiveTexture = texture(for: .emission, in: sourceMaterial, device: device)
        
        opacity = float(for: .opacity, in: sourceMaterial, defaultValue: DefaultOpacityValue)
        
        /*
        let allSemantics: [MDLMaterialSemantic] = [
            .baseColor, .subsurface, .metallic, .specular, .specularExponent, .specularTint,
            .roughness, .anisotropic, .anisotropicRotation, .sheen, .sheenTint ,
            .clearcoat , .clearcoatGloss , .emission , .bump , .opacity , .interfaceIndexOfRefraction ,
            .materialIndexOfRefraction , .objectSpaceNormal , .tangentSpaceNormal , .displacement , .displacementScale ,
            .ambientOcclusion , .ambientOcclusionScale
        ]
        
        for semantics in allSemantics {
            guard let property = sourceMaterial?.property(with: semantics) else { continue }
            
            switch property.type {
            case .texture:
                print("Texture (\(property.name) - \(semantics)): \(property.textureSamplerValue)")
            case .color:
                print("Color (\(property.name) - \(semantics)): \(property.color)")
            case .float:
                print("Float (\(property.name) - \(semantics)): \(property.floatValue)")
            case .float3:
                print("Float 3 (\(property.name) - \(semantics)): \(property.float3Value)")
            default:
                print("Unhandled (\(property.name) - \(semantics)): \(property.type)")
            }
            
            if let url = property.urlValue {
                print("Additional URL (\(property.name) - \(semantics)): \(url)")
            }
        }
         */
    }
    
    private func float(for semantic: MDLMaterialSemantic, in material: MDLMaterial, defaultValue: Float) -> Float {
        guard let property = material.property(with: semantic) else { return defaultValue }
        guard property.type == .float else { return defaultValue }
        
        return property.floatValue
    }
    
    private func float4(for semantic: MDLMaterialSemantic, in material: MDLMaterial, defaultValue: SIMD4<Float>) -> SIMD4<Float> {
        guard let property = material.property(with: semantic) else { return defaultValue }
        
        switch property.type {
        case .float3:
            return SIMD4<Float>(property.float3Value, 1)
        case .float4:
            return property.float4Value
        case .color:
            let color = property.color ?? CGColor.white
            let colorSpace = CGColorSpace(name: CGColorSpace.linearSRGB)!
            
            if let matchedColor = color.converted(to: colorSpace, intent: .defaultIntent, options: nil), let components = matchedColor.components {
                return SIMD4<Float>(components.map { Float($0) })
            } else {
                return SIMD4<Float>(repeating: 1.0)
            }
        default:
            return defaultValue
        }
    }
    
    private func texture(for semantic: MDLMaterialSemantic, in material: MDLMaterial, device: MTLDevice) -> MTLTexture? {
        guard let property = material.property(with: semantic) else { return nil }
        guard property.type == .texture else { return nil }
        guard let mdlTexture = property.textureSamplerValue?.texture else { return nil }
        
        let textureLoaderOptions: [MTKTextureLoader.Option:Any] = [
            .generateMipmaps : true,
            .textureUsage : MTLTextureUsage.shaderRead.rawValue,
            .textureStorageMode : MTLStorageMode.private.rawValue,
            .origin : MTKTextureLoader.Origin.flippedVertically.rawValue
        ]
        
        let textureLoader = MTKTextureLoader(device: device)
        
        var texture: MTLTexture?
        
        do {
            texture = try textureLoader.newTexture(texture: mdlTexture, options: textureLoaderOptions)
        } catch {
            texture = nil
        }
            
        
        return texture
    }
}

fileprivate class Mesh {
    let name: String
    
    let meshes: [MTKMesh]
    let materials: [[Material]]
    
    init(name: String, meshes: [MTKMesh], materials: [[Material]]) {
        self.name = name
        self.meshes = meshes
        self.materials = materials
    }
}

fileprivate class Node {
    
    weak var parentNode: Node?
    private(set) var childNodes: [Node] = []
    
    let name: String
    let mesh: MTKMesh
    var materials: [Material]
    
    let isDrawable: Bool
    let isInstanced: Bool
    
    var transforms: [simd_float4x4] = []
    
    init(name: String, mesh: MTKMesh , materials: [Material], isDrawable: Bool = true, instances: Int = 1) {
        self.name = name
        self.mesh = mesh
        self.materials = materials
        self.isDrawable = isDrawable
        
        if instances == 1 {
            isInstanced = false
            transforms = [matrix_identity_float4x4]
        } else {
            isInstanced = true
            transforms = [simd_float4x4](repeating: matrix_identity_float4x4, count: instances)
        }
    }
    
    func position(at index: Int) -> SIMD3<Float> {
        return worldTransform(at: index).columns.3.xyz
    }
    
    func worldTransform(at index: Int) -> simd_float4x4 {
        if let parentNode {
            return parentNode.worldTransform(at: 0) * transforms[index]
        } else {
            return transforms[index]
        }
    }
    
    var worldTransforms: [simd_float4x4] {
        if let parentNode {
            return transforms.map { parentNode.worldTransform(at: 0) * $0 }
        } else {
            return transforms
        }
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
    
    private var meshes: [String:Mesh] = [:]
    private var nodesTable: [String:Node] = [:]
    private var nodes: [Node] = []
    
    private var textures: [String:MTLTexture] = [:]
    
    private var pointOfView: simd_float4x4 = matrix_identity_float4x4
    private var lightsTable: [String:Light] = [:]
    private var lights: [Light] = []
    
    private var commandQueue: MTLCommandQueue!
    private var constantBuffer: MTLBuffer!
    private var pipelineState: MTLRenderPipelineState!
    private var depthStencilState: MTLDepthStencilState!
    
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
    
    public func loadMesh(name: String, fromResource resource: String) throws {
        guard let url = Bundle.main.url(forResource: resource, withExtension: "usdz") else {
            throw SolutionError.apiError("No mesh resource for \(name)")
        }
        
        var finalMeshes: [MTKMesh] = []
        var finalMaterials: [[Material]] = []
        
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
        
        let (sourceMeshes, meshes) = try MTKMesh.newMeshes(asset: mdlAsset, device: renderer.metalDevice)
        
        for (sourceMesh, mesh) in zip(sourceMeshes, meshes) {
            var materials: [Material] = []
            
            for sourceSubmesh in sourceMesh.submeshes as! [MDLSubmesh] {
                if let mdlMaterial = sourceSubmesh.material {
                    let material = Material(material: mdlMaterial, device: renderer.metalDevice)
                    materials.append(material)
                }
            }
            
            finalMeshes.append(mesh)
            finalMaterials.append(materials)
        }
        
        let finalMesh = Mesh(name: name, meshes: finalMeshes, materials: finalMaterials)
        self.meshes[name] = finalMesh
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
        
        var material = Material()
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
        
        let mesh = Mesh(name: name, meshes: [mtkMesh], materials: [[material]])
        
        meshes[name] = mesh
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
        
        var material = Material()
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
        
        let mesh = Mesh(name: name, meshes: [mtkMesh], materials: [[material]])
        
        meshes[name] = mesh
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
        
        var material = Material()
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
        
        let mesh = Mesh(name: name, meshes: [mtkMesh], materials: [[material]])
        
        meshes[name] = mesh
    }
    
    public func loadTexture(name: String, resource: String, withExtension ext: String) throws {
        guard let url = Bundle.main.url(forResource: resource, withExtension: ext) else {
            throw SolutionError.apiError("No texture resource for \(name)")
        }
        
        let texture = try textureLoader.newTexture(URL: url, options: textureOptions)
        
        textures[name] = texture
    }
    
    // MARK: - Node Management
    
    public func addNode(name: String, mesh: String, parent parentName: String? = nil, instances: Int = 1) {
        guard let mesh = meshes[mesh] else { return }
        
        let rootNode: Node
        
        if mesh.meshes.count == 1 {
            rootNode = Node(name: name, mesh: mesh.meshes[0], materials: mesh.materials[0], instances: instances)
        } else {
            rootNode = Node(name: name, mesh: mesh.meshes[0], materials: mesh.materials[0], isDrawable: false, instances: instances)
            
            for childIndex in 0 ..< mesh.meshes.count {
                let nodeName = "\(name)_\(childIndex)"
                let mtkMesh = mesh.meshes[childIndex]
                let materials = mesh.materials[childIndex]
                
                let childNode = Node(name: nodeName, mesh: mtkMesh, materials: materials)
                
                nodesTable[nodeName] = childNode
                nodes.append(childNode)
                
                rootNode.addChildNode(childNode)
            }
        }
        
        nodesTable[name] = rootNode
        nodes.append(rootNode)
        
        if let parentName, let parentNode = nodesTable[parentName] {
            parentNode.addChildNode(rootNode)
        }
    }
    
    public func removeNode(name: String) {
        guard let node = nodesTable[name] else { return }
        
        for childNode in node.childNodes {
            removeNode(name: childNode.name)
        }
        
        nodesTable.removeValue(forKey: name)
        nodes.removeAll(where: { $0 === node })
    }
    
    public func updateNode(name: String, instance: Int = 0, transform: simd_float4x4? = nil, materialIndex: Int = 0, baseColor: SIMD4<Float>? = nil, metallicFactor: Float? = nil, roughnessFactor: Float? = nil, emissiveColor: SIMD4<Float>? = nil, opacity: Float? = nil) {
        guard let node = nodesTable[name] else {
            return
        }
        
        if let transform { node.transforms[instance] = transform }
        
        if let baseColor { node.materials[materialIndex].baseColor = baseColor }
        if let metallicFactor { node.materials[materialIndex].metallicFactor = metallicFactor }
        if let roughnessFactor { node.materials[materialIndex].roughnessFactor = roughnessFactor }
        if let emissiveColor { node.materials[materialIndex].emissiveColor = emissiveColor }
        if let opacity { node.materials[materialIndex].opacity = opacity }
    }
    
    // MARK: - Light & Camera Management
    
    public func addDirectLight(name: String, lookAt target: SIMD3<Float>, from origin: SIMD3<Float>, up: SIMD3<Float>, color: SIMD3<Float> = SIMD3<Float>(1, 1, 1), intensity: Float = 1.0) {
        let light = Light()
        light.type = .directional
        light.worldTransform = simd_float4x4(lookAt: target, from: origin, up: up)
        light.color = color
        light.intensity = intensity
        
        lightsTable[name] = light
        lights.append(light)
    }
    
    public func addPointLight(name: String, color: SIMD3<Float> = SIMD3<Float>(1, 1, 1), intensity: Float = 1.0) {
        let light = Light()
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
        
        encoder.setVertexBuffer(constantBuffer, offset: 0, index: VertexBufferIndex.nodeConstants)
        encoder.setVertexBuffer(constantBuffer, offset: frameConstantsOffset, index: VertexBufferIndex.frameConstants)
        encoder.setVertexBuffer(constantBuffer, offset: lightConstantsOffset, index: VertexBufferIndex.lightConstants)
        
        encoder.setFragmentBuffer(constantBuffer, offset: 0, index: FragmentBufferIndex.materialConstants)
        encoder.setFragmentBuffer(constantBuffer, offset: frameConstantsOffset, index: FragmentBufferIndex.frameConstants)
        encoder.setFragmentBuffer(constantBuffer, offset: lightConstantsOffset, index: FragmentBufferIndex.lightConstants)
        
        let nodeLayout = MemoryLayout<NodeConstants>.self
        let materialLayout = MemoryLayout<MaterialConstants>.self
        
        for (objectIndex, node) in nodes.enumerated() {
            guard node.isDrawable else { continue }
            
            encoder.pushDebugGroup("Node \(node.name)")
            
            encoder.setVertexBufferOffset(nodeConstantsOffset[objectIndex], index: VertexBufferIndex.nodeConstants)
        
            for (meshIndex, meshBuffer) in node.mesh.vertexBuffers.enumerated() {
                encoder.setVertexBuffer(meshBuffer.buffer, offset: meshBuffer.offset, index: meshIndex)
            }
            
            for (submeshIndex, submesh) in node.mesh.submeshes.enumerated() {
                let material = node.materials[submeshIndex]
                
                encoder.setFragmentTexture(material.baseColorTexture, index: FragmentTextureIndex.baseColor)
                encoder.setFragmentTexture(material.emissiveTexture, index: FragmentTextureIndex.emissive)
                encoder.setFragmentTexture(material.normalTexture, index: FragmentTextureIndex.normal)
                encoder.setFragmentTexture(material.metallicTexture, index: FragmentTextureIndex.metalness)
                encoder.setFragmentTexture(material.roughnessTexture, index: FragmentTextureIndex.roughness)
                encoder.setFragmentTexture(material.ambientOcclusionTexture, index: FragmentTextureIndex.ambientOcclusion)
                                           
                encoder.setFragmentBufferOffset(nodeConstantsOffset[objectIndex] + (nodeLayout.stride * node.transforms.count) + (materialLayout.stride * submeshIndex), index: FragmentBufferIndex.materialConstants)
                let indexBuffer = submesh.indexBuffer
                
                encoder.drawIndexedPrimitives(
                    type: submesh.primitiveType,
                    indexCount: submesh.indexCount,
                    indexType: submesh.indexType,
                    indexBuffer: indexBuffer.buffer,
                    indexBufferOffset: indexBuffer.offset,
                    instanceCount: node.transforms.count
                )
            }
            
            encoder.popDebugGroup()
        }
        
        encoder.endEncoding()
    }
    
    private func updateFrameConstants() {
        let aspectRatio = Float(width) / Float(height)
        let projectionMatrix = simd_float4x4(
            perspectiveProjectionFoVY: .pi / 3,
            aspectRatio: aspectRatio,
            near: 0.01,
            far: 1000
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
    }
    
    private func updateLightConstants() {
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
    }
    
    private func updateNodeConstants() {
        let nodeLayout = MemoryLayout<NodeConstants>.self
        let materialLayout = MemoryLayout<MaterialConstants>.self
        
        nodeConstantsOffset.removeAll(keepingCapacity: true)
        
        for node in nodes {
            guard node.isDrawable else { continue }
            
            var nodeConstants = (0 ..< node.worldTransforms.count).map { instanceIndex -> NodeConstants in
                let modelMatrix = node.worldTransform(at: instanceIndex)
                let modelViewMatrix = pointOfView.inverse * modelMatrix
                let normalMatrix = modelViewMatrix.upperLeft3x3.transpose.inverse
                
                return NodeConstants(modelMatrix: modelMatrix, normalMatrix: normalMatrix)
            }
            
            let totalSize = (nodeLayout.stride * node.transforms.count) + (materialLayout.stride * node.materials.count)
            let totalStride = totalSize
            
            let offset = allocateConstantStorage(size: totalSize, alignment: totalStride)
            let constantsPointer = constantBuffer.contents().advanced(by: offset)
            constantsPointer.copyMemory(from: &nodeConstants, byteCount: nodeLayout.stride * node.transforms.count)
            
            for (materialIndex, material) in node.materials.enumerated() {
                var constants = MaterialConstants(
                    baseColor: material.baseColor,
                    emissiveColor: material.emissiveColor,
                    metallicFactor: material.metallicFactor,
                    roughnessFactor: material.roughnessFactor,
                    occlusionWeight: 1.0,
                    opacity: material.opacity
                )
                
                let constantsPointer = constantBuffer.contents().advanced(by: offset + (nodeLayout.stride * node.transforms.count) + (materialLayout.stride * materialIndex))
                constantsPointer.copyMemory(from: &constants, byteCount: materialLayout.size)
            }
            
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
