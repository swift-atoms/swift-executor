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
            name: "Executor",
            targets: ["Executor"]
        ),
        .library(
            name: "Executor Standard Library Integration",
            targets: ["Executor Standard Library Integration"]
        ),
        .library(
            name: "Executor Apple Foundation Integration",
            targets: ["Executor Apple Foundation Integration"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Executor",
            dependencies: []
        ),
        .target(
            name: "Executor Standard Library Integration",
            dependencies: ["Executor"]
        ),
        .target(
            name: "Executor Apple Foundation Integration",
            dependencies: [
                "Executor",
                "Executor Standard Library Integration",
            ]
        ),
        .testTarget(
            name: "Executor Tests",
            dependencies: ["Executor"]
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
