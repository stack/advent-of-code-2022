//
//  Visualization3DTestingApp.swift
//  Visualization 3D Testing
//
//  Created by Stephen H. Gerstacker on 2022-11-12.
//  Copyright © 2022 Stephen H. Gerstacker. All rights reserved.
//

import SwiftUI
import Visualization

@main
struct Visualization3DTestingApp: App {
    @StateObject var context: SolutionContext = Visualization3DTestingContext(width: 1920, height: 1080, frameRate: 60.0)
    
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
