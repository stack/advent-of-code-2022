//
//  Day10VisualizedApp.swift
//  Day 10
//
//  Created by Stephen H. Gerstacker on 2022-12-10.
//  Copyright © 2022 Stephen H. Gerstacker. All rights reserved.
//

import SwiftUI
import Visualization

@main
struct Day10VisualizedApp: App {
    
    @StateObject var context: SolutionContext = DisplayContext(width: 1920, height: 1080, frameRate: 60.0)
    
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
