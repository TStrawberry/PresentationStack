// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PresentationStack",
    platforms: [.iOS(.v18)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "PresentationStack",
            targets: ["PresentationStack"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/TStrawberry/NavigationValues", .upToNextMajor(from: "1.0.2"))
    ],
    targets: [
        .target(
            name: "PresentationStack",
            dependencies: [
                .byName(name: "NavigationValues")
            ]
        ),
        .testTarget(
            name: "PresentationStackTests",
            dependencies: ["PresentationStack"]
        ),
    ]
)
