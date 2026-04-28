import Combine
import Foundation

final class DeviceSelectionStore: ObservableObject {
    @Published var primaryUID: String? {
        didSet { defaults.set(primaryUID, forKey: Keys.primaryUID) }
    }

    @Published var secondaryUID: String? {
        didSet { defaults.set(secondaryUID, forKey: Keys.secondaryUID) }
    }

    @Published var includeSystemSounds: Bool {
        didSet { defaults.set(includeSystemSounds, forKey: Keys.includeSystemSounds) }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = UserDefaults(suiteName: "com.pdg.SoundOutputToggle.shared") ?? .standard) {
        self.defaults = defaults
        primaryUID = defaults.string(forKey: Keys.primaryUID)
        secondaryUID = defaults.string(forKey: Keys.secondaryUID)
        includeSystemSounds = defaults.object(forKey: Keys.includeSystemSounds) as? Bool ?? true
    }

    var isConfigured: Bool {
        guard let primaryUID, let secondaryUID else {
            return false
        }
        return primaryUID != secondaryUID
    }

    private enum Keys {
        static let primaryUID = "primaryOutputDeviceUID"
        static let secondaryUID = "secondaryOutputDeviceUID"
        static let includeSystemSounds = "includeSystemSounds"
    }
}
