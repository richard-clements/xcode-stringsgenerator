//
//  StringName.swift
//  StringsGenerator
//
//  Created by Richard Clements on 27/06/2019.
//

import Foundation

public enum StringNameError: LocalizedError {
    case invalidArgumentsCount(value: String, expectedArguments: Int, foundArguments: Int)
    
    public var errorDescription: String? {
        switch self {
        case .invalidArgumentsCount(value: let identifier, expectedArguments: let ea, foundArguments: let fa):
            return "String for \"\(identifier)\" does not contain the correct number of arguments. Expected \(ea), found \(fa)"
        }
    }
}

class StringName: CustomStringConvertible {
    
    struct NamedArgument {
        private let publicName: String?
        private let privateName: String
        
        init(publicName: String?, privateName: String) {
            self.publicName = publicName
            self.privateName = privateName
        }
        
        var methodArguments: String {
            if let publicName = publicName, !publicName.isEmpty {
                return "\(publicName) \(privateName)"
            } else {
                return "_ \(privateName)"
            }
        }
        
        var stringArgument: String {
            return privateName
        }
    }
    
    enum Argument: String, CaseIterable, CustomStringConvertible {
        case string = "@"
        case character = "%"
        case int32Lower = "d"
        case int32Upper = "D"
        case unsignedInt32Lower = "u"
        case unsignedInt32Upper = "U"
        case unsignedInt32HexLower = "x"
        case unsignedInt32HexUpper = "X"
        case unsignedInt32OctalLower = "o"
        case unsignedInt32OctalUpper = "O"
        case doubleLower = "f"
        case doubleUpper = "F"
        case expLower = "e"
        case expUpper = "E"
        case expFourthsLower = "g"
        case expFourthsUpper = "G"
        case unsignedCharacterLower = "c"
        case unsignedCharacterUpper = "C"
        case nullTerminatedArrayLower = "s"
        case nullTerminatedArrayUpper = "S"
        case pointer = "p"
        case scientificDoubleLower = "a"
        case scientificDoubleUpper = "A"
        
        var description: String {
            switch self {
            case .string:
                return "String"
            case .character:
                return "CChar"
            case .int32Lower, .int32Upper:
                return "Int"
            case .unsignedInt32Lower, .unsignedInt32Upper, .unsignedInt32HexLower, .unsignedInt32HexUpper, .unsignedInt32OctalLower, .unsignedInt32OctalUpper:
                return "UInt32"
            case .doubleLower, .doubleUpper, .expLower, .expUpper, .expFourthsLower, .expFourthsUpper, .scientificDoubleLower, .scientificDoubleUpper:
                return "Double"
            case .unsignedCharacterLower, .unsignedCharacterUpper:
                return "CUnsignedChar"
            case .nullTerminatedArrayLower, .nullTerminatedArrayUpper:
                return "Sequence"
            case .pointer:
                return "AnyObject"
            }
        }
    }
    
    let parentNode: StringNode?
    let identifier: String
    let methodName: String
    let argumentNames: [NamedArgument]
    let arguments: [Argument]
    
    init(parentNode: StringNode?, identifier: String, arguments: [Argument]) throws {
        self.parentNode = parentNode
        self.arguments = arguments
        self.identifier = identifier.replacingOccurrences(of: "_*", with: "")
        
        var splitIdentifier = identifier.split(separator: "_").map { String($0) }
        self.methodName = escape(name: splitIdentifier.first ?? "")
        
        splitIdentifier = Array(splitIdentifier.dropFirst())
        
        var argumentNames = [NamedArgument]()
        
        for (i, split) in splitIdentifier.enumerated() {
            if split == ":" || split == "*" || split.isEmpty {
                argumentNames.append(NamedArgument(publicName: "", privateName: "arg\(i)"))
            } else {
                argumentNames.append(NamedArgument(publicName: split, privateName: "arg\(i)"))
            }
        }
        
        self.argumentNames = argumentNames
        
        guard arguments.count == argumentNames.count else {
            throw StringNameError.invalidArgumentsCount(value: fullPath(), expectedArguments: arguments.count, foundArguments: argumentNames.count)
        }
    }
    
    func fullPath() -> String {
        return parentNode == nil ? identifier : "\(parentNode!.fullPath()).\(identifier)"
    }
    
    func functionName(indentLevel: Int) -> String {
        let preIndent = Array(repeating: "    ", count: indentLevel).joined()
        
        let keySplit = identifier.split(separator: "_")
        guard keySplit.count > 0 else {
            return ""
        }
        
        switch arguments.count {
        case 0:
            return "\(preIndent)public static let \(methodName) = NSLocalizedString(\"\(fullPath())\", comment: \"\")"
        default:
            let functionArgumentNames: [NamedArgument] = (0 ..< arguments.count).map {
                if $0 < argumentNames.count {
                    return argumentNames[$0]
                }
                
                return NamedArgument(publicName: nil, privateName: "arg\($0)")
            }
            
            let functionArguments = functionArgumentNames.enumerated().map {
                return "\($0.element.methodArguments): \(arguments[$0.offset])"
                }.joined(separator: ", ")
            let stringArguments = functionArgumentNames.map { $0.stringArgument }.joined(separator: ", ")
            return "\(preIndent)public static func \(methodName)(\(functionArguments)) -> String {\n\(preIndent)    return String(format: NSLocalizedString(\"\(fullPath())\", comment: \"\"), \(stringArguments))\n\(preIndent)}"
        }
    }
    
    var description: String {
        return "\(identifier), args: \(arguments)"
    }
}
