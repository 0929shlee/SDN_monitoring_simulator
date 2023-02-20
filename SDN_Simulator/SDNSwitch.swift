//
// Created by Seunghyun Lee on 2022/04/27.
//

import Foundation

class SDNSwitch: Node {
    private let _delay: TimeOffset

    override init(id: NodeID) {
        _delay = TimeOffset()
        super.init(id: id)
    }

    func doTasks() {
        if ENABLE_PACKET_IN && !(ENABLE_PACKET_OUT && ENABLE_LLDP) {
            loadPacketInAnyway()
        }
        sendPackets()
    }
    private func loadPacketInAnyway() {
        guard ENABLE_PACKET_IN else { return }
        guard GLOBAL_TIME_OFFSET % NETWORKS_MONITORING_PERIOD == 0 else { return }

        loadPacket(packet: Packet(type: .packetIn,
                srcID: self.id, dstID: NODE_ID_OF_CONTROLLER,
                genTime: GLOBAL_TIME_OFFSET, arrivalTime: GLOBAL_TIME_OFFSET,
                size: SIZE_OF_LLDP, isLast: true))
    }

    public static func ==(lhs: SDNSwitch, rhs: SDNSwitch) -> Bool {
        return lhs.id == rhs.id
    }
}