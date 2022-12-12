//
//  SolutionRenderView.swift
//  Advent of Code 2022 Common
//
//  Created by Stephen H. Gerstacker on 2022-11-03.
//  SPDX-License-Identifier: MIT
//

import MetalKit
import SwiftUI

#if os(macOS)
import AppKit
typealias ViewController = NSViewController
typealias ViewControllerRepresentable = NSViewControllerRepresentable
#else
typealias ViewController = UIViewController
typealias ViewControllerRepresentable = UIViewControllerRepresentable
#endif

class SolutionRenderViewController: ViewController, MTKViewDelegate {
    
    // MARK: - Properties
    
    private let renderer: SolutionRenderer
    
    private var screenObserver: Any? = nil
    
    private var mtkView: MTKView {
        return view as! MTKView
    }
    
    
    // MARK: - Initialization
    
    init(renderer: SolutionRenderer) {
        self.renderer = renderer
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: - NSViewController Methods
    
    override func loadView() {
        let mtkView = MTKView(frame: .zero, device: renderer.metalDevice)
        mtkView.delegate = self
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        
        view = mtkView
    }
    
#if os(macOS)
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        screenObserver = NotificationCenter.default.addObserver(forName: NSWindow.didChangeScreenNotification, object: nil, queue: nil, using: { [weak self] notification in
            guard let self else { return }
            guard let swiftUIWindow = notification.object else { return }
            guard let window = swiftUIWindow as? NSWindow else { return }
            guard let screen = window.screen else { return }
            
            self.mtkView.preferredFramesPerSecond = screen.maximumFramesPerSecond
        })
        
        if let maximumFramesPerSecond = view.window?.screen?.maximumFramesPerSecond {
            mtkView.preferredFramesPerSecond = maximumFramesPerSecond
        }
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        
        if let screenObserver {
            NotificationCenter.default.removeObserver(screenObserver)
            self.screenObserver = nil
        }
    }
    
#else
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
#endif
    
    // MARK: - MTKViewDelegate Protocol
    
    func draw(in view: MTKView) {
        guard view.bounds.width > 0 && view.bounds.height > 0 else { return }
        guard let drawable = view.currentDrawable else { return }
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
        
        renderer.draw(drawable: drawable, renderPassDescriptor: renderPassDescriptor)
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        renderer.resize(size)
    }
}

struct SolutionRenderView: ViewControllerRepresentable {
    
    var renderer: SolutionRenderer
    
#if os(macOS)
    
    func makeNSViewController(context: Context) -> SolutionRenderViewController {
        return SolutionRenderViewController(renderer: renderer)
    }
    
    func updateNSViewController(_ nsViewController: SolutionRenderViewController, context: Context) {
    }
    
#else
    
    func makeUIViewController(context: Context) -> SolutionRenderViewController {
        return SolutionRenderViewController(renderer: renderer)
    }
    
    func updateUIViewController(_ uiViewController: SolutionRenderViewController, context: Context) {
        
    }
    
#endif
}

struct SolutionRenderView_Previews: PreviewProvider {
    static var previews: some View {
        SolutionRenderView(renderer: SolutionRenderer())
            .frame(width: 300, height: 300)
    }
}
