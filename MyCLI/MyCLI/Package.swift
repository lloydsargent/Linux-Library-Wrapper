// swift-tools-version: 6.3

// ^^^ that line MUST exist or you will get an error. Don’t remove it thinking it’s
//     just a comment. Or remove it and see what happens. Trust me.

import PackageDescription

let package = Package(
    name: "MyCLI",
    dependencies: [ ],
    targets: [
        .systemLibrary(
            name: "CSDL3",
            // These are the names in /usr/local/lib/pkgConfig
            // The pkgConfig files refer to the REAL libraries
            pkgConfig: "sdl3",
            providers: [ ]
        ),
        .executableTarget(
            name: "MyCLI", 
            dependencies: [ "CSDL3"],
         ),
        .testTarget(
            name: "MyCLITests",
            dependencies: ["MyCLI"]
        ),
    ],
    swiftLanguageModes: [.v6]
)