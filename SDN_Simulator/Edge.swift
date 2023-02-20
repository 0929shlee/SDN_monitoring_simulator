//
// Created by Seunghyun Lee on 2022/04/27.
//

import Foundation

class Edge {
    init(n1: Node, n2: Node) {
        _nodes = [n1, n2]
    }

    private let _nodes: [Node]
    var nodes: [Node] { _nodes }
}