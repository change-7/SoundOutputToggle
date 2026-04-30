import AppKit
import SwiftUI

final class HUDService {
    private var panels: [NSPanel] = []
    private var activeToken = UUID()

    func show(
        title: String,
        subtitle: String,
        isError: Bool = false,
        duration: TimeInterval = 0.95,
        completion: @escaping () -> Void
    ) {
        activeToken = UUID()
        let token = activeToken
        closePanels()

        let screenFrames = NSScreen.screens.map(\.visibleFrame)
        let frames = screenFrames.isEmpty
            ? [NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)]
            : screenFrames

        let panels = frames.map { frame in
            makePanel(
                screenFrame: frame,
                title: title,
                subtitle: subtitle,
                isError: isError
            )
        }
        self.panels = panels

        panels.forEach { panel in
            panel.alphaValue = 0.01
            panel.orderFrontRegardless()
        }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.06
            panels.forEach { panel in
                panel.animator().alphaValue = 1
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self, panels] in
            guard let self, self.activeToken == token else { return }

            self.fadeOut(
                panels: panels,
                token: token
            ) {
                completion()
            }
        }
    }

    private func makePanel(screenFrame: NSRect, title: String, subtitle: String, isError: Bool) -> NSPanel {
        let size = NSSize(width: 360, height: 184)
        let origin = NSPoint(
            x: screenFrame.midX - size.width / 2,
            y: screenFrame.midY - size.height / 2 + 24
        )

        let panel = NSPanel(
            contentRect: NSRect(origin: origin, size: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        panel.ignoresMouseEvents = true
        panel.contentView = NSHostingView(
            rootView: OutputHUDView(
                title: title,
                subtitle: subtitle,
                isError: isError
            )
        )
        return panel
    }

    private func fadeOut(
        panels: [NSPanel],
        token: UUID,
        _ completion: @escaping () -> Void
    ) {
        guard !panels.isEmpty else {
            completion()
            return
        }

        let fadeGroup = DispatchGroup()

        for panel in panels {
            fadeGroup.enter()
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.16
                panel.animator().alphaValue = 0
            } completionHandler: {
                panel.close()
                fadeGroup.leave()
            }
        }

        fadeGroup.notify(queue: .main) { [weak self] in
            if self?.activeToken == token {
                self?.panels.removeAll()
                completion()
            }
        }
    }

    private func closePanels() {
        panels.forEach { $0.close() }
        panels.removeAll()
    }
}

private struct OutputHUDView: View {
    let title: String
    let subtitle: String
    let isError: Bool

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: isError ? "exclamationmark.triangle.fill" : "speaker.wave.2.fill")
                .font(.system(size: 42, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.white)

            VStack(spacing: 5) {
                Text(title)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.58)

                Text(subtitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.68))
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 22)
        .frame(width: 360, height: 184)
        .background {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(Color.black.opacity(0.72))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(Color.white.opacity(0.11), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.28), radius: 28, x: 0, y: 14)
    }
}
