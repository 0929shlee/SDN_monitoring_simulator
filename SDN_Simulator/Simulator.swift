//
// Created by Seunghyun Lee on 2022/04/27.
//

import Foundation

class Simulator {
    private var _networks: Networks

    init(networks: Networks) {
        _networks = networks
    }

    func initSimulation(packet: Packet) {
        //load packet in src node
        guard let srcNode = _networks.getNode(id: packet.srcID) else {
            //there are no such node
            print("Error: class Simulator: func sendPacket: load packet error")
            return
        }
        srcNode.loadPacket(packet: packet)
    }

    func run(timeStep: TimeOffset) {
        IS_SIMULATION_FINISHED = false

        while !IS_SIMULATION_FINISHED {
            self._networks.nextTimeOffset(timeStep: timeStep)
        }
    }
}