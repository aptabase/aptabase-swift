// swift-tools-version: 5.5
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
        .library(name: "Aptabase", targets: ["Aptabase"]),
    ],
    targets: [
        // .target(name: "Aptabase")
        .binaryTarget(name: "Aptabase", path: "Aptabase.xcframework")
    ]
)
