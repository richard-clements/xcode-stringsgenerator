import XCTest
import class Foundation.Bundle

final class StringsGeneratorTests: XCTestCase {
    
    var localizedStringFilePath: String!
    var localizedDictFilePath: String!
    var swiftFilePath: String!
    
    override func tearDown() {
        if let localizedStringFilePath = localizedStringFilePath {
            try? FileManager.default.removeItem(atPath: localizedStringFilePath)
        }
        if let localizedDictFilePath = localizedDictFilePath {
            try? FileManager.default.removeItem(atPath: localizedDictFilePath)
        }
        if let swiftFilePath = swiftFilePath {
            try? FileManager.default.removeItem(atPath: swiftFilePath)
        }
        localizedStringFilePath = nil
        localizedDictFilePath = nil
        swiftFilePath = nil
    }
    
    func testGenerateStrings() {
        guard #available(macOS 10.13, *) else {
            return
        }
        
        setUpCorrect()
        
        let fooBinary = productsDirectory.appendingPathComponent("strings-generator")
        
        let process = Process()
        process.executableURL = fooBinary
        process.arguments = [
            localizedStringFilePath,
            localizedDictFilePath,
            "-o",
            swiftFilePath,
            "-m",
            "Test Message"
        ]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        try! process.run()
        process.waitUntilExit()
        
        let fileString = try! String(contentsOfFile: swiftFilePath)
        
        
        let expectedFile = """
        /**
        AUTO GENERATED STRINGS FILE

        Test Message
        */
        import Foundation
        
        struct LocalizedString {
            static func multilineArgumentText(_ arg0: String, _ arg1: String) -> String {
                return String(format: NSLocalizedString("multilineArgumentText_:_:", comment: ""), arg0, arg1)
            }
            static func multivariable(string arg0: String, int1 arg1: Int, int2 arg2: Int) -> String {
                return String(format: NSLocalizedString("multivariable_string_int1_int2", comment: ""), arg0, arg1, arg2)
            }
            static let staticText = NSLocalizedString("staticText", comment: "")

            struct Section1 {

                struct Subsection1 {
                    static let staticText = NSLocalizedString("section1.subsection1.staticText", comment: "")

                }
                struct Subsection2 {
                    static func dynamicText(_ arg0: String, param2 arg1: Int) -> String {
                        return String(format: NSLocalizedString("section1.subsection2.dynamicText_:_param2", comment: ""), arg0, arg1)
                    }

                }
            }

            struct Section2 {

                struct Subsection1 {
                    static func floatText(floatName arg0: Double) -> String {
                        return String(format: NSLocalizedString("section2.subsection1.floatText_floatName", comment: ""), arg0)
                    }

                }
            }

            struct Time {
                static func days(_ arg0: Int) -> String {
                    return String(format: NSLocalizedString("time.days_:", comment: ""), arg0)
                }
                static func hours(_ arg0: Int) -> String {
                    return String(format: NSLocalizedString("time.hours_:", comment: ""), arg0)
                }
                static func minutes(_ arg0: Int) -> String {
                    return String(format: NSLocalizedString("time.minutes_:", comment: ""), arg0)
                }

            }
        }
        """
        
        XCTAssertEqual(fileString, expectedFile)
    }
    
    func testGenerateStringsFailsForTooManyArgumentsCount() {
        guard #available(macOS 10.13, *) else {
            return
        }
        
        setUpFailTooManyArguments()
        
        let fooBinary = productsDirectory.appendingPathComponent("strings-generator")
        
        let process = Process()
        process.executableURL = fooBinary
        process.arguments = [
            localizedStringFilePath,
            localizedDictFilePath,
            "-o",
            swiftFilePath,
            "-m",
            "Test Message"
        ]
        
        let pipe = Pipe()
        process.standardError = pipe
        
        try! process.run()
        process.waitUntilExit()
        
        XCTAssertNotNil(process.standardError)
        let handle = pipe.fileHandleForReading
        let errorString = String(data: handle.availableData, encoding: .utf8)
        XCTAssertNotNil(errorString)
        XCTAssert(errorString!.count > 0)
    }
    
    func testGenerateStringsFailsForTooFewArgumentsCount() {
        guard #available(macOS 10.13, *) else {
            return
        }
        
        setUpFailNotEnoughArguments()
        
        let fooBinary = productsDirectory.appendingPathComponent("strings-generator")
        
        let process = Process()
        process.executableURL = fooBinary
        process.arguments = [
            localizedStringFilePath,
            localizedDictFilePath,
            "-o",
            swiftFilePath,
            "-m",
            "Test Message"
        ]
        
        let pipe = Pipe()
        process.standardError = pipe
        
        try! process.run()
        process.waitUntilExit()
        
        XCTAssertNotNil(process.standardError)
        let handle = pipe.fileHandleForReading
        let errorString = String(data: handle.availableData, encoding: .utf8)
        XCTAssertNotNil(errorString)
        XCTAssert(errorString!.count > 0)
    }
    
    /// Returns path to the built products directory.
    var productsDirectory: URL {
      #if os(macOS)
        for bundle in Bundle.allBundles where bundle.bundlePath.hasSuffix(".xctest") {
            return bundle.bundleURL.deletingLastPathComponent()
        }
        fatalError("couldn't find the products directory")
      #else
        return Bundle.main.bundleURL
      #endif
    }

    static var allTests = [
        ("testGenerateStrings", testGenerateStrings),
        ("testGenerateStringsFailsForTooManyArgumentsCount", testGenerateStringsFailsForTooManyArgumentsCount),
        ("testGenerateStringsFailsForTooFewArgumentsCount", testGenerateStringsFailsForTooFewArgumentsCount)
    ]
}

