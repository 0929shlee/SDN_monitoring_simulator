//
// Created by Seunghyun Lee on 2022/04/27.
//

import Foundation

class Node {
    private let _id: NodeID
    private var _links: [Link]

    var id: NodeID { _id }
    var links: [Link] { _links }

    private var _queueOfDataPackets: [Packet]
    private var _queueOfControlPackets: [Packet]
    private var _queueOfDestinedPackets: [Packet]

    internal var _routingRule: (NodeID) -> (Node, Link)? = { (_: NodeID) -> (Node, Link)? in return nil }

    init(id: NodeID) {
        _id = id
        _links = []

        _queueOfDataPackets = []
        _queueOfControlPackets = []
        _queueOfDestinedPackets = []
    }


    func appendLink(link: Link) {
        _links.append(link)
    }

    func setRoutingRule(routingRule: @escaping (NodeID) -> (Node, Link)?) {
        _routingRule = routingRule
    }

    func loadPacket(packet: Packet) {
        if packet.type == .packetOut && !ENABLE_PACKET_OUT { return }
        if packet.type == .lldp && !ENABLE_LLDP { return }
        if packet.type == .packetIn && !ENABLE_PACKET_IN { return }

        if isDestinationHere(packet: packet) {
            self._queueOfDestinedPackets += [packet]
        }
        else {
            switch packet.type {
            case .data:
                _queueOfDataPackets += splitPacket(packet: packet)
            default:
                _queueOfControlPackets += splitPacket(packet: packet)
            }
        }
        /**/
        //printMsgLoadPacket(packet: packet)
        /**/

        if isDestinationHere(packet: packet) {
            flushPackets()
        }
    }

    internal func sendPackets() {
        guard let packet = choosePacket() else { return }
        guard let (nextNode, nextLink) = _routingRule(packet.dstID) else { return }

        if nextLink.isIdle(node: self) {
            packet.arrivalTime = GLOBAL_TIME_OFFSET
            /**/
            //printMsgSendPacket(packet: packet, nextNode: nextNode)
            /**/
            nextLink.loadPacket(packet: packet, from: self, to: nextNode)
            popPacket(packet: packet)
        }
    }
    private func splitPacket(packet: Packet) -> [Packet] {
        guard packet.isLast else { return [packet] }

        let nPackets = (packet.size / SIZE_OF_DATA_GRAM) < 1 ? 1 : (packet.size / SIZE_OF_DATA_GRAM)
        if nPackets == 1 { return [packet] }

        var res: [Packet] = []
        (0..<(nPackets - 1)).forEach { i in
            res.append(Packet(num: i,
                    type: packet.type,
                    srcID: packet.srcID, dstID: packet.dstID,
                    genTime: packet.genTime, arrivalTime: packet.arrivalTime,
                    size: SIZE_OF_DATA_GRAM,
                    isLast: false))
        }
        res.append(Packet(num: nPackets - 1,
                type: packet.type,
                srcID: packet.srcID, dstID: packet.dstID,
                genTime: packet.genTime, arrivalTime: packet.arrivalTime,
                size: SIZE_OF_DATA_GRAM,
                isLast: true))

        return res
    }
    private func mergePackets(packets: [Packet]) -> Packet {
        if packets.count == 1 { return packets.first! }

        let firstPacket = packets.first!
        let lastPacket = packets.last!
        var packetSize = PacketSize(str: "0K")!
        packets.forEach { packet in
            packetSize += packet.size
        }

        return Packet(num: packets.first!.num,
                type: lastPacket.type,
                srcID: lastPacket.srcID, dstID: lastPacket.dstID,
                genTime: firstPacket.genTime, arrivalTime: lastPacket.arrivalTime,
                size: packetSize,
                isLast: true)
    }
    private func flushPackets() {
        if let packet = self._queueOfDestinedPackets.last, packet.isLast {
            var firstPacketArrivalTime: TimeOffset = TimeOffset()
            var _tmpQueueOfDestinedPacket: [Packet] = []
            var _tmpQueueToFlush: [Packet] = []

            _queueOfDestinedPackets.forEach { _destinedPacket in
                if _destinedPacket == packet {
                    _tmpQueueToFlush.append(_destinedPacket)
                }
                else {
                    _tmpQueueOfDestinedPacket.append(_destinedPacket)
                }
            }
            firstPacketArrivalTime.copy(_tmpQueueToFlush.first!.arrivalTime)
            let mergedPacket = mergePackets(packets: _tmpQueueToFlush)
            if mergedPacket.type == .data {
                /*
                RESULT_STR += "Node(\(mergedPacket.srcID.num))->Node(\(mergedPacket.dstID.num)) "
                RESULT_STR += "Delay: \((mergedPacket.arrivalTime - mergedPacket.genTime).getMicrosecond()) μs "
                RESULT_STR += "Jitter: \((mergedPacket.arrivalTime - firstPacketArrivalTime).getMicrosecond()) μs\n"
                 */

                RESULT_DELAY_ARR.append((mergedPacket.arrivalTime - mergedPacket.genTime).getMicrosecond())
                RESULT_JITTER_ARR.append((mergedPacket.arrivalTime - firstPacketArrivalTime).getMicrosecond())

                IS_SIMULATION_FINISHED = true
            }

            self._queueOfDestinedPackets = _tmpQueueOfDestinedPacket
            _tmpQueueOfDestinedPacket = []
            _tmpQueueToFlush = []

            switch mergedPacket.type {
            case .packetOut:
                guard ENABLE_LLDP else { break }
                for neighbor in getNeighbors() {
                    self.loadPacket(packet: Packet(type: .lldp,
                            srcID: self.id, dstID: neighbor.id,
                            genTime: GLOBAL_TIME_OFFSET, arrivalTime: GLOBAL_TIME_OFFSET,
                            size: SIZE_OF_LLDP,
                            isLast: true))
                }
            case .lldp:
                guard ENABLE_PACKET_IN else { break }
                self.loadPacket(packet: Packet(type: .packetIn,
                        srcID: self.id, dstID: NODE_ID_OF_CONTROLLER,
                        genTime: GLOBAL_TIME_OFFSET, arrivalTime: GLOBAL_TIME_OFFSET,
                        size: SIZE_OF_PACKET_IN, isLast: true))
            default:
                //printMsgFlushPackets(mergedPacket: mergedPacket, firstPacketArrivalTime: firstPacketArrivalTime)
                break
            }
        }
    }
    private func choosePacket() -> Packet? {
        if let controlPacket = _queueOfControlPackets.first {
            return controlPacket
        }
        if let dataPacket = _queueOfDataPackets.first {
            return dataPacket
        }
        return nil
    }
    private func popPacket(packet: Packet) {
        //TODO O(n) time complexity each.
        switch packet.type {
        case .data:
            _queueOfDataPackets.removeFirst()
        default:
            _queueOfControlPackets.removeFirst()
        }
    }
    private func getNeighbors() -> [Node] {
        var res: [Node] = []
        for _link in self.links {
            for node in _link.nodes {
                if node != NODE_ID_OF_CONTROLLER && node != self {
                    res.append(node)
                }
            }
        }
        return res
    }
    private func isDestinationHere(packet: Packet) -> Bool {
        return packet.dstID == self._id
    }

