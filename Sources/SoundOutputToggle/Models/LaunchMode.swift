import Foundation

enum LaunchMode {
    case toggle
    case settings
    case refreshIcon

    static func current(selectionStore: DeviceSelectionStore) -> LaunchMode {
        let arguments = Set(CommandLine.arguments.dropFirst())
        let environment = ProcessInfo.processInfo.environment

        if environment["SOT_LAUNCH_MODE"] == "refresh-icon" || arguments.contains("--refresh-icon") {
            return .refreshIcon
        }

        if environment["SOT_LAUNCH_MODE"] == "settings" {
            return .settings
        }

        if Bundle.main.bundleURL.lastPathComponent == "SoundOutputToggle Settings.app" {
            return .settings
        }

        if arguments.contains("--settings") || arguments.contains("settings") {
            return .settings
        }

        if !selectionStore.isConfigured {
            return .settings
        }

        return .toggle
    }
}
