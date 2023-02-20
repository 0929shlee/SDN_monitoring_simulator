//
// Created by Seunghyun Lee on 2022/04/27.
//

import Foundation

struct TimeOffset {
    private var _offset: UInt
    var offset: UInt { _offset }

    private init(_ offset: UInt) {
        _offset = offset
    }
    init(second offset: UInt) {
        self.init(offset * 10 * 1000 * 1000)
    }
    init(millisecond offset: UInt) {
        self.init(offset * 10 * 1000)
    }
    init(microsecond offset: UInt) {
        self.init(offset * 10)
    }
    init(nanosecond offset: UInt) {
        self.init(offset / 100)
    }
    init() {
        self.init(second: 0)
    }

    mutating func copy(_ rhs: TimeOffset) {
        self._offset = rhs._offset
    }
    func getSecond() -> UInt {
        return offset / (10 * 1000 * 1000)
    }
    func getMillisecond() -> UInt {
        return offset / (10 * 1000)
    }
    func getMicrosecond() -> UInt {
        return offset / (10)
    }
    func getNanosecond() -> UInt {
        return offset * 100
    }

    mutating func increase() {
        _offset += 1
    }
    mutating func increaseMicrosecond() {
        _offset += (1 * 10)
    }
    mutating func increaseMillisecond() {
        _offset += (1 * 10 * 1000)
    }
    mutating func increaseSecond() {
        _offset += (1 * 10 * 1000 * 1000)
    }
    mutating func increase(timeStep: TimeOffset) {
        _offset += timeStep.offset
    }

    public static func +(lhs: TimeOffset, rhs: TimeOffset) -> TimeOffset {
        return TimeOffset(lhs.offset + rhs.offset)
    }
    public static func +=(lhs: inout TimeOffset, rhs: TimeOffset) {
        lhs._offset += rhs.offset
    }
    public static func ==(lhs: TimeOffset, rhs: TimeOffset) -> Bool {
        return lhs.offset == rhs.offset
    }
    public static func <(lhs: TimeOffset, rhs: TimeOffset) -> Bool {
        return lhs.offset < rhs.offset
    }
    public static func <=(lhs: TimeOffset, rhs: TimeOffset) -> Bool {
        return lhs.offset < rhs.offset || lhs.offset == rhs.offset
    }
    public static func >(lhs: TimeOffset, rhs: TimeOffset) -> Bool {
        return lhs.offset > rhs.offset
    }
    public static func >=(lhs: TimeOffset, rhs: TimeOffset) -> Bool {
        return lhs.offset > rhs.offset || lhs.offset == rhs.offset
    }
    public static func -(lhs: TimeOffset, rhs: TimeOffset) -> TimeOffset {
        return lhs.offset > rhs.offset ? TimeOffset(lhs.offset - rhs.offset) : TimeOffset(0)
    }
    public static func %(lhs: TimeOffset, rhs: TimeOffset) -> UInt {
        return lhs.offset % rhs.offset
    }
    public static func /(lhs: TimeOffset, rhs: TimeOffset) -> UInt {
        return lhs.offset / rhs.offset
    }
}