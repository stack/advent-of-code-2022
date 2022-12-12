//
//  SolutionError.swift
//  Visualization
//
//  Created by Stephen H. Gerstacker on 2022-11-09.
//  SPDX-License-Identifier: MIT
//

import Foundation

public enum SolutionError: LocalizedError {
    
    case apiError(String)
    case wrapped(String,Error)
    
    public var errorDescription: String? {
        return localizedDescription
    }
    
    public var localizedDescription: String {
        switch self {
        case .apiError(let message): return message
        case .wrapped(let message, let error): return "\(message): \(error.localizedDescription)"
        }
    }
}
