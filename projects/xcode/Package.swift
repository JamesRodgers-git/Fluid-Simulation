// swift-tools-version:5.10
import PackageDescription

// not used, preserved for history of mankind

let package = Package(
    name: "Fluid",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "fluid", targets: [ "Main" ])
    ],
    targets: [
        .executableTarget(
            name: "Main",
            dependencies: [ "Bridge" ],
            sources: [ "Main.swift" ],
            linkerSettings: [
                .unsafeFlags([ "-L", "Sources/zig_build" ]),
                .linkedLibrary("fluid", .when(platforms: [.macOS]))
            ]
        ),
        .target(
            name: "Bridge",
            path: "Sources/C"
        ),
    ]
)