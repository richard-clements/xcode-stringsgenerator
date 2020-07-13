import StringsGeneratorCore
import Foundation

do {
    let tool = StringsGenerator()
    try tool.run()
} catch {
    let fileHandle = FileHandle.standardError
    fileHandle.write(error.localizedDescription.data(using: .utf8) ?? Data())
    exit(1)
}
