// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "SwiftLinkedListAndHash",
    products: [
        .library(name: "SwiftLinkedListAndHash", targets: ["SwiftLinkedListAndHash"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "SwiftLinkedListAndHash",
            dependencies: []
        ),
        // test cases
        .testTarget(
            name: "unit-tests",
            dependencies: ["SwiftLinkedListAndHash"],
            swiftSettings: [
                .unsafeFlags([
                    "-Ounchecked",
                ]),
            ]
        ),
    ]
)
