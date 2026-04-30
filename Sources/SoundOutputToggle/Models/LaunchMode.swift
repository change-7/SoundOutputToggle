import Foundation

enum LaunchMode {
    case toggle
    case settings

    static func current(selectionStore: DeviceSelectionStore) -> LaunchMode {
        let arguments = Set(CommandLine.arguments.dropFirst())
        let environment = ProcessInfo.processInfo.environment

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
