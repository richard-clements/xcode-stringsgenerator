# StringsGenerator

A build tool for Xcode to create a swift api for any strings that are in Localizable.strings or Localizable.stringsdict.

## Key Path Style

The tool converts key paths into nested structs. A string with no arguments will be created as a variable, while a string that contains arguments will be created as a function with the required type parameters. You can define the arguments of the function by using underscores for each argument.

E.g.
```
someSection.somesubsection.someConstant = "A constant";
someSection.someArgumentedString_argument1_argument2 = "A string with arguments %@ %d";
```

```swift
struct SomeSection {
  struct SomeSubsection { 
    static let someConstant = NSLocalizedString("someSection.somesubsection.someConstant", comment: "")
  }
  static func someArgumentedString(argument1 arg0: String, argument2 arg1: Int) String {
    return String(format: NSLocalizedString("someSection.someArgumentedString_argument1_argument2", comment: ""), arg0, arg1)
  }
}
```

## Usage

To run the strings generator, for input files `Localizable.strings`, `Localizable.stringsdict` and output file `Localizable.swift` use:
```shell
swift run strings-generator Localizable.strings Localizable.stringsdict -o Localizable.swift
```

The command should be ran as a build script as early as possible in the Build Phases tasks.
