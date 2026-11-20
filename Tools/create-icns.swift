import Foundation

guard CommandLine.arguments.count == 3 else {
    fatalError("Usage: create-icns.swift ICONSET_DIRECTORY OUTPUT_FILE")
}

let iconset = URL(fileURLWithPath: CommandLine.arguments[1])
let output = URL(fileURLWithPath: CommandLine.arguments[2])
let images: [(String, String)] = [
    ("icp4", "icon_16x16.png"),
    ("ic11", "icon_32x32.png"),
    ("icp5", "icon_32x32.png"),
    ("ic12", "icon_64x64.png"),
    ("ic07", "icon_128x128.png"),
    ("ic13", "icon_256x256.png"),
    ("ic08", "icon_256x256.png"),
    ("ic14", "icon_512x512.png"),
    ("ic09", "icon_512x512.png"),
    ("ic10", "icon_1024x1024.png"),
]

var icns = Data("icns".utf8)
icns.append(contentsOf: [0, 0, 0, 0])
for (type, filename) in images {
    let image = try Data(contentsOf: iconset.appendingPathComponent(filename))
    icns.append(contentsOf: type.utf8)
    var chunkLength = UInt32(image.count + 8).bigEndian
    withUnsafeBytes(of: &chunkLength) { icns.append(contentsOf: $0) }
    icns.append(image)
}
var fileLength = UInt32(icns.count).bigEndian
withUnsafeBytes(of: &fileLength) { icns.replaceSubrange(4..<8, with: $0) }
try icns.write(to: output, options: .atomic)
