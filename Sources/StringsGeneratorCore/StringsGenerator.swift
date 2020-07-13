//
//  StringsGenerator.swift
//  StringsGeneratorCore
//
//  Created by Richard Clements on 27/06/2019.
//

import Foundation

public final class StringsGenerator {
    private let arguments: [String]
    var message: String?
    
    public init(arguments: [String] = CommandLine.arguments) {
        self.arguments = arguments
    }
    
    /**
     To be called after initialisation.
     */
    public func run() throws {
        var stringsFilePath: String?
        var dictFilePath: String?
        var outputFilePath: String?
        
        var previousArgument: String?
        
        for argument in arguments {
            if argument.hasSuffix(".strings") {
                stringsFilePath = argument
            } else if argument.hasSuffix(".stringsdict") {
                dictFilePath = argument
            } else if previousArgument == "-o" {
                outputFilePath = argument
            } else if previousArgument == "-m" {
                message = argument
            }
            previousArgument = argument
        }
        
        guard let ofp = outputFilePath else {
            throw NSError(domain: "No output file declared", code: -999, userInfo: nil)
        }
        
        guard stringsFilePath != nil || dictFilePath != nil else {
            return
        }
        
        try generateFile(stringsFilePath: stringsFilePath, dictFilePath: dictFilePath, outputFilePath: ofp, showDebug: arguments.contains("--debug"))
    }
    
    /**
     Looks for name of variable in the specified key represented as: %#@VARIABLE@
     
     - parameters:
         - value: The key specified as the variable name
     - returns:
         The name of the variable used in the string. Input of %#@VARIABLE@ will return VARIABLE
     */
    func stringVariables(forValue value: String) -> [String] {
        let regex = try! NSRegularExpression(pattern: "\\%\\#\\@[^%#@]+\\@", options: [])
        
        let matches = regex.matches(in: value, options: [], range: NSMakeRange(0, value.count))
        return matches.map { match in
            let range = value.index(value.startIndex, offsetBy: match.range.lowerBound) ..< value.index(value.startIndex, offsetBy: match.range.upperBound)
            return value[range].replacingOccurrences(of: "%#@", with: "").replacingOccurrences(of: "@", with: "")
        }
    }
    
    func generateFile(stringsFilePath: String?, dictFilePath: String?, outputFilePath: String, showDebug: Bool) throws {
        var stringsPlist: [String: String] = [:]
        var plist: [String: Any] = [:]

        if let stringsFilePath = stringsFilePath {
            let fileUrl = URL(fileURLWithPath: stringsFilePath)
            let localizedStrings = (try? String(contentsOf: fileUrl)) ?? ""
            stringsPlist = localizedStrings.propertyListFromStringsFileFormat()
        }
        
        if let dictFilePath = dictFilePath {
            let fileUrl = URL(fileURLWithPath: dictFilePath)
            plist = NSDictionary(contentsOf: fileUrl) as? [String: Any] ?? [:]
        }
        
        var string = ""
        
        // Adds strings from the .strings file
        for (key, value) in stringsPlist {
            string += "\(key) = \"\(value.filter { !$0.isNewline })\";\n"
        }
        
        // Adds strings from the .stringdict file
        for (key, value) in plist {
            guard let value = value as? [String: Any],
                let formatKey = value["NSStringLocalizedFormatKey"] as? String else {
                    continue
            }
            let variableNames = stringVariables(forValue: formatKey)
            var formattedKey = formatKey
            for variable in variableNames {
                let variableDictionary = value[variable] as? [String: Any]
                guard let typeKey = variableDictionary?["NSStringFormatValueTypeKey"] as? String else {
                    continue
                }
                formattedKey = formattedKey.replacingOccurrences(of: "%#@\(variable)@", with: "%\(typeKey)")
            }
            
            let addedValue = "\(key) = \"\(formattedKey)\""
            string += "\(addedValue)\n"
        }
        
        while string.hasSuffix("\n") {
            string.removeLast()
        }
        
        let graph = try StringParser(strings: string).parse()
        let fileContents = try graph.fileContents()
        
        let message = self.message == nil ? "" : "\n\n\(self.message!)"
        
        let fullString = """
        /**
        AUTO GENERATED STRINGS FILE\(message)
        */
        import Foundation
        
        \(fileContents)
        """
        
        let data = fullString.data(using: .utf8)
        let outputUrl = URL(fileURLWithPath: outputFilePath)
        
        try data?.write(to: outputUrl)
        
        if showDebug {
            print(graph)
        }
    }
}
