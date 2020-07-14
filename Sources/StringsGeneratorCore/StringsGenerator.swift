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
    
    private func inputFiles() -> [String] {
        let fileCount = Int(ProcessInfo.processInfo.environment["SCRIPT_INPUT_FILE_COUNT"] ?? "0") ?? 0
        guard fileCount > 0 else {
            return []
        }
        return (0 ..< fileCount).compactMap {
            ProcessInfo.processInfo.environment["SCRIPT_INPUT_FILE_\($0)"]
        }
    }
    
    private func outputFiles() -> [String] {
        let fileCount = Int(ProcessInfo.processInfo.environment["SCRIPT_OUTPUT_FILE_COUNT"] ?? "0") ?? 0
        guard fileCount > 0 else {
            return []
        }
        return (0 ..< fileCount).compactMap {
            ProcessInfo.processInfo.environment["SCRIPT_OUTPUT_FILE_\($0)"]
        }
    }
    
    private func fetchArgument(_ argument: String, from arguments: [String]) -> String? {
        var previousArgument: String?
        for argumentValue in arguments {
            if previousArgument == "-\(argument)" {
                return argumentValue
            }
            previousArgument = argumentValue
        }
        return nil
    }
    
    /**
     To be called after initialisation.
     */
    public func run() throws {
        let inputFiles = self.inputFiles()
        let outputFiles = self.outputFiles()
        
        let stringsFilePath = inputFiles.first { $0.hasSuffix(".strings") }
        let dictFilePath = inputFiles.first { $0.hasSuffix(".stringsdict") }
        
        guard let outputFilePath = outputFiles.first(where: { $0.hasSuffix(".swift") }) else {
            throw NSError(domain: "No output file declared", code: -999, userInfo: nil)
        }
        
        try generateFile(stringsFilePath: stringsFilePath, dictFilePath: dictFilePath, outputFilePath: outputFilePath, message: fetchArgument("m", from: arguments), showDebug: arguments.contains("--debug"))
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
    
    func generateFile(stringsFilePath: String?, dictFilePath: String?, outputFilePath: String, message: String?, showDebug: Bool) throws {
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
        
        let fullString = """
        /**
        AUTO GENERATED STRINGS FILE\(message.map { "\n\n\($0)" } ?? "")
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
