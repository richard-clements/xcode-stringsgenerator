//
//  Escaping.swift
//  StringsGenerator
//
//  Created by Richard Clements on 27/06/2019.
//

import Foundation

/**
 Escapes strings that are the same as the listed keywords in Swift
 */
func escape(name: String) -> String {
    switch name {
    case "associatatedtype", "class", "deinit", "enum", "extension", "fileprivate", "func", "import", "init", "inout", "internal", "let", "open", "operator", "private", "protocol", "public", "static", "struct", "subscript", "typealias", "var", "break", "case", "continue", "default", "defer", "do", "else", "fallthrough", "for", "guard", "if", "in", "repeat", "return", "switch", "where", "while", "as", "Any", "catch", "false", "is", "nil", "rethrows", "super", "self", "Self", "throw", "throws", "true", "try", "#available", "#colorLiteral", "#column", "#else", "#elseif", "#endif", "#error", "#file", "#fileLiteral", "#function", "#if", "#imageLiteral", "#line", "#selector", "#soureLocation", "#warning", "associativity", "convenience", "dynamic", "didSet", "final", "get", "infix", "indirect", "lazy", "left", "mutating", "none", "nonmutating", "optional", "override", "postfix", "precedence", "prefix", "Protocol", "required", "right", "set", "Type", "unowned", "weak", "willSet":
        return "`\(name)`"
    default:
        return name
    }
}
