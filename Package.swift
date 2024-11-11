// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "darwin-apk",
  platforms: [
    .macOS(.v13),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0"),
  ],
  targets: [
    .target(
      name: "darwin-apk",
      path: "Sources/apk"),
    .executableTarget(
      name: "dpk",
      dependencies: [
        "darwin-apk",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ],
      path: "Sources/dpk-cli"
    ),
  ]
)
