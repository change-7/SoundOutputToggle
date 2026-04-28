import AppKit
import Foundation

final class IconService {
    func updateToggleAppIcon(slot: OutputSlot, deviceName: String? = nil) {
        if let toggleURL = toggleAppBundleURL() {
            applyIcon(
                makeToggleIcon(slot: slot, deviceName: deviceName),
                to: toggleURL,
                resourceName: "SoundOutputToggle"
            )
        }

        if let settingsURL = settingsAppBundleURL() {
            applyIcon(
                makeSettingsIcon(),
                to: settingsURL,
                resourceName: "SoundOutputToggleSettings"
            )
        }
    }

    private func toggleAppBundleURL() -> URL? {
        let currentBundleURL = Bundle.main.bundleURL
        let currentName = currentBundleURL.lastPathComponent

        if currentName == "SoundOutputToggle.app" {
            return currentBundleURL
        }

        if currentName == "SoundOutputToggle Settings.app" {
            let siblingURL = currentBundleURL
                .deletingLastPathComponent()
                .appendingPathComponent("SoundOutputToggle.app")

            return FileManager.default.fileExists(atPath: siblingURL.path) ? siblingURL : nil
        }

        return nil
    }

    private func settingsAppBundleURL() -> URL? {
        let currentBundleURL = Bundle.main.bundleURL
        let currentName = currentBundleURL.lastPathComponent

        if currentName == "SoundOutputToggle Settings.app" {
            return currentBundleURL
        }

        if currentName == "SoundOutputToggle.app" {
            let siblingURL = currentBundleURL
                .deletingLastPathComponent()
                .appendingPathComponent("SoundOutputToggle Settings.app")

            return FileManager.default.fileExists(atPath: siblingURL.path) ? siblingURL : nil
        }

        return nil
    }

    private func makeToggleIcon(slot: OutputSlot, deviceName: String?) -> NSImage {
        let size = NSSize(width: 1024, height: 1024)
        let image = NSImage(size: size)

        image.lockFocus()

        NSColor.clear.setFill()
        NSRect(origin: .zero, size: size).fill()

        let backgroundColor: NSColor
        switch slot {
        case .primary:
            backgroundColor = NSColor.systemBlue
        case .secondary:
            backgroundColor = NSColor.systemGreen
        case .unknown:
            backgroundColor = NSColor.systemGray
        }

        let backgroundRect = NSRect(x: 76, y: 76, width: 872, height: 872)
        let backgroundPath = NSBezierPath(roundedRect: backgroundRect, xRadius: 210, yRadius: 210)
        backgroundColor.setFill()
        backgroundPath.fill()

        let speakerConfig = NSImage.SymbolConfiguration(pointSize: 410, weight: .semibold)
        if let speaker = NSImage(
            systemSymbolName: "speaker.wave.2.fill",
            accessibilityDescription: nil
        )?.withSymbolConfiguration(speakerConfig) {
            speaker.isTemplate = true
            NSColor.white.withAlphaComponent(0.88).set()
            speaker.draw(
                in: NSRect(x: 214, y: 334, width: 596, height: 420),
                from: .zero,
                operation: .sourceOver,
                fraction: 1
            )
        }

        drawDeviceNameBadge(
            label: deviceNamePrefix(from: deviceName),
            textColor: backgroundColor
        )

        image.unlockFocus()
        return image
    }

    private func makeSettingsIcon() -> NSImage {
        let size = NSSize(width: 1024, height: 1024)
        let image = NSImage(size: size)
        let backgroundColor = NSColor.systemGray

        image.lockFocus()

        NSColor.clear.setFill()
        NSRect(origin: .zero, size: size).fill()

        let backgroundRect = NSRect(x: 76, y: 76, width: 872, height: 872)
        let backgroundPath = NSBezierPath(roundedRect: backgroundRect, xRadius: 210, yRadius: 210)
        backgroundColor.setFill()
        backgroundPath.fill()

        let speakerConfig = NSImage.SymbolConfiguration(pointSize: 410, weight: .semibold)
        if let speaker = NSImage(
            systemSymbolName: "speaker.wave.2.fill",
            accessibilityDescription: nil
        )?.withSymbolConfiguration(speakerConfig) {
            speaker.isTemplate = true
            NSColor.white.withAlphaComponent(0.88).set()
            speaker.draw(
                in: NSRect(x: 214, y: 334, width: 596, height: 420),
                from: .zero,
                operation: .sourceOver,
                fraction: 1
            )
        }

        drawSettingsBadge(backgroundColor: backgroundColor)

        image.unlockFocus()
        return image
    }

