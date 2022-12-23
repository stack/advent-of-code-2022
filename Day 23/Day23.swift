//
//  main.swift
//  Day 23
//
//  Created by Stephen Gerstacker on 2022-12-23.
//  SPDX-License-Identifier: MIT
//

import Algorithms
import Foundation
import Utilities

@main
struct Day23 {
    
    static func main() async throws {
        print("== Part 1 ==")
        
        let smallSampleField = Field(data: SampleData1)
        let (smallSampleEmpty, smallSampleRounds) = smallSampleField.run(maxRounds: 10)
        
        print("Sample 1 Empty: \(smallSampleEmpty) after \(smallSampleRounds) rounds")
        
        let sampleField1 = Field(data: SampleData2)
        let (sampleEmpty1, sampleRounds1) = sampleField1.run(maxRounds: 10)
        
        print("Sample 2 Empty: \(sampleEmpty1) after \(sampleRounds1) rounds")
        
        let inputField1 = Field(data: InputData)
        let (inputEmpty1, inputRounds1) = inputField1.run(maxRounds: 10)
        
        print("Input Empty: \(inputEmpty1) after \(inputRounds1) rounds")
        
        print()
        print("== Part 2 ==")
        
        let sampleField2 = Field(data: SampleData2)
        let (sampleEmpty2, sampleRounds2) = sampleField2.run(maxRounds: .max)
        
        print("Sample 2 Empty: \(sampleEmpty2) after \(sampleRounds2) rounds")
        
        let inputField2 = Field(data: InputData)
        let (inputEmpty2, inputRounds2) = inputField2.run(maxRounds: .max)
        
        print("Input Empty: \(inputEmpty2) after \(inputRounds2) rounds")
    }
}

