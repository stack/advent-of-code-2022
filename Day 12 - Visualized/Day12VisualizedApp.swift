//
//  Day12VisualizedApp.swift
//  Day 12 - Visualized
//
//  Created by Stephen H. Gerstacker on 2022-12-12.
//  SPDX-License-Identifier: MIT
//

import SwiftUI
import Visualization

@main
struct Day12VisualizedApp: App {
    
    @StateObject var context: SolutionContext = TerrainContext(width: 1920, height: 1080, frameRate: 60.0, maxConstantsSize: 1024 * 1024 * 5)
    
    var body: some Scene {
        WindowGroup {
#if os(macOS)
            SolutionView()
                .environmentObject(context)
                .navigationTitle(context.name)
#else
            NavigationStack {
                SolutionView()
                    .environmentObject(context)
                    .navigationTitle(context.name)
                    .navigationBarTitleDisplayMode(.inline)
                    .ignoresSafeArea(.all, edges: [.bottom])
            }
#endif
        }
    }
}
