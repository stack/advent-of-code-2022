//
//  SolutionView.swift
//  Advent of Code 2022 Common
//
//  Created by Stephen H. Gerstacker on 2022-11-03.
//  Copyright © 2022 Stephen H. Gerstacker. All rights reserved.
//

import SwiftUI

public struct SolutionView: View {
    
    private enum Status {
        case ready
        case running
        case completing
        case done
        case error
    }
    
    @EnvironmentObject var context: SolutionContext
    
    @State private var status: Status = .ready
    
    @State private var lastError: Error? = nil
    @State private var errorTitle: String = ""
    @State private var isErrorShowing: Bool = false
    
    @State private var document: SolutionVideoFile? = nil
    @State private var isExportShowing: Bool = false
    
    public init() { }
    
    public var body: some View {
        SolutionRenderView(renderer: context.renderer)
            .alert(errorTitle, isPresented: $isErrorShowing, presenting: lastError, actions: { error in
                Button("OK") { }
            }, message: { error in
                Text(error.localizedDescription)
            })
            .fileExporter(isPresented: $isExportShowing, document: document, contentType: .mpeg4Movie, defaultFilename: "\(context.name)", onCompletion: { result in
                if case .failure(let error) = result {
                    lastError = error
                    errorTitle = "Failed to export file"
                    isErrorShowing = true
                }
            })
            .toolbar(content: {
                ToolbarItem {
                    Button(action: startRunning) {
                        Image(systemName: "play")
                    }
                    .disabled(status != .ready)
                }
                
            })
    }
    
    private func startRunning() {
        let temporaryURL = FileManager.default.temporaryDirectory
        let outputURL = temporaryURL.appending(component: "\(context.name).mp4")
        
        if FileManager.default.fileExists(atPath: outputURL.path(percentEncoded: false)) {
            try! FileManager.default.removeItem(at: outputURL)
        }
        
        status = .running
        
        Task {
            do {
                try await context.prepare(url: outputURL)
                try await context.run()
                
                await MainActor.run { status = .completing }
                
                try await context.complete()
                
                await MainActor.run {
                    status = .done
                    
                    document = SolutionVideoFile(sourceURL: outputURL)
                    isExportShowing = true
                }
            } catch {
                lastError = error
                errorTitle = "Failed to prepare context"
                
                isErrorShowing = true
                
                status = .done
            }
        }
    }
}

struct SolutionView_Previews: PreviewProvider {
    static var previews: some View {
        let context = SolutionContext(width: 400, height: 400, frameRate: 30)
        
        SolutionView()
            .environmentObject(context)
    }
}
