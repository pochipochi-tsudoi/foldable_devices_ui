// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "foldable_devices_ui",
  platforms: [
    .iOS("12.0")
  ],
  products: [
    .library(name: "foldable-devices-ui", targets: ["foldable_devices_ui"])
  ],
  dependencies: [
    .package(name: "FlutterFramework", path: "../FlutterFramework")
  ],
  targets: [
    .target(
      name: "foldable_devices_ui",
      dependencies: [
        .product(name: "FlutterFramework", package: "FlutterFramework")
      ]
    )
  ]
)
