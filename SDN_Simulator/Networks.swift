//
// Created by Seunghyun Lee on 2022/04/27.
//

import Foundation

class Networks {
    private let _topology: Topology
    private let _controller: SDNController
    private var _switches: [SDNSwitch]
    private var _links: [Link]
    private var _nSwitches: UInt { UInt(_switches.count) }

    init(topology: Topology, nSwitches: UInt) {
        _topology = topology
        _controller = SDNController()
        _switches = []
        _links = []

        var predecessorRule: (UInt) -> UInt = { i -> UInt in i }
        switch _topology {
        case .linear:
            predecessorRule = { i -> UInt in
                if i == 0 { return 0 }
                return i - 1
            }
        case .tree:
            predecessorRule = { i -> UInt in
                if i == 0 { return 0 }
                return i / 2
            }
        }
        setTopology(nSwitches: nSwitches, predecessorRule: predecessorRule)

        setRoutingRules()
    }

    func nextTimeOffset(timeStep: TimeOffset) {
        _links.forEach { (_link: Link) -> Void in _link.doTasks() }
        _controller.doTasks()
        _switches.forEach { (_switch: SDNSwitch) -> Void in _switch.doTasks() }
        GLOBAL_TIME_OFFSET.increase(timeStep: timeStep)
    }

    private func setTopology(nSwitches: UInt, predecessorRule: (UInt) -> UInt) {
        (1...nSwitches).forEach { i in
            if let node = getNode(id: NodeID(predecessorRule(i))) {
                addSwitch(to: node)
            }
        }
    }

    func setThroughput(to throughput: Throughput) {
        _links.forEach { link in
            link.setThroughput(to: throughput)
        }
    }

    private func addSwitch(to src: Node) {
        let newS = SDNSwitch(id: NodeID(_nSwitches + 1))
        _switches.append(newS)

        let newL = Link(n1: src, n2: newS)
        src.appendLink(link: newL)
        newS.appendLink(link: newL)
        _links.append(newL)
    }

    private func setRoutingRules() {
        _controller.setRoutingRule(routingRule: genRoutingRule(src: _controller))
        _switches.forEach { _switch in
            _switch.setRoutingRule(routingRule: genRoutingRule(src: _switch))
        }
    }
    private func genRoutingRule(src: Node) -> (NodeID) -> (Node, Link)? {
        switch _topology {
        case .linear: return { (dstID: NodeID) -> (Node, Link)? in
            guard let dst = self.getNode(id: dstID) else { return nil }
            if src == dst { return nil }

            if src.id < dst.id {
                guard let nextNode = self.getNode(id: src.id + 1) else { return nil }
                guard let link = self.getLink(src: src, dst: nextNode) else { return nil }
                return (nextNode, link)
            }
            else if dst.id < src.id {
                guard let nextNode = self.getNode(id: src.id - 1) else { return nil }
                guard let link = self.getLink(src: src, dst: nextNode) else { return nil }
                return (nextNode, link)
            }

            return nil
        }
        case .tree: return { (dstID: NodeID) -> (Node, Link)? in
            guard let dst = self.getNode(id: dstID) else { return nil }
            if src == dst { return nil }

            if src.id == NODE_ID_OF_CONTROLLER {
                guard let nextNode = self._switches.first else { return nil }
                guard let link = self.getLink(src: src, dst: nextNode) else { return nil }
                return (nextNode, link)
            }
            else if src.id < dst.id {
                let lvl = UInt(log2l(Double(dst.id.num / src.id.num)))
                guard let ancestor = self.getNode(id: NodeID(dst.id.num >> lvl)) else { return nil }
                let nextNodeID = src.id == ancestor.id ? NodeID(dst.id.num >> (lvl-1)) : NodeID(src.id.num / 2)

                guard let nextNode = self.getNode(id: nextNodeID) else { return nil }
                guard let link = self.getLink(src: src, dst: nextNode) else { return nil }
                return (nextNode, link)
            }
            else if dst.id < src.id {
                let nextNodeID = NodeID(src.id.num / 2)

                guard let nextNode = self.getNode(id: nextNodeID) else { return nil }
                guard let link = self.getLink(src: src, dst: nextNode) else { return nil }
                return (nextNode, link)
            }

            return nil
        }
        }
    }
    func getNode(id: NodeID) -> Node? {
        if id == NODE_ID_OF_CONTROLLER {
            return _controller
        }
        if let lastSwitch = _switches.last, id <= lastSwitch.id {
            //TODO hide id.num property !!!!
            //Warning!!
            return _switches[Int(id.num) - 1]
        }
        return nil
    }
    private func getLink(src: Node, dst: Node) -> Link? {
        for e in src.links {
            for n in e.nodes {
                if n.id == dst.id {
                    return e
                }
            }
        }
        return nil
    }
    private func getLink(srcID: NodeID, dstID: NodeID) -> Link? {
        guard let src = getNode(id: srcID) else { return nil }
        guard let dst = getNode(id: dstID) else { return nil }
        return getLink(src: src, dst: dst)
    }
}