//
//  Data.swift
//  Day 16
//
//  Created by Stephen H. Gerstacker on 2022-12-16.
//  SPDX-License-Identifier: MIT
//

import Foundation

let SampleData = """
Valve AA has flow rate=0; tunnels lead to valves DD, II, BB
Valve BB has flow rate=13; tunnels lead to valves CC, AA
Valve CC has flow rate=2; tunnels lead to valves DD, BB
Valve DD has flow rate=20; tunnels lead to valves CC, AA, EE
Valve EE has flow rate=3; tunnels lead to valves FF, DD
Valve FF has flow rate=0; tunnels lead to valves EE, GG
Valve GG has flow rate=0; tunnels lead to valves FF, HH
Valve HH has flow rate=22; tunnel leads to valve GG
Valve II has flow rate=0; tunnels lead to valves AA, JJ
Valve JJ has flow rate=21; tunnel leads to valve II
"""

let InputData = """
Valve GS has flow rate=0; tunnels lead to valves KB, GW
Valve CB has flow rate=0; tunnels lead to valves GW, CT
Valve TP has flow rate=0; tunnels lead to valves LR, TH
Valve FI has flow rate=3; tunnels lead to valves DA, AY, ZO, MP, XP
Valve WV has flow rate=0; tunnels lead to valves TH, HG
Valve EA has flow rate=16; tunnels lead to valves PL, NG, AX
Valve AT has flow rate=9; tunnels lead to valves ZO, EM
Valve WS has flow rate=0; tunnels lead to valves GW, RD
Valve MP has flow rate=0; tunnels lead to valves AA, FI
Valve GE has flow rate=0; tunnels lead to valves AX, QN
Valve SA has flow rate=10; tunnels lead to valves NI, OM, RD, RC, GO
Valve NI has flow rate=0; tunnels lead to valves SA, YG
Valve GO has flow rate=0; tunnels lead to valves TH, SA
Valve IT has flow rate=0; tunnels lead to valves WB, KB
Valve NG has flow rate=0; tunnels lead to valves EA, KF
Valve RD has flow rate=0; tunnels lead to valves SA, WS
Valve LR has flow rate=12; tunnels lead to valves TP, XR
Valve TO has flow rate=22; tunnel leads to valve VW
Valve WF has flow rate=0; tunnels lead to valves XX, OO
Valve YD has flow rate=21; tunnel leads to valve NR
Valve XR has flow rate=0; tunnels lead to valves LR, KB
Valve KF has flow rate=0; tunnels lead to valves GW, NG
Valve OO has flow rate=0; tunnels lead to valves UD, WF
Valve HG has flow rate=0; tunnels lead to valves WV, YG
Valve CT has flow rate=0; tunnels lead to valves YG, CB
Valve DA has flow rate=0; tunnels lead to valves TH, FI
Valve YY has flow rate=0; tunnels lead to valves AA, YG
Valve VW has flow rate=0; tunnels lead to valves TO, EM
Valve RC has flow rate=0; tunnels lead to valves AA, SA
Valve PL has flow rate=0; tunnels lead to valves AA, EA
Valve TH has flow rate=14; tunnels lead to valves GO, WV, GJ, DA, TP
Valve QN has flow rate=24; tunnels lead to valves LC, GE
Valve XE has flow rate=0; tunnels lead to valves NA, XX
Valve XP has flow rate=0; tunnels lead to valves FI, OM
Valve AX has flow rate=0; tunnels lead to valves GE, EA
Valve EM has flow rate=0; tunnels lead to valves AT, VW
Valve NR has flow rate=0; tunnels lead to valves YD, PM
Valve YG has flow rate=4; tunnels lead to valves AY, HG, NI, YY, CT
Valve PM has flow rate=0; tunnels lead to valves UD, NR
Valve AY has flow rate=0; tunnels lead to valves YG, FI
Valve GJ has flow rate=0; tunnels lead to valves AA, TH
Valve LC has flow rate=0; tunnels lead to valves QN, GW
Valve UD has flow rate=17; tunnels lead to valves OO, PM
Valve AA has flow rate=0; tunnels lead to valves MP, GJ, YY, RC, PL
Valve OM has flow rate=0; tunnels lead to valves XP, SA
Valve WB has flow rate=0; tunnels lead to valves NA, IT
Valve GW has flow rate=11; tunnels lead to valves KF, GS, LC, CB, WS
Valve NA has flow rate=7; tunnels lead to valves WB, XE
Valve XX has flow rate=20; tunnels lead to valves XE, WF
Valve ZO has flow rate=0; tunnels lead to valves AT, FI
Valve KB has flow rate=8; tunnels lead to valves XR, GS, IT
"""
