//
//  Data.swift
//  Day 15
//
//  Created by Stephen Gerstacker on 2022-12-15.
//  SPDX-License-Identifier: MIT
//

import Foundation

let SampleData = """
Sensor at x=2, y=18: closest beacon is at x=-2, y=15
Sensor at x=9, y=16: closest beacon is at x=10, y=16
Sensor at x=13, y=2: closest beacon is at x=15, y=3
Sensor at x=12, y=14: closest beacon is at x=10, y=16
Sensor at x=10, y=20: closest beacon is at x=10, y=16
Sensor at x=14, y=17: closest beacon is at x=10, y=16
Sensor at x=8, y=7: closest beacon is at x=2, y=10
Sensor at x=2, y=0: closest beacon is at x=2, y=10
Sensor at x=0, y=11: closest beacon is at x=2, y=10
Sensor at x=20, y=14: closest beacon is at x=25, y=17
Sensor at x=17, y=20: closest beacon is at x=21, y=22
Sensor at x=16, y=7: closest beacon is at x=15, y=3
Sensor at x=14, y=3: closest beacon is at x=15, y=3
Sensor at x=20, y=1: closest beacon is at x=15, y=3
"""

let InputData = """
Sensor at x=655450, y=2013424: closest beacon is at x=967194, y=2000000
Sensor at x=1999258, y=1017714: closest beacon is at x=3332075, y=572515
Sensor at x=2159800, y=3490958: closest beacon is at x=2145977, y=3551728
Sensor at x=3990472, y=1891598: closest beacon is at x=3022851, y=2629972
Sensor at x=188608, y=354698: closest beacon is at x=-1037755, y=-391680
Sensor at x=286630, y=3999086: closest beacon is at x=-1202308, y=3569538
Sensor at x=2022540, y=3401295: closest beacon is at x=2013531, y=3335868
Sensor at x=65063, y=2648597: closest beacon is at x=967194, y=2000000
Sensor at x=2533266, y=439414: closest beacon is at x=3332075, y=572515
Sensor at x=1728594, y=2416005: closest beacon is at x=967194, y=2000000
Sensor at x=1156357, y=1867331: closest beacon is at x=967194, y=2000000
Sensor at x=825519, y=3323952: closest beacon is at x=2013531, y=3335868
Sensor at x=3278267, y=201451: closest beacon is at x=3332075, y=572515
Sensor at x=3679732, y=1213595: closest beacon is at x=3332075, y=572515
Sensor at x=896808, y=1637672: closest beacon is at x=967194, y=2000000
Sensor at x=2035362, y=3363480: closest beacon is at x=2013531, y=3335868
Sensor at x=2056169, y=3442413: closest beacon is at x=2013531, y=3335868
Sensor at x=2631999, y=1884495: closest beacon is at x=3022851, y=2629972
Sensor at x=3149604, y=3870003: closest beacon is at x=3707835, y=4152776
Sensor at x=3579002, y=1702: closest beacon is at x=3332075, y=572515
Sensor at x=2306088, y=2605428: closest beacon is at x=3022851, y=2629972
Sensor at x=2428132, y=3171598: closest beacon is at x=2013531, y=3335868
Sensor at x=1447212, y=3938104: closest beacon is at x=2145977, y=3551728
Sensor at x=3131240, y=3166665: closest beacon is at x=3022851, y=2629972
Sensor at x=3865496, y=2980765: closest beacon is at x=3022851, y=2629972
Sensor at x=2508598, y=3611761: closest beacon is at x=2145977, y=3551728
Sensor at x=2144092, y=3514660: closest beacon is at x=2145977, y=3551728
Sensor at x=3947251, y=469499: closest beacon is at x=3332075, y=572515
"""
