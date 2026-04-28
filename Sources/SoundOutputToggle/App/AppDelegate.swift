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
            services.iconService.updateToggleAppIcon(
                slot: services.toggleController.currentSlot(),
                deviceName: services.toggleController.currentDeviceName()
            )
            services.openSettings()
        case .refreshIcon:
            NSApp.setActivationPolicy(.accessory)
            services.refreshIconAndTerminate()
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
