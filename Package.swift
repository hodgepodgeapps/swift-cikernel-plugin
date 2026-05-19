// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "SwiftCIKernelPlugin",
    platforms: [
        .macOS(.v26),
        .iOS(.v26)
    ],
    products: [
        .plugin(name: "Swift-CIKernel", targets: ["Swift-CIKernel"]),
    ],
    targets: [
        .plugin(name: "Swift-CIKernel", capability: .buildTool()),

        .testTarget(name: "Swift-CIKernel-Tests", exclude: [
            // Exclude so that the default Metal compiler is not used.
            "CIKernels",
        ], plugins: ["Swift-CIKernel"]),
    ]
)
