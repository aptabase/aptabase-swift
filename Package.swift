// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Aptabase",
    platforms: [
      .iOS(.v13),
      .macCatalyst(.v13),
      .macOS(.v10_15),
      .watchOS(.v6),
      .tvOS(.v13),
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Aptabase",
            targets: ["Aptabase"]),
    ],
    dependencies: [],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Aptabase",
            dependencies: []),
        .testTarget(
            name: "AptabaseTests",
            dependencies: ["Aptabase"]
        )
    ]
)


#if swift(>=5.6)
// Add the DocC plugin if possible.
package.dependencies.append(.package(url: "https://github.com/apple/swift-docc-plugin", from: "1.3.0"))
#endif
