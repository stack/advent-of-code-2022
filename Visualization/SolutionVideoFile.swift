//
//  SolutionVideoFile.swift
//  Advent of Code 2022 Common
//
//  Created by Stephen H. Gerstacker on 2022-11-03.
//  Copyright © 2022 Stephen H. Gerstacker. All rights reserved.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers
import Utilities

struct SolutionVideoFile: FileDocument {
    
    static var readableContentTypes = [UTType.mpeg4Movie]
    
    private let sourceURL: URL
    
    init(sourceURL: URL) {
        self.sourceURL = sourceURL
    }
    
    init(configuration: ReadConfiguration) throws {
        throw SolutionError.apiError("Cannot init with read configuration")
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return try FileWrapper(url: sourceURL)
    }
}
