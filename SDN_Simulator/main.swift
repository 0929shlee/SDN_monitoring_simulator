//
//  main.swift
//  SDN_Simulator
//
//  Created by Seunghyun Lee on 2022/04/27.
//
//

import Foundation

var IS_SIMULATION_FINISHED = false

var GLOBAL_TIME_OFFSET = TimeOffset()

var ENABLE_PACKET_OUT = false
var ENABLE_LLDP = false
var ENABLE_PACKET_IN = false

let SIZE_OF_PACKET_OUT = PacketSize(str: "1K")!
let SIZE_OF_LLDP = PacketSize(str: "1K")!
let SIZE_OF_PACKET_IN = PacketSize(str: "1K")!
let SIZE_OF_DATA_GRAM = PacketSize(str: "1K")!

let NETWORKS_MONITORING_PERIOD = TimeOffset(millisecond: 10)

let NODE_ID_OF_CONTROLLER = NodeID(0)

var topology: Topology = .tree
var nSwitches: UInt = 15
var networks = Networks(topology: topology, nSwitches: nSwitches)

var linkThroughput: Throughput = Throughput(str: "10M")!

var packetSize: PacketSize = PacketSize(str: "10K")!

let timeStep = TimeOffset(microsecond: 10)
//let duration = TimeOffset(millisecond: 9)

//simulation
var RESULT_DELAY_ARR: [UInt] = []
var RESULT_JITTER_ARR: [UInt] = []
var RESULT_STR = ""
var simulationCount = 0

runSimulation()

print(RESULT_STR)

if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
    let fileURL = dir.appendingPathComponent("results.txt")
    do {
        try RESULT_STR.write(to: fileURL, atomically: false, encoding: .utf8)
    }
    catch {/* error handling here */}
}

func runSimulation() {
    topology = .linear
    //topology = .tree
    packetSize = PacketSize(str: "50K")!
    _runNSwitches()
}
func _runNSwitches() {
    (41...49).forEach { (i: UInt) -> Void in
        nSwitches = i
        _runMonitoringProtocol()
    }
}
func _runMonitoringProtocol() {
    RESULT_STR += "\n********************************************************\n"
    RESULT_STR += "\nTopology: \(topology.rawValue)\n"
    RESULT_STR += "Networks monitoring period: \(NETWORKS_MONITORING_PERIOD.getMillisecond()) ms\n"
    RESULT_STR += "The number of switches: \(nSwitches)\n"
    RESULT_STR += "Link throughput: \(linkThroughput.getSizeAsMByte()) MBps\n"
    RESULT_STR += "Packet size: \(packetSize.getSizeAsKByte()) KB\n"

    ENABLE_PACKET_OUT = false
    ENABLE_LLDP = false
    ENABLE_PACKET_IN = false
    RESULT_STR += "\n------Without networks monitoring protocol------\n"
    _runSingleSimulation()

    ENABLE_PACKET_OUT = false
    ENABLE_LLDP = false
    ENABLE_PACKET_IN = true
    RESULT_STR += "\n------With simplified networks monitoring protocol------\n"
    _runSingleSimulation()

    ENABLE_PACKET_OUT = true
    ENABLE_LLDP = true
    ENABLE_PACKET_IN = true
    RESULT_STR += "\n------With networks monitoring protocol------\n"
    _runSingleSimulation()
}
func _runSingleSimulation() {
    print("A Simulation is working...")

    //_runSingle_All_Pairs()
    //_runSingle_End_to_End()
    //_runSingle_Randomize()
    _runSingle_Switches_to_Controller()

    RESULT_STR += "Average delay: \(RESULT_DELAY_ARR.reduce(0, { (i, delay) in i + delay }) / UInt(RESULT_DELAY_ARR.count)) μs "
    RESULT_STR += "Average jitter: \(RESULT_JITTER_ARR.reduce(0, { (i, jitter) in i + jitter }) / UInt(RESULT_JITTER_ARR.count)) μs\n"

    RESULT_DELAY_ARR = []
    RESULT_JITTER_ARR = []
    print("A Simulation is complete!!!")

    //save the progress
    /*
    if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
        let fileURL = dir.appendingPathComponent("tmp_result_\(simulationCount).txt")
        simulationCount += 1
        do {
            try RESULT_STR.write(to: fileURL, atomically: false, encoding: .utf8)
        }
        catch {/* error handling here */}
    }

     */
}

func _runSingle_End_to_End() {
    initNetworks()

    let srcID: NodeID = NodeID(nSwitches)
    let dstID: NodeID = NODE_ID_OF_CONTROLLER
    let dataPacket = Packet(type: .data,
            srcID: srcID, dstID: dstID,
            genTime: GLOBAL_TIME_OFFSET, arrivalTime: GLOBAL_TIME_OFFSET,
            size: packetSize, isLast: true)

    let simulator = Simulator(networks: networks)
    simulator.initSimulation(packet: dataPacket)
    simulator.run(timeStep: timeStep)
}
func _runSingle_Randomize() {
    (0..<10).forEach { _ in
        let i = UInt.random(in: 0...nSwitches)
        let j = UInt.random(in: 0...nSwitches)
        if i != j {
            initNetworks()

            let srcID: NodeID = NodeID(i)
            let dstID: NodeID = NodeID(j)
            let dataPacket = Packet(type: .data,
                    srcID: srcID, dstID: dstID,
                    genTime: GLOBAL_TIME_OFFSET, arrivalTime: GLOBAL_TIME_OFFSET,
                    size: packetSize, isLast: true)

            let simulator = Simulator(networks: networks)
            simulator.initSimulation(packet: dataPacket)
            simulator.run(timeStep: timeStep)
        }
    }
}
func _runSingle_All_Pairs() {
    for i in 0...nSwitches {
        for j in 0...nSwitches {
            if i == j { continue }
            initNetworks()

            let srcID: NodeID = NodeID(i)
            let dstID: NodeID = NodeID(j)
            let dataPacket = Packet(type: .data,
                    srcID: srcID, dstID: dstID,
                    genTime: GLOBAL_TIME_OFFSET, arrivalTime: GLOBAL_TIME_OFFSET,
                    size: packetSize, isLast: true)

            let simulator = Simulator(networks: networks)
            simulator.initSimulation(packet: dataPacket)
            simulator.run(timeStep: timeStep)
        }
    }
}
func _runSingle_Switches_to_Controller() {
    for i in 1...nSwitches {
        initNetworks()

        let srcID: NodeID = NodeID(i)
        let dstID: NodeID = NODE_ID_OF_CONTROLLER
        let dataPacket = Packet(type: .data,
                srcID: srcID, dstID: dstID,
                genTime: GLOBAL_TIME_OFFSET, arrivalTime: GLOBAL_TIME_OFFSET,
                size: packetSize, isLast: true)

        let simulator = Simulator(networks: networks)
        simulator.initSimulation(packet: dataPacket)
        simulator.run(timeStep: timeStep)
    }
}
func initNetworks() {
    GLOBAL_TIME_OFFSET = TimeOffset()
    networks = Networks(topology: topology, nSwitches: nSwitches)
    networks.setThroughput(to: linkThroughput)
}