// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "YPImagePicker",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(name: "YPImagePicker", targets: ["YPImagePicker"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/freshOS/Stevia",
            .exact("4.8.0")
        ),
        .package(
            url: "https://github.com/HHK1/PryntTrimmerView",
            .exact("4.0.2")
        ),
        .package(
            url: "https://github.com/SDWebImage/SDWebImage.git",
            .exact("5.15.8")
        )
    ],
    targets: [
        .target(
            name: "YPImagePicker",
            dependencies: ["Stevia", "PryntTrimmerView", "SDWebImage"],
            path: "Source",
            exclude: ["Info.plist", "YPImagePickerHeader.h"]
        )
    ]
)