extension StringsGeneratorTests {
    
    func setUpCorrect() {
        var dummyFilePath = NSTemporaryDirectory().appending("file.strings")
        var contents =
            """
        staticText = "Static text";
        section1.subsection1.staticText = "Some text";
        section1.subsection2.dynamicText_:_param2 = "Some text with param1: %@ and param2: %d";
        section2.subsection1.floatText_floatName = "Some float %6.4f";
        multilineArgumentText_:_: = "Some argument on line 1 %@\nfollowed by some argument on line 2 %@";
        """.data(using: .utf8)
        
        
        FileManager.default.createFile(atPath: dummyFilePath, contents: contents, attributes: nil)
        localizedStringFilePath = dummyFilePath
        
        dummyFilePath = NSTemporaryDirectory().appending("file.stringsdict")
        contents = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>time.days_:</key>
            <dict>
                <key>NSStringLocalizedFormatKey</key>
                <string>%#@VARIABLE@</string>
                <key>VARIABLE</key>
                <dict>
                    <key>NSStringFormatSpecTypeKey</key>
                    <string>NSStringPluralRuleType</string>
                    <key>NSStringFormatValueTypeKey</key>
                    <string>d</string>
                    <key>one</key>
                    <string>1 day</string>
                    <key>other</key>
                    <string>%d days</string>
                </dict>
            </dict>
            <key>time.hours_:</key>
            <dict>
                <key>NSStringLocalizedFormatKey</key>
                <string>%#@VARIABLE@</string>
                <key>VARIABLE</key>
                <dict>
                    <key>NSStringFormatSpecTypeKey</key>
                    <string>NSStringPluralRuleType</string>
                    <key>NSStringFormatValueTypeKey</key>
                    <string>d</string>
                    <key>one</key>
                    <string>1 hr</string>
                    <key>other</key>
                    <string>%d hrs</string>
                </dict>
            </dict>
            <key>time.minutes_:</key>
            <dict>
                <key>NSStringLocalizedFormatKey</key>
                <string>%#@VARIABLE@</string>
                <key>VARIABLE</key>
                <dict>
                    <key>NSStringFormatSpecTypeKey</key>
                    <string>NSStringPluralRuleType</string>
                    <key>NSStringFormatValueTypeKey</key>
                    <string>d</string>
                    <key>one</key>
                    <string>1 min</string>
                    <key>other</key>
                    <string>%d mins</string>
                </dict>
            </dict>
            <key>multivariable_string_int1_int2</key>
            <dict>
                <key>NSStringLocalizedFormatKey</key>
                <string>Multivariable string of %@ with %#@item1@ and %#@item2@</string>
                <key>item1</key>
                <dict>
                    <key>NSStringFormatSpecTypeKey</key>
                    <string>NSStringPluralRuleType</string>
                    <key>NSStringFormatValueTypeKey</key>
                    <string>d</string>
                    <key>one</key>
                    <string>1 item 1</string>
                    <key>other</key>
                    <string>%d item 1's</string>
                </dict>
                <key>item2</key>
                <dict>
                    <key>NSStringFormatSpecTypeKey</key>
                    <string>NSStringPluralRuleType</string>
                    <key>NSStringFormatValueTypeKey</key>
                    <string>d</string>
                    <key>one</key>
                    <string>1 item 2</string>
                    <key>other</key>
                    <string>%d item 2's</string>
                </dict>
            </dict>
        </dict>
        </plist>
        """.data(using: .utf8)
        FileManager.default.createFile(atPath: dummyFilePath, contents: contents, attributes: nil)
        localizedDictFilePath = dummyFilePath
        
        dummyFilePath = NSTemporaryDirectory().appending("file.swift")
        FileManager.default.createFile(atPath: dummyFilePath, contents: nil, attributes: nil)
        swiftFilePath = dummyFilePath
    }
    
    func setUpFailTooManyArguments() {
        var dummyFilePath = NSTemporaryDirectory().appending("file.strings")
        var contents =
            """
        staticText = "Static text";
        section1.subsection1.staticText = "Some text";
        section1.subsection2.dynamicText_:_param2 = "Some text with param1: %@ and param2: %d";
        section2.subsection1.floatText = "Some float %6.4f";
        multilineArgumentText_one_too_manyArguments = "Some argument on line 1 %@\nfollowed by some argument on line 2 %@";
        """.data(using: .utf8)
        
        
        FileManager.default.createFile(atPath: dummyFilePath, contents: contents, attributes: nil)
        localizedStringFilePath = dummyFilePath
        
        dummyFilePath = NSTemporaryDirectory().appending("file.stringsdict")
        contents = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>time.days</key>
            <dict>
                <key>NSStringLocalizedFormatKey</key>
                <string>%#@VARIABLE@</string>
                <key>VARIABLE</key>
                <dict>
                    <key>NSStringFormatSpecTypeKey</key>
                    <string>NSStringPluralRuleType</string>
                    <key>NSStringFormatValueTypeKey</key>
                    <string>d</string>
                    <key>one</key>
                    <string>1 day</string>
                    <key>other</key>
                    <string>%d days</string>
                </dict>
            </dict>
            <key>time.hours</key>
            <dict>
                <key>NSStringLocalizedFormatKey</key>
                <string>%#@VARIABLE@</string>
                <key>VARIABLE</key>
                <dict>
                    <key>NSStringFormatSpecTypeKey</key>
                    <string>NSStringPluralRuleType</string>
                    <key>NSStringFormatValueTypeKey</key>
                    <string>d</string>
                    <key>one</key>
                    <string>1 hr</string>
                    <key>other</key>
                    <string>%d hrs</string>
                </dict>
            </dict>
            <key>time.minutes</key>
            <dict>
                <key>NSStringLocalizedFormatKey</key>
                <string>%#@VARIABLE@</string>
                <key>VARIABLE</key>
                <dict>
                    <key>NSStringFormatSpecTypeKey</key>
                    <string>NSStringPluralRuleType</string>
                    <key>NSStringFormatValueTypeKey</key>
                    <string>d</string>
                    <key>one</key>
                    <string>1 min</string>
                    <key>other</key>
                    <string>%d mins</string>
                </dict>
            </dict>
        </dict>
        </plist>
        """.data(using: .utf8)
        FileManager.default.createFile(atPath: dummyFilePath, contents: contents, attributes: nil)
        localizedDictFilePath = dummyFilePath
        
        dummyFilePath = NSTemporaryDirectory().appending("file.swift")
        FileManager.default.createFile(atPath: dummyFilePath, contents: nil, attributes: nil)
        swiftFilePath = dummyFilePath
    }
    
