//
//  Day23VisualizedApp.swift
//  Day 23 - Visualized
//
//  Created by Stephen H. Gerstacker on 2022-12-23.
//  SPDX-License-Identifier: MIT
//

import SwiftUI
import Visualization

import SwiftUI

@main
struct Day23VisualizedApp: App {
    @StateObject var context: SolutionContext = FieldContext(width: 1920, height: 1080, frameRate: 60.0, maxConstantsSize: 1024 * 1024 * 10)
    
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
