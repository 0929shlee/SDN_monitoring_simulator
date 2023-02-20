//
// Created by Seunghyun Lee on 2022/04/27.
//

import Foundation

class SDNController: Node {
    init() {
        super.init(id: NODE_ID_OF_CONTROLLER)
    }

    func doTasks() {
        if ENABLE_PACKET_OUT {
            runNetworksMonitoringProtocol()
        }
        sendPackets()
    }
    private func runNetworksMonitoringProtocol() {
        guard ENABLE_PACKET_OUT else { return }
        guard GLOBAL_TIME_OFFSET % NETWORKS_MONITORING_PERIOD == 0 else { return }

        /*
        print("\n*************************************************************")
        print("@@@@@@@@@@@@@ Network Monitoring Protocol No.\(1 + (GLOBAL_TIME_OFFSET / NETWORKS_MONITORING_PERIOD)) @@@@@@@@@@@@@")
        print("*************************************************************\n")
         */

        for i in 1...UInt.max {
            guard let _ = self._routingRule(NodeID(i)) else { break }
            let packet = Packet(type: .packetOut,
                    srcID: self.id, dstID: NodeID(i),
                    genTime: GLOBAL_TIME_OFFSET, arrivalTime: GLOBAL_TIME_OFFSET,
                    size: SIZE_OF_PACKET_OUT,
                    isLast: true)
            self.loadPacket(packet: packet)
        }
    }
}