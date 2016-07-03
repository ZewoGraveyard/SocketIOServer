import PackageDescription

let package = Package(
    name: "SocketIOServer",
    dependencies: [
		.Package(url: "https://github.com/Zewo/EngineIOServer.git", majorVersion: 0, minor: 7)
    ]
)
