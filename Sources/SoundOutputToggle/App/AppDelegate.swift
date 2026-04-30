import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let services = AppServices.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        services.audioService.refresh()

        switch LaunchMode.current(selectionStore: services.selectionStore) {
        case .toggle:
            NSApp.setActivationPolicy(.accessory)
            services.toggleAndTerminate()
        case .settings:
            NSApp.setActivationPolicy(.regular)
            services.openSettings()
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
