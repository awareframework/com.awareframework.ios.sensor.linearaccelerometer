// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "com.awareframework.ios.sensor.linearaccelerometer",
    platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "com.awareframework.ios.sensor.linearaccelerometer",
            targets: [
                "com.awareframework.ios.sensor.linearaccelerometer"
            ]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/awareframework/com.awareframework.ios.core.git", from: "1.1.0")
    ],
    targets: [
        .target(
            name: "com.awareframework.ios.sensor.linearaccelerometer",
            dependencies: [
                .product(name: "com.awareframework.ios.core", package: "com.awareframework.ios.core", condition: .when(platforms: [.iOS]))
            ],
            path: "Sources/com.awareframework.ios.sensor.linearaccelerometer"
        ),
        .testTarget(
            name: "com.awareframework.ios.sensor.linearaccelerometerTests",
            dependencies: [
                "com.awareframework.ios.sensor.linearaccelerometer",
                .product(name: "com.awareframework.ios.core", package: "com.awareframework.ios.core", condition: .when(platforms: [.iOS]))
            ],
            path: "Tests/com.awareframework.ios.sensor.linearaccelerometerTests"
        )
    ],
    swiftLanguageModes: [.v5]
)
