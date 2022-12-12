//
//  main.swift
//  Day 06
//
//  Created by Stephen H. Gerstacker on 2022-12-06.
//  SPDX-License-Identifier: MIT
//

import Algorithms
import Foundation

// MARK: - Part 1

func firstPacketMarker(data: String) -> (String, Int) {
    for (markerIndex, marker) in data.windows(ofCount: 4).enumerated() {
        let characters = Set(marker)
        
        if characters.count == 4 {
            return (String(marker), markerIndex + 4)
        }
    }
    
    fatalError("No marker found")
}

for data in [SampleData1, SampleData2, SampleData3, SampleData4, SampleData5] {
    let (marker, index) = firstPacketMarker(data: data)
    
    print("Sample Packet Marker: \(marker): Index: \(index)")
}

let (packetMarker, packetIndex) = firstPacketMarker(data: InputData)
print("Packet Marker: \(packetMarker): Index: \(packetIndex)")

// MARK: - Part 2

func firstMessageMarker(data: String) -> (String, Int) {
    for (markerIndex, marker) in data.windows(ofCount: 14).enumerated() {
        let characters = Set(marker)
        
        if characters.count == 14 {
            return (String(marker), markerIndex + 14)
        }
    }
    
    fatalError("No marker found")
}

for data in [SampleData6, SampleData7, SampleData8, SampleData9, SampleData10] {
    let (marker, index) = firstMessageMarker(data: data)
    
    print("Sample Message Marker: \(marker): Index: \(index)")
}

let (messageMarker, messageIndex) = firstMessageMarker(data: InputData)
print("Message Marker: \(messageMarker): Index: \(messageIndex)")

