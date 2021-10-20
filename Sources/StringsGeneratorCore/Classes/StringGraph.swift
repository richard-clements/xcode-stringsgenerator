//
//  StringGraph.swift
//  StringsGenerator
//
//  Created by Richard Clements on 27/06/2019.
//

import Foundation

class StringGraph: CustomStringConvertible {
    
    var nodes = [StringNode]()
    var strings = [StringName]()
    var buildForPackage: Bool = false
    
    func node(withIdentifier identifier: String) -> StringNode? {
        return nodes.first(where: { $0.identifier == identifier })
    }
    
    var description: String {
        var description = ""
        for string in strings {
            description += "\(string.description)\n"
        }
        
        for node in nodes {
            description += "\(node.description)\n"
        }
        
        return description
    }
    
    func fileContents() throws -> String {
        var contents = "public struct LocalizedString {\n"
        
        let sortedStrings = strings.sorted { $0.identifier < $1.identifier }
        for string in sortedStrings {
            contents += "\(string.functionName(indentLevel: 1, buildForPackage: buildForPackage))\n"
        }
        
        let sortedNodes = nodes.sorted { $0.structName < $1.structName }
        for node in sortedNodes {
            let nodeName = node.structName
            contents += "\n    public struct \(nodeName) {\n"
            contents += "\(try node.structureContents(indentLevel: 1))\n"
            contents += "    }\n"
        }
        contents += "}"
        return contents
    }
}
