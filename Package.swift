// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "darwin-apk",
  platforms: [
    .macOS(.v13),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.6.1"),
    .package(url: "https://github.com/davecom/SwiftGraph", from: "3.1.0"),
  ],
  targets: [
    .target(
      name: "darwin-apk",
      dependencies: [
        .product(name: "SwiftGraph", package: "SwiftGraph"),
      ],
      path: "Sources/apk",
    ),
    .testTarget(
      name: "darwin-apk-tests",
      dependencies: [
        "darwin-apk",
      ],
    ),
    .executableTarget(
      name: "dpk",
      dependencies: [
        "darwin-apk",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ],
      path: "Sources/dpk-cli",
    ),
  ],
)
