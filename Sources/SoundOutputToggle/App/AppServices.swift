import AppKit
import SwiftUI

final class AppServices {
    static let shared = AppServices()

    let audioService: AudioDeviceService
    let selectionStore: DeviceSelectionStore
    let toggleController: OutputToggleController
    let hudService: HUDService

    private var settingsWindow: NSWindow?

    private init() {
        audioService = AudioDeviceService()
        selectionStore = DeviceSelectionStore()
        toggleController = OutputToggleController(
            audioService: audioService,
            store: selectionStore
        )
        hudService = HUDService()
    }

    func toggleAndTerminate() {
        audioService.refresh()
        toggleController.toggle()
        let deviceName = toggleController.currentDeviceName()

        if selectionStore.showHUD {
            let isError = toggleController.lastError != nil
            hudService.show(
                title: isError ? "Switch Failed" : deviceName,
                subtitle: isError ? (toggleController.lastError ?? "Could not switch output") : "Sound Output",
                isError: isError,
                duration: isError ? 1.35 : 0.95
            ) {
                NSApp.terminate(nil)
            }
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            NSApp.terminate(nil)
        }
    }

    func openSettings() {
        audioService.startListeningForChanges()

        let window = settingsWindow ?? makeSettingsWindow()
        settingsWindow = window

        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func makeSettingsWindow() -> NSWindow {
        let view = SettingsView(
            audioService: audioService,
            selectionStore: selectionStore,
            toggleController: toggleController,
            hudService: hudService
        )
        .frame(width: 560, height: 460)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 460),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Sound Output Toggle Settings"
        window.contentViewController = NSHostingController(rootView: view)
        window.isReleasedWhenClosed = false
        return window
    }
}
