//
//  StringParser.swift
//  StringsGenerator
//
//  Created by Richard Clements on 27/06/2019.
//

import Foundation

class StringParser {
    
    let strings: String
    let buildForPackage: Bool
    
    init(strings: String, buildForPackage: Bool) {
        self.strings = strings
        self.buildForPackage = buildForPackage
    }
    
    /**
     Looks for format specifiers as referenced in https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Strings/Articles/formatSpecifiers.html
     Uses these to create arguments based on their specifier type.
     Then checks the identifier to create a graph for its' parents.
     */
    func parse() throws -> StringGraph {
        let argumentsRegEx = try! NSRegularExpression(pattern: "%(?:\\d+\\$)?[+-]?(?:[lh]{0,2})(?:[qLztj])?(?:[ 0]|'.{1})?\\d*(?:\\.\\d+)?[@dDiuUxXoOfeEgGcCsSpaAFn]", options: [])
        let split = strings.split(separator: "\n").compactMap { $0.contains(" = \"") ? $0 : nil }
        
        let graph = StringGraph()
        
        for item in split {
            guard let spaceIndex = item.firstIndex(of: " ") else {
                continue
            }
            guard let quoteIndex = item.firstIndex(of: "\"") else {
                continue
            }
            let string = String(item.suffix(from: quoteIndex))
            var argumentPositions = [(StringName.Argument, Range<String.Index>)]()
            
            let matches = argumentsRegEx.matches(in: string, options: [], range: NSMakeRange(0, string.count))
            
            for match in matches {
                let range = string.index(string.startIndex, offsetBy: match.range.lowerBound) ..< string.index(string.startIndex, offsetBy: match.range.upperBound)
                if let lastCharacter = string[range].last,
                    let argument = StringName.Argument(rawValue: String(lastCharacter)) {
                    argumentPositions.append((argument, range))
                }
            }
            
            argumentPositions.sort { $0.1.lowerBound < $1.1.lowerBound }
            
            let argumentMap = argumentPositions.map { $0.0 }
            
            let identifier = String(item.prefix(upTo: spaceIndex))
            let itemSplit = identifier.split(separator: ".").map { String($0) }
            
            if itemSplit.count == 0 {
                continue
            } else if itemSplit.count == 1 {
                let name = try StringName(parentNode: nil, identifier: identifier, arguments: argumentMap)
                graph.strings.append(name)
            } else {
                var parentNode: StringNode! = graph.node(withIdentifier: itemSplit[0])
                if parentNode == nil {
                    parentNode = StringNode(parentNode: nil, identifier: itemSplit[0], buildForPackage: buildForPackage)
                    graph.nodes.append(parentNode)
                }
                
                var currentNode: StringNode! = parentNode
                
                for i in 1 ..< itemSplit.count - 1 {
                    let subIdentifier = itemSplit[i]
                    let currentParentNode: StringNode! = currentNode
                    currentNode = currentParentNode.node(withIdentifier: subIdentifier)
                    if currentNode == nil {
                        currentNode = StringNode(parentNode: currentParentNode, identifier: subIdentifier, buildForPackage: buildForPackage)
                        currentParentNode.childNodes.append(currentNode)
                    }
                }
                
                let stringIdentifier = itemSplit.last!
                let stringItem = try StringName(parentNode: currentNode, identifier: stringIdentifier, arguments: argumentMap)
                currentNode.addString(stringItem)
            }
        }
        
        graph.buildForPackage = buildForPackage
        
        return graph
    }
    
}
