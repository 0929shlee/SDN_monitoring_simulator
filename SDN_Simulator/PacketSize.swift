//
// Created by Seunghyun Lee on 2022/04/28.
//

import Foundation

class PacketSize {
    private var _size: UInt
    internal var size: UInt { _size }

    private init(_ size: UInt) {
        _size = size
    }
    init(_ packetSize: PacketSize) {
        _size = packetSize.size
    }
    init?(str: String) {
        guard str.count > 1 else {
            print("Error: struct PacketSize: init?(\(str)): invalid format error")
            return nil
        }

        let numPart = String(str[str.startIndex..<str.index(before: str.endIndex)])
        let unitPart = String(str.last!)
        guard let num = UInt(numPart) else {
            print("Error: struct PacketSize: init?(\(str)): invalid format error")
            return nil
        }

        let mul: UInt? = {
            switch unitPart {
            case "b": return 1
            case "B": return 8
            case "k": return 1024
            case "K": return 1024 * 8
            case "m": return 1024 * 1024
            case "M": return 1024 * 1024 * 8
            case "g": return 1024 * 1024 * 1024
            case "G": return 1024 * 1024 * 1024 * 8
            default: return nil
            }
        }()

        if let m = mul {
            _size = num * m
        }
        else {
            print("Error: struct PacketSize: init?(\(str)): invalid format error")
            return nil
        }
    }

    func getSizeAsBit() -> UInt {
        return self._size
    }
    func getSizeAsByte() -> UInt {
        return getSizeAsBit() / 8
    }
    func getSizeAsKBit() -> UInt {
        return getSizeAsBit() / 1024
    }
    func getSizeAsKByte() -> UInt {
        return getSizeAsBit() / (8 * 1024)
    }
    func getSizeAsMBit() -> UInt {
        return getSizeAsBit() / (1024 * 1024)
    }
    func getSizeAsMByte() -> UInt {
        return getSizeAsBit() / (8 * 1024 * 1024)
    }
    func getSizeAsGBit() -> UInt {
        return getSizeAsBit() / (1024 * 1024 * 1024)
    }
    func getSizeAsGByte() -> UInt {
        return getSizeAsBit() / (8 * 1024 * 1024 * 1024)
    }

    public static func /(lhs: PacketSize, rhs: PacketSize) -> UInt {
        return lhs._size / rhs._size
    }
    public static func /(lhs: PacketSize, rhs: Throughput) -> TimeOffset {
        return TimeOffset(nanosecond: lhs.size * 1000 * 1000 * 1000 / rhs.size)
    }
    public static func +(lhs: PacketSize, rhs: PacketSize) -> PacketSize {
        return PacketSize(lhs._size + rhs._size)
    }
    public static func +=(lhs: inout PacketSize, rhs: PacketSize) {
        lhs._size += rhs._size
    }
    public static func %(lhs: PacketSize, rhs: PacketSize) -> UInt {
        return lhs._size % rhs._size
    }
}