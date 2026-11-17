// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "BeanKit",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [
        .library(name: "BeanKit", targets: ["BeanKit"]),
        .executable(name: "beanpod", targets: ["beanpod"]),
    ],
    targets: [
        .target(name: "BeanKit"),
        .executableTarget(name: "beanpod", swiftSettings: [.swiftLanguageMode(.v5)]),
        // 职业预设、自定义项和整理提示词拼接。和 App 编译的是同一份 Shared/Profession.swift，这里单独做成库，便于不启动界面就测。
        .target(name: "NotesCore", path: "Shared", sources: ["Profession.swift"]),
        .testTarget(name: "BeanKitTests", dependencies: ["BeanKit"], resources: [.copy("Fixtures")]),
        .testTarget(name: "NotesCoreTests", dependencies: ["NotesCore"], path: "Tests/NotesCoreTests"),
    ]
)
