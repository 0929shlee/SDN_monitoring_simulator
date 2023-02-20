//
// Created by Seunghyun Lee on 2022/04/27.
//

import Foundation

enum Topology: String {
    case linear = ".linear", tree = ".tree"
}

extension String {
    func toTopology() -> Topology? {
        switch self {
        case "linear": return .linear
        case "tree": return .tree
        default: return nil
        }
    }
}