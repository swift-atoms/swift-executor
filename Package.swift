// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "swift-executor",
    platforms: [
        .macOS(.v27),
        .iOS(.v27),
        .tvOS(.v27),
        .watchOS(.v27),
        .visionOS(.v27),
    ],
    products: [

        .library(
            name: "Executor Primitive",
            targets: ["Executor Primitive"]
        ),
        .library(
            name: "Executor Job",
            targets: ["Executor Job"]
        ),
        .library(
            name: "Executor Shutdown",
            targets: ["Executor Shutdown"]
        ),
        .library(
            name: "Executor Wait",
            targets: ["Executor Wait"]
        ),

        .library(
            name: "Executor Job Queue",
            targets: ["Executor Job Queue"]
        ),
        .library(
            name: "Executor Job Deque",
            targets: ["Executor Job Deque"]
        ),

        .library(
            name: "Executor",
            targets: ["Executor"]
        ),
        .library(
            name: "Executor Test Support",
            targets: ["Executor Test Support"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/swift-molecules/swift-buffer-ring.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-clock.git",
            branch: "main"
        ),

        .package(
            url: "https://github.com/swift-molecules/swift-column.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-deque.git",
            branch: "main"
        ),

        .package(
            url: "https://github.com/swift-molecules/swift-index.git",
            branch: "main"
        ),
    ],
    targets: [

        .target(
            name: "Executor Primitive",
            dependencies: []
        ),
        .target(
            name: "Executor Job",
            dependencies: [
                "Executor Primitive"
            ]
        ),
        .target(
            name: "Executor Shutdown",
            dependencies: [
                "Executor Primitive"
            ]
        ),
        .target(
            name: "Executor Wait",
            dependencies: [
                "Executor Primitive"
            ]
        ),

        .target(
            name: "Executor Job Queue",
            dependencies: [
                "Executor Job",
                .product(name: "Buffer Ring Primitive", package: "swift-buffer-ring"),
                .product(name: "Column", package: "swift-column"),
                .product(name: "Deque", package: "swift-deque"),
                .product(name: "Index", package: "swift-index"),
            ]
        ),

        .target(
            name: "Executor Job Deque",
            dependencies: [
                "Executor Job",
                .product(name: "Index", package: "swift-index"),
            ]
        ),

        .target(
            name: "Executor",
            dependencies: [
                "Executor Primitive",
                "Executor Job",
                "Executor Shutdown",
                "Executor Wait",
                "Executor Job Queue",
                "Executor Job Deque",

            ]
        ),

        .target(
            name: "Executor Test Support",
            dependencies: [
                "Executor"
            ],
            path: "Tests/Support"
        ),

        .testTarget(
            name: "Executor Tests",
            dependencies: [
                "Executor",
                "Executor Test Support",
                .product(name: "Clock", package: "swift-clock"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("Lifetimes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
    ]

    let package: [SwiftSetting] = [
        .define(
            "KERNEL_AVAILABLE",
            .when(platforms: [
                .macOS, .iOS, .tvOS, .watchOS, .visionOS,
                .linux, .windows, .android, .openbsd,
            ])
        )
    ]

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
