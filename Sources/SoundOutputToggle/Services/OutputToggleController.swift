import AppKit
import Combine

final class OutputToggleController: ObservableObject {
    @Published private(set) var lastMessage: String?
    @Published private(set) var lastError: String?

    private let audioService: AudioDeviceService
    private let store: DeviceSelectionStore

    init(audioService: AudioDeviceService, store: DeviceSelectionStore) {
        self.audioService = audioService
        self.store = store
    }

    func toggle() {
        guard let targetUID = nextTargetUID() else {
            lastError = AudioDeviceError.devicesNotConfigured.localizedDescription
            NSSound.beep()
            return
        }

        do {
            try audioService.setDefaultOutputDevice(
                uid: targetUID,
                includeSystemSounds: store.includeSystemSounds
            )
            let name = audioService.device(uid: targetUID)?.name ?? "selected device"
            lastError = nil
            lastMessage = "Switched to \(name)."
        } catch {
            lastError = error.localizedDescription
            NSSound.beep()
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

    private func nextTargetUID() -> String? {
        guard store.isConfigured,
              let primaryUID = store.primaryUID,
              let secondaryUID = store.secondaryUID else {
            return nil
        }

        if audioService.defaultOutputUID == primaryUID {
            return secondaryUID
        }

        return primaryUID
    }
}
