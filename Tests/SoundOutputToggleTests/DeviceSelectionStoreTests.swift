import Foundation
@testable import SoundOutputToggle
import XCTest

final class DeviceSelectionStoreTests: XCTestCase {
    func testConfigurationRequiresTwoDifferentOutputs() {
        withStore { store in
            XCTAssertFalse(store.isConfigured)

            store.primaryUID = "speaker-a"
            store.secondaryUID = "speaker-a"
            XCTAssertFalse(store.isConfigured)

            store.secondaryUID = "speaker-b"
            XCTAssertTrue(store.isConfigured)
        }
    }

    func testSettingsPersistToDefaults() {
        let suiteName = "SoundOutputToggleTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let store = DeviceSelectionStore(defaults: defaults)
        store.primaryUID = "speaker-a"
        store.secondaryUID = "speaker-b"
        store.includeSystemSounds = false
        store.showHUD = false

        let restoredStore = DeviceSelectionStore(defaults: defaults)
        XCTAssertEqual(restoredStore.primaryUID, "speaker-a")
        XCTAssertEqual(restoredStore.secondaryUID, "speaker-b")
        XCTAssertFalse(restoredStore.includeSystemSounds)
        XCTAssertFalse(restoredStore.showHUD)
    }

    private func withStore(_ body: (DeviceSelectionStore) -> Void) {
        let suiteName = "SoundOutputToggleTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        body(DeviceSelectionStore(defaults: defaults))
    }
}
