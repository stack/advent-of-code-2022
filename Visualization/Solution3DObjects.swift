//
//  Solution3DObjects.swift
//  Visualization
//
//  Created by Stephen H. Gerstacker on 2022-11-28.
//  SPDX-License-Identifier: MIT
//

import Foundation
import Metal
import MetalKit
import ModelIO

class SolutionLight {
    
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

class SolutionNode {
    let name: String
    var mesh: SolutionMesh
    let batch: String?
    
    var transform: simd_float4x4
    
    private weak var parent: SolutionNode? = nil
    private(set) var children: [SolutionNode] = []
    
    var position: SIMD3<Float> {
        worldTransform.columns.3.xyz
    }
    
    var worldTransform: simd_float4x4 {
        if let parent {
            return parent.worldTransform * transform
        } else {
            return transform
        }
    }
    
    init(name: String, mesh: SolutionMesh, batch: String? = nil, transform: simd_float4x4 = matrix_identity_float4x4) {
        self.name = name
        self.batch = batch
        self.mesh = mesh
        
        self.transform = transform
    }
    
    func addChild(_ node: SolutionNode) {
        children.append(node)
        node.parent = self
    }
    
    func removeFromParent() {
        parent?.removeChild(self)
    }
    
    private func removeChild(_ node: SolutionNode) {
        children.removeAll { $0 === node }
    }
}

struct SolutionMesh {
    let name: String
    let bounds: SIMD3<Float>
    var submeshes: [SolutionSubmesh]
    
    var unitScale: simd_float4x4 {
        var factor = bounds.max()
        
        if factor == 0.0 {
            factor = 1.0
        }
        
        return simd_float4x4(scale: SIMD3<Float>(repeating: 1.0 / factor))
    }
    
    init(name: String, bounds: SIMD3<Float>, submeshes: [SolutionSubmesh]) {
        self.name = name
        self.bounds = bounds
        self.submeshes = submeshes
    }
}

struct SolutionSubmesh {
    
    let mtkMesh: MTKMesh
    var materails: [SolutionMaterial]
    
    init(mtkMesh: MTKMesh, materials: [SolutionMaterial]) {
        self.mtkMesh = mtkMesh
        self.materails = materials
    }
}

struct SolutionMaterial {
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
            .generateMipmaps : false,
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
