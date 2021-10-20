//
//  StringNode.swift
//  StringsGenerator
//
//  Created by Richard Clements on 27/06/2019.
//

import Foundation

class StringNode: CustomStringConvertible {
    
    unowned var parentNode: StringNode?
    let identifier: String
    let buildForPackage: Bool
    var childNodes = [StringNode]()
    var strings = [StringName]()
    
    init(parentNode: StringNode?, identifier: String, buildForPackage: Bool) {
        self.parentNode = parentNode
        self.identifier = identifier
        self.buildForPackage = buildForPackage
    }
    
    func fullPath() -> String {
        return parentNode == nil ? identifier : "\(parentNode!.fullPath()).\(identifier)"
    }
    
    func node(withIdentifier identifier: String) -> StringNode? {
        return childNodes.first(where: { $0.identifier == identifier })
    }
    
    var description: String {
        var description = "\(identifier)\n"
        for string in strings {
            description += "    -\(string.description)\n"
        }
        for node in childNodes {
            let nodeDescription = node.description.replacingOccurrences(of: "\n", with: "\n    ")
            description += "    -\(nodeDescription)\n"
        }
        return description
    }
    
    func addString(_ string: StringName) {
        strings.append(string)
    }
    
    func structureContents(indentLevel: Int) throws -> String {
        var contents = ""
        
        let sortedStrings = strings.sorted { $0.identifier < $1.identifier }
        for string in sortedStrings {
            contents += string.functionName(indentLevel: indentLevel + 1, buildForPackage: buildForPackage)
            contents += "\n"
        }
        
        let preIndent = Array(repeating: "    ", count: indentLevel).joined()
        
        let sortedNodes = childNodes.sorted { $0.structName < $1.structName }
        for node in sortedNodes {
            contents += "\n\(preIndent)    public struct \(node.structName) {\n"
            contents += try node.structureContents(indentLevel: indentLevel + 1)
            contents += "\n\(preIndent)    }"
        }
        
        return contents
    }
    
    var structName: String {
        return "\(identifier.prefix(1).uppercased())\(identifier.suffix(from: identifier.index(after: identifier.startIndex)))"
    }
}
