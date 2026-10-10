// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "AKeyboardSwitcher",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "AKeyboardSwitcher",
            path: "Sources/AKeyboardSwitcher",
            linkerSettings: [.linkedFramework("IOBluetooth")]
        )
    ]
)
