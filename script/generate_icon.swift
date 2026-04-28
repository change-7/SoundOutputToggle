#!/usr/bin/env swift

import AppKit
import Foundation

let arguments = CommandLine.arguments

guard arguments.count == 3 else {
    FileHandle.standardError.write(Data("usage: generate_icon.swift <output.icns> <A|B|settings|unknown>\n".utf8))
    exit(2)
}

let outputURL = URL(fileURLWithPath: arguments[1])
let variant = arguments[2]
let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
    .appendingPathComponent("SoundOutputToggle-\(UUID().uuidString).iconset")

try FileManager.default.createDirectory(at: tempURL, withIntermediateDirectories: true)
defer {
    try? FileManager.default.removeItem(at: tempURL)
}

let sizes = [
    (16, 1), (16, 2),
    (32, 1), (32, 2),
    (128, 1), (128, 2),
    (256, 1), (256, 2),
    (512, 1), (512, 2)
]

for (points, scale) in sizes {
    let pixels = points * scale
    let image = makeIcon(variant: variant, pixels: pixels)

    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let data = bitmap.representation(using: .png, properties: [:]) else {
        fatalError("Could not render \(pixels)x\(pixels) icon")
    }

    let suffix = scale == 1 ? "" : "@\(scale)x"
    let filename = "icon_\(points)x\(points)\(suffix).png"
    try data.write(to: tempURL.appendingPathComponent(filename))
}

try FileManager.default.createDirectory(
    at: outputURL.deletingLastPathComponent(),
    withIntermediateDirectories: true
)

let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", tempURL.path, "-o", outputURL.path]
try process.run()
process.waitUntilExit()

if process.terminationStatus != 0 {
    exit(process.terminationStatus)
}

private func makeIcon(variant: String, pixels: Int) -> NSImage {
    let size = NSSize(width: pixels, height: pixels)
    let image = NSImage(size: size)
    let scale = CGFloat(pixels) / 1024

    image.lockFocus()

    NSColor.clear.setFill()
    NSRect(origin: .zero, size: size).fill()

    let backgroundColor: NSColor
    let label: String
    let showsSettingsBadge: Bool

    switch variant {
    case "A":
        backgroundColor = .systemBlue
        label = "A"
        showsSettingsBadge = false
    case "B":
        backgroundColor = .systemGreen
        label = "B"
        showsSettingsBadge = false
    case "settings":
        backgroundColor = .systemGray
        label = ""
        showsSettingsBadge = true
    default:
        backgroundColor = .systemGray
        label = "?"
        showsSettingsBadge = false
    }

    let backgroundRect = NSRect(x: 76 * scale, y: 76 * scale, width: 872 * scale, height: 872 * scale)
    let backgroundPath = NSBezierPath(
        roundedRect: backgroundRect,
        xRadius: 210 * scale,
        yRadius: 210 * scale
    )
    backgroundColor.setFill()
    backgroundPath.fill()

    let symbolConfig = NSImage.SymbolConfiguration(pointSize: 410 * scale, weight: .semibold)
    if let symbol = NSImage(systemSymbolName: "speaker.wave.2.fill", accessibilityDescription: nil)?
        .withSymbolConfiguration(symbolConfig) {
        symbol.isTemplate = true
        NSColor.white.withAlphaComponent(0.88).set()
        symbol.draw(
            in: NSRect(x: 214 * scale, y: 334 * scale, width: 596 * scale, height: 420 * scale),
            from: .zero,
            operation: .sourceOver,
            fraction: 1
        )
    }

    if !label.isEmpty {
        let badgeRect = NSRect(x: 74 * scale, y: 92 * scale, width: 876 * scale, height: 282 * scale)
        let badgePath = NSBezierPath(
            roundedRect: badgeRect,
            xRadius: 141 * scale,
            yRadius: 141 * scale
        )
        NSColor.white.setFill()
        badgePath.fill()

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let horizontalPadding = 30 * scale
        let maxTextWidth = badgeRect.width - horizontalPadding * 2
        let maxTextHeight = badgeRect.height - 42 * scale
        let fontSize = fittedFontSize(
            label: label,
            maxWidth: maxTextWidth,
            maxHeight: maxTextHeight,
            minSize: 112 * scale,
            maxSize: 298 * scale
        )
        let font = NSFont.systemFont(ofSize: fontSize, weight: .heavy)
        let measuredSize = (label as NSString).size(withAttributes: [.font: font])
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: backgroundColor,
            .paragraphStyle: paragraph
        ]

        (label as NSString).draw(
            in: NSRect(
                x: badgeRect.minX + horizontalPadding,
                y: badgeRect.midY - measuredSize.height / 2 - 12 * scale,
                width: maxTextWidth,
                height: measuredSize.height + 24 * scale
            ),
            withAttributes: attributes
        )
    }

    if showsSettingsBadge {
        drawSettingsBadge(backgroundColor: backgroundColor, scale: scale)
    }

    image.unlockFocus()
    return image
}

private func fittedFontSize(
    label: String,
    maxWidth: CGFloat,
    maxHeight: CGFloat,
    minSize: CGFloat,
    maxSize: CGFloat
) -> CGFloat {
    var size = maxSize

    while size > minSize {
        let font = NSFont.systemFont(ofSize: size, weight: .heavy)
        let measured = (label as NSString).size(withAttributes: [.font: font])

        if measured.width <= maxWidth && measured.height <= maxHeight {
            return size
        }

        size -= 4
    }

    return minSize
}

private func drawSettingsBadge(backgroundColor: NSColor, scale: CGFloat) {
    let badgeRect = NSRect(x: 642 * scale, y: 650 * scale, width: 286 * scale, height: 286 * scale)
    let badgePath = NSBezierPath(ovalIn: badgeRect)
    NSColor.white.setFill()
    badgePath.fill()

    let gearConfig = NSImage.SymbolConfiguration(pointSize: 178 * scale, weight: .bold)
    if let gear = NSImage(systemSymbolName: "gearshape.fill", accessibilityDescription: nil)?
        .withSymbolConfiguration(gearConfig) {
        gear.isTemplate = true
        backgroundColor.set()
        gear.draw(
            in: NSRect(x: 696 * scale, y: 704 * scale, width: 178 * scale, height: 178 * scale),
            from: .zero,
            operation: .sourceOver,
            fraction: 1
        )
    }
}
