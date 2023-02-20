//
// Created by Seunghyun Lee on 2022/04/27.
//

import Foundation

enum LinkStatus {
    case idle, occupied
}

class Link: Edge {
    private var _throughput: Throughput = Throughput(str: "100M")!
    private var _statusArr: [LinkStatus]
    private var _packetArr: [Packet?]
    private var _dstNodeArr: [Node?]

    var throughput: Throughput { _throughput }

    override init(n1: Node, n2: Node) {
        _statusArr = [.idle, .idle]
        _packetArr = [nil, nil]
        _dstNodeArr = [nil, nil]

        super.init(n1: n1, n2: n2)
    }

    func setThroughput(to throughput: Throughput) {
        _throughput = throughput
    }
    func getTransmissionDelay(packetSize: PacketSize) -> TimeOffset {
        return packetSize / throughput
    }
    func isIdle(node: Node) -> Bool {
        guard let srcIdx = getNodesIdx(node: node) else { return false }
        setStatus()

        return _statusArr[srcIdx] == .idle
    }

    func loadPacket(packet: Packet, from src: Node, to dst: Node) {
        guard let srcIdx = getNodesIdx(node: src) else { return }

        packet.arrivalTime += getTransmissionDelay(packetSize: packet.size)
        _packetArr[srcIdx] = packet
        _dstNodeArr[srcIdx] = dst
    }
    private func sendPackets() {
        for i in 0..<_packetArr.count {
            if let packet = _packetArr[i], let dst = _dstNodeArr[i], packet.arrivalTime <= GLOBAL_TIME_OFFSET {
                _packetArr[i] = nil
                _dstNodeArr[i] = nil
                dst.loadPacket(packet: packet)
            }
        }
    }
    func doTasks() {
        sendPackets()
    }

    private func setStatus() {
        for i in 0..<_statusArr.count {
            _statusArr[i] = (_packetArr[i] == nil) ? .idle : .occupied
        }
    }
    private func getNodesIdx(node: Node) -> Int? {
        guard let firstNode = nodes.first, nodes.last != nil else { return nil }
        return (firstNode == node) ? 0 : 1
    }

}