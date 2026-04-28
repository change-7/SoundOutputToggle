import AppKit
import Combine
import Foundation

final class OutputToggleController: ObservableObject {
    @Published private(set) var lastMessage: String?
    @Published private(set) var lastError: String?

    private let audioService: AudioDeviceService
    private let store: DeviceSelectionStore

    init(audioService: AudioDeviceService, store: DeviceSelectionStore) {
        self.audioService = audioService
        self.store = store
    }

    @discardableResult
    func toggle() -> OutputSlot? {
        guard let target = nextTarget() else {
            lastError = AudioDeviceError.devicesNotConfigured.localizedDescription
            NSSound.beep()
            return nil
        }

        do {
            try audioService.setDefaultOutputDevice(
                uid: target.uid,
                includeSystemSounds: store.includeSystemSounds
            )
            let name = audioService.device(uid: target.uid)?.name ?? "selected device"
            lastError = nil
            lastMessage = "Switched to \(name)."
            return target.slot
        } catch {
            lastError = error.localizedDescription
            NSSound.beep()
            return nil
        }
    }

    func currentSlot() -> OutputSlot {
        guard let currentUID = audioService.defaultOutputUID else {
            return .unknown
        }

        if currentUID == store.primaryUID {
            return .primary
        }
        if currentUID == store.secondaryUID {
            return .secondary
        }
        return .unknown
    }

    func currentDeviceName() -> String {
        guard let currentUID = audioService.defaultOutputUID else {
            return "No output device"
        }
        return audioService.device(uid: currentUID)?.name ?? "Unknown output device"
    }

    private func nextTarget() -> (uid: String, slot: OutputSlot)? {
        guard store.isConfigured,
              let primaryUID = store.primaryUID,
              let secondaryUID = store.secondaryUID else {
            return nil
        }

        if audioService.defaultOutputUID == primaryUID {
            return (secondaryUID, .secondary)
        }

        return (primaryUID, .primary)
    }
}
