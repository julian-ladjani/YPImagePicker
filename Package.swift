// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "YPImagePicker",
    defaultLocalization: "en",
    platforms: [.iOS(.v12)],
    products: [ .library(name: "YPImagePicker", targets: ["YPImagePicker"]) ],
    dependencies: [
        .package(url: "https://github.com/freshOS/Stevia", .exact("5.1.0")),
        .package(url: "https://github.com/HHK1/PryntTrimmerView", .exact("4.0.2")),
        .package(url: "https://github.com/SDWebImage/SDWebImage.git", .exact("5.11.1"))
    ],
    targets: [
        .target(name: "YPImagePicker", dependencies: ["Stevia", "PryntTrimmerView", "SDWebImage"]),
        .testTarget(name: "YPImagePickerTests", dependencies: ["YPImagePicker"]),
    ]
)