    private func drawDeviceNameBadge(label: String, textColor: NSColor) {
        let badgeRect = NSRect(x: 74, y: 92, width: 876, height: 282)
        let badgePath = NSBezierPath(roundedRect: badgeRect, xRadius: 141, yRadius: 141)
        NSColor.white.setFill()
        badgePath.fill()

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let horizontalPadding: CGFloat = 30
        let maxTextWidth = badgeRect.width - horizontalPadding * 2
        let maxTextHeight = badgeRect.height - 42
        let fontSize = fittedFontSize(
            label: label,
            maxWidth: maxTextWidth,
            maxHeight: maxTextHeight,
            minSize: 112,
            maxSize: 298
        )
        let font = NSFont.systemFont(ofSize: fontSize, weight: .heavy)
        let measuredSize = (label as NSString).size(withAttributes: [.font: font])

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor,
            .paragraphStyle: paragraph
        ]
        (label as NSString).draw(
            in: NSRect(
                x: badgeRect.minX + horizontalPadding,
                y: badgeRect.midY - measuredSize.height / 2 - 12,
                width: maxTextWidth,
                height: measuredSize.height + 24
            ),
            withAttributes: attributes
        )
    }

    private func drawSettingsBadge(backgroundColor: NSColor) {
        let badgeRect = NSRect(x: 642, y: 650, width: 286, height: 286)
        let badgePath = NSBezierPath(ovalIn: badgeRect)
        NSColor.white.setFill()
        badgePath.fill()

        let gearConfig = NSImage.SymbolConfiguration(pointSize: 178, weight: .bold)
        if let gear = NSImage(systemSymbolName: "gearshape.fill", accessibilityDescription: nil)?
            .withSymbolConfiguration(gearConfig) {
            gear.isTemplate = true
            backgroundColor.set()
            gear.draw(
                in: NSRect(x: 696, y: 704, width: 178, height: 178),
                from: .zero,
                operation: .sourceOver,
                fraction: 1
            )
        }
    }

    private func deviceNamePrefix(from deviceName: String?) -> String {
        let cleaned = (deviceName ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)

        guard !cleaned.isEmpty else {
            return "?"
        }

        return String(cleaned.prefix(3)).uppercased()
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

    private func applyIcon(_ image: NSImage, to bundleURL: URL, resourceName: String) {
        let resourceURL = bundleURL
            .appendingPathComponent("Contents")
            .appendingPathComponent("Resources")
            .appendingPathComponent("\(resourceName).icns")

        do {
            try writeICNS(image: image, to: resourceURL)
            touch(bundleURL)
            importMetadata(for: bundleURL)
        } catch {
            // Keep Finder usable even if rewriting the bundle resource is denied.
        }

        NSWorkspace.shared.setIcon(image, forFile: bundleURL.path, options: [])
    }

    private func writeICNS(image: NSImage, to outputURL: URL) throws {
        let iconsetURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("SoundOutputToggle-\(UUID().uuidString).iconset")
        let icnsURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("SoundOutputToggle-\(UUID().uuidString).icns")

        try FileManager.default.createDirectory(at: iconsetURL, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: iconsetURL)
            try? FileManager.default.removeItem(at: icnsURL)
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
            let rendered = render(image: image, pixels: pixels)

            guard let tiff = rendered.tiffRepresentation,
                  let bitmap = NSBitmapImageRep(data: tiff),
                  let data = bitmap.representation(using: .png, properties: [:]) else {
                throw IconError.renderFailed
            }

            let suffix = scale == 1 ? "" : "@\(scale)x"
            let fileURL = iconsetURL.appendingPathComponent("icon_\(points)x\(points)\(suffix).png")
            try data.write(to: fileURL)
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
        process.arguments = ["-c", "icns", iconsetURL.path, "-o", icnsURL.path]
        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw IconError.iconutilFailed
        }

        try FileManager.default.createDirectory(
            at: outputURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        if FileManager.default.fileExists(atPath: outputURL.path) {
            try FileManager.default.removeItem(at: outputURL)
        }
        try FileManager.default.moveItem(at: icnsURL, to: outputURL)
    }

    private func render(image: NSImage, pixels: Int) -> NSImage {
        let size = NSSize(width: pixels, height: pixels)
        let rendered = NSImage(size: size)

        rendered.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: size), from: .zero, operation: .copy, fraction: 1)
        rendered.unlockFocus()

        return rendered
    }

    private func touch(_ bundleURL: URL) {
        try? FileManager.default.setAttributes(
            [.modificationDate: Date()],
            ofItemAtPath: bundleURL.path
        )
    }

    private func importMetadata(for bundleURL: URL) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/mdimport")
        process.arguments = [bundleURL.path]
        try? process.run()
    }
}

private enum IconError: Error {
    case renderFailed
    case iconutilFailed
}
