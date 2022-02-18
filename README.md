# scan-swift

A swift port of fmt.scan in go.
scan-swift provides scanner which scans text read from a file or string.

## Usage

```swift
import ScanSwift
func p<T>(_ x: UnsafeMutablePointer<T>) -> Any {
    return x
}
var (s, b, c) = ("", 0, 0)
let n = try sscan(content: "hello     2345  111", p(&s), p(&b), p(&c))
print(n, s, b, c)
```

## Adding `ScanSwift` as a Dependency

To use the `ScanSwift` library in a SwiftPM project, 
add it to the dependencies for your package:

```swift
let package = Package(
    // name, platforms, products, etc.
    dependencies: [
        // other dependencies
        .package(url: "https://github.com/nnabeyang/scan-swift", from: "0.0.0"),
    ],
    targets: [
        .executableTarget(name: "<executable-target-name>", dependencies: [
            // other dependencies
            .product(name: "ScanSwift", package: "scan-swift"),
        ]),
        // other targets
    ]
)
```

## License

scan-swift is published under the MIT License, see LICENSE.

## Author
[Noriaki Watanabe@nnabeyang](https://twitter.com/nnabeyang)
