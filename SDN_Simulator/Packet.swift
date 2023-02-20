//
// Created by Seunghyun Lee on 2022/04/27.
//

import Foundation

enum PacketType: String {
    case data = ".data", control = ".control"
    case packetIn = ".packetIn", lldp = ".lldp", packetOut = ".packetOut"
}

class Packet {
    var num: UInt
    private let _type: PacketType
    var type: PacketType { _type }
    let srcID: NodeID
    let dstID: NodeID
    let genTime: TimeOffset
    var arrivalTime: TimeOffset
    let size: PacketSize
    let isLast: Bool

    var description: String {
        return "num: \(num), " +
                "\(self._type.rawValue), " +
                "Node(\(srcID.num)) -> Node(\(dstID.num)), " +
                "genTime: \(genTime.offset), " +
                "arrivalTime: \(arrivalTime.offset), " +
                "size: \(self.size.getSizeAsByte()) Byte"
    }

    init(num: UInt = 0,
         type: PacketType,
         srcID: NodeID, dstID: NodeID,
         genTime: TimeOffset, arrivalTime: TimeOffset,
         size: PacketSize,
         isLast: Bool)
    {
        self.num = num
        _type = type
        self.srcID = srcID
        self.dstID = dstID
        self.genTime = genTime
        self.size = size
        self.arrivalTime = arrivalTime
        self.isLast = isLast
    }

    public static func ==(lhs: Packet, rhs: Packet) -> Bool {
        //TODO Logic error may occur
        return lhs.type == rhs.type &&
                lhs.srcID == rhs.srcID &&
                lhs.dstID == rhs.dstID &&
                lhs.genTime == rhs.genTime
    }
}