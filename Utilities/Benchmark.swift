//
//  Benchmark.swift
//  Utilities
//
//  Created by Stephen H. Gerstacker on 2022-12-21.
//  SPDX-License-Identifier: MIT
//

import Foundation

public func benchmark<T>(_ method: () -> T) -> (T, Duration) {
    let clock = ContinuousClock()
    
    let start = clock.now
    let result = method()
    let end = clock.now
    
    let duration = end - start
    
    return (result, duration)
}

public struct BenchmarkFormatStyle: FormatStyle {
    
    public typealias FormatInput = Duration
    public typealias FormatOutput = String
    
    public init() { }
    
    public func format(_ value: Duration) -> String {
        var remainingAttoseconds = value.components.attoseconds
        var remainingSeconds = value.components.seconds
        
        let milliseconds = remainingAttoseconds / 1_000_000_000_000_000
        remainingAttoseconds -= milliseconds * 1_000_000_000_000_000
        
        let microseconds = remainingAttoseconds / 1_000_000_000_000
        remainingAttoseconds -= microseconds * 1_000_000_000_000
        
        let hours = remainingSeconds / 86400
        remainingSeconds -= hours * 86400
        
        let minutes = remainingSeconds / 3600
        remainingSeconds -= minutes * 3600
        
        let seconds = remainingSeconds / 60
        remainingSeconds -= seconds * 60
        
        var parts: [String] = []
        
        if hours != 0 {
            parts.append("\(hours)h")
            parts.append("\(minutes)m")
            parts.append("\(seconds)s")
        } else if minutes != 0 {
            parts.append("\(minutes)m")
            parts.append("\(seconds)s")
        } else if seconds != 0 {
            parts.append("\(seconds)s")
            
            if milliseconds != 0 {
                parts.append("\(milliseconds)ms")
            }
        } else if milliseconds != 0 {
            parts.append("\(milliseconds)ms")
        } else {
            parts.append("\(microseconds)µs")
        }
        
        return parts.joined(separator: " ")
    }
}

public extension FormatStyle where Self == Duration.TimeFormatStyle {
    
    static var benchmark: BenchmarkFormatStyle {
        return BenchmarkFormatStyle()
    }
}
