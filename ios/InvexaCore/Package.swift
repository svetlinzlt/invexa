// swift-tools-version: 6.0
import PackageDescription

// Логиката на приложението стои отделно от интерфейса нарочно:
// така се тества за секунди, без симулатор, и не зависи от SwiftUI,
// SwiftData или версията на iOS. Приложението внася този пакет.
let package = Package(
    name: "InvexaCore",
    // Езикът по подразбиране е български: продуктът тръгва от българския
    // пазар и преводът на английски е добавка, не обратното.
    defaultLocalization: "bg",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "InvexaCore", targets: ["InvexaCore"]),
    ],
    targets: [
        .target(
            name: "InvexaCore",
            resources: [.process("Resources")]
        ),
        .testTarget(name: "InvexaCoreTests", dependencies: ["InvexaCore"]),
    ]
)
