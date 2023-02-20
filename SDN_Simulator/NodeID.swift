//
// Created by Seunghyun Lee on 2022/04/28.
//

import Foundation

struct NodeID {
    private let _id: UInt

    //use this property wisely
    var num: UInt { _id }

    init(_ id: UInt) {
        _id = id
    }

    public static func ==(lhs: NodeID, rhs: NodeID) -> Bool {
        return lhs._id == rhs._id
    }
    public static func !=(lhs: NodeID, rhs: NodeID) -> Bool {
        return lhs._id != rhs._id
    }
    public static func <(lhs: NodeID, rhs: NodeID) -> Bool {
        return lhs._id < rhs._id
    }
    public static func <=(lhs: NodeID, rhs: NodeID) -> Bool {
        return lhs._id < rhs._id || lhs._id == rhs._id
    }
    public static func +(lhs: NodeID, rhs: UInt) -> NodeID {
        return NodeID(lhs._id + rhs)
    }
    public static func -(lhs: NodeID, rhs: UInt) -> NodeID {
        if lhs._id >= rhs {
            return NodeID(lhs._id - rhs)
        }
        else {
            return NodeID(0)
        }
    }
}
