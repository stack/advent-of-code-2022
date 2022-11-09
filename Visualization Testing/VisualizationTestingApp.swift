//
//  VisualizationTestingApp.swift
//  VisualizationTesting
//
//  Created by Stephen H. Gerstacker on 2022-11-03.
//  Copyright © 2022 Stephen H. Gerstacker. All rights reserved.
//

import SwiftUI
import Visualization

@main
struct VisualizationTestingApp: App {
    
    @StateObject var context: SolutionContext = VisualizationTestingContext(width: 800, height: 800, frameRate: 60.0)
    
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