    func setUpFailNotEnoughArguments() {
        var dummyFilePath = NSTemporaryDirectory().appending("file.strings")
        var contents =
            """
        staticText = "Static text";
        section1.subsection1.staticText = "Some text";
        section1.subsection2.dynamicText_:_param2 = "Some text with param1: %@ and param2: %d";
        section2.subsection1.floatText = "Some float %6.4f";
        multilineArgumentText_notEnoughArguments = "Some argument on line 1 %@\nfollowed by some argument on line 2 %@";
        """.data(using: .utf8)
        
        
        FileManager.default.createFile(atPath: dummyFilePath, contents: contents, attributes: nil)
        localizedStringFilePath = dummyFilePath
        
        dummyFilePath = NSTemporaryDirectory().appending("file.stringsdict")
        contents = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>time.days_:</key>
            <dict>
                <key>NSStringLocalizedFormatKey</key>
                <string>%#@VARIABLE@</string>
                <key>VARIABLE</key>
                <dict>
                    <key>NSStringFormatSpecTypeKey</key>
                    <string>NSStringPluralRuleType</string>
                    <key>NSStringFormatValueTypeKey</key>
                    <string>d</string>
                    <key>one</key>
                    <string>1 day</string>
                    <key>other</key>
                    <string>%d days</string>
                </dict>
            </dict>
            <key>time.hours_:</key>
            <dict>
                <key>NSStringLocalizedFormatKey</key>
                <string>%#@VARIABLE@</string>
                <key>VARIABLE</key>
                <dict>
                    <key>NSStringFormatSpecTypeKey</key>
                    <string>NSStringPluralRuleType</string>
                    <key>NSStringFormatValueTypeKey</key>
                    <string>d</string>
                    <key>one</key>
                    <string>1 hr</string>
                    <key>other</key>
                    <string>%d hrs</string>
                </dict>
            </dict>
            <key>time.minutes_:</key>
            <dict>
                <key>NSStringLocalizedFormatKey</key>
                <string>%#@VARIABLE@</string>
                <key>VARIABLE</key>
                <dict>
                    <key>NSStringFormatSpecTypeKey</key>
                    <string>NSStringPluralRuleType</string>
                    <key>NSStringFormatValueTypeKey</key>
                    <string>d</string>
                    <key>one</key>
                    <string>1 min</string>
                    <key>other</key>
                    <string>%d mins</string>
                </dict>
            </dict>
        </dict>
        </plist>
        """.data(using: .utf8)
        FileManager.default.createFile(atPath: dummyFilePath, contents: contents, attributes: nil)
        localizedDictFilePath = dummyFilePath
        
        dummyFilePath = NSTemporaryDirectory().appending("file.swift")
        FileManager.default.createFile(atPath: dummyFilePath, contents: nil, attributes: nil)
        swiftFilePath = dummyFilePath
    }
}