    private func printMsgLoadPacket(packet: Packet) {
        print("Time \(GLOBAL_TIME_OFFSET.offset): packet(\(packet.description))")
        print("\t\t-> Node(\(self.id.num))")
    }
    private func printMsgSendPacket(packet: Packet, nextNode: Node) {
        print("Time \(GLOBAL_TIME_OFFSET.offset): packet(\(packet.description))")
        print("\t\tNode(\(self.id.num)) -> Node(\(nextNode.id.num))")
    }
    private func printMsgFlushPackets(mergedPacket: Packet, firstPacketArrivalTime: TimeOffset) {
        print("\n----------------------------------------------")
        print("Time \(GLOBAL_TIME_OFFSET.offset): packet(\(mergedPacket.description)) is arrived completely")
        print("Delay: \((mergedPacket.arrivalTime - mergedPacket.genTime).getMicrosecond()) microseconds")
        print("Jitter: \((mergedPacket.arrivalTime - firstPacketArrivalTime).getMicrosecond()) microseconds")
        print("----------------------------------------------\n")
    }

    public static func ==(lhs: Node, rhs: Node) -> Bool {
        return lhs._id == rhs._id
    }
    public static func !=(lhs: Node, rhs: Node) -> Bool {
        return lhs._id != rhs._id
    }
    public static func ==(lhs: Node, rhs: NodeID) -> Bool {
        return lhs._id == rhs
    }
    public static func !=(lhs: Node, rhs: NodeID) -> Bool {
        return lhs._id != rhs
    }
    public static func ==(lhs: NodeID, rhs: Node) -> Bool {
        return lhs == rhs._id
    }
    public static func !=(lhs: NodeID, rhs: Node) -> Bool {
        return lhs != rhs._id
    }
}