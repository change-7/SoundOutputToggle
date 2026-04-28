import Combine
import CoreAudio
import Foundation

final class AudioDeviceService: ObservableObject {
    @Published private(set) var outputDevices: [AudioOutputDevice] = []
    @Published private(set) var defaultOutputUID: String?

    private var listenerInstalled = false

    init() {
        refresh()
    }

    func refresh() {
        outputDevices = (try? loadOutputDevices()) ?? []
        defaultOutputUID = try? defaultOutputDevice()?.uid
    }

    func defaultOutputDevice() throws -> AudioOutputDevice? {
        let deviceID = try getDefaultOutputDeviceID()
        return try makeOutputDevice(from: deviceID)
    }

    func device(uid: String) -> AudioOutputDevice? {
        if let cached = outputDevices.first(where: { $0.uid == uid }) {
            return cached
        }

        refresh()
        return outputDevices.first(where: { $0.uid == uid })
    }

    func setDefaultOutputDevice(uid: String, includeSystemSounds: Bool) throws {
        guard let target = device(uid: uid) else {
            throw AudioDeviceError.deviceUnavailable
        }

        guard target.canBeDefault else {
            throw AudioDeviceError.deviceCannotBeDefault(target.name)
        }

        try setDevice(target.audioDeviceID, selector: kAudioHardwarePropertyDefaultOutputDevice)

        if includeSystemSounds {
            try setDevice(target.audioDeviceID, selector: kAudioHardwarePropertyDefaultSystemOutputDevice)
        }

        refresh()
    }

    func startListeningForChanges() {
        guard !listenerInstalled else {
            return
        }

        listenerInstalled = true
        addSystemListener(selector: kAudioHardwarePropertyDevices)
        addSystemListener(selector: kAudioHardwarePropertyDefaultOutputDevice)
        addSystemListener(selector: kAudioHardwarePropertyDefaultSystemOutputDevice)
    }

    private func addSystemListener(selector: AudioObjectPropertySelector) {
        var address = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        AudioObjectAddPropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            DispatchQueue.main
        ) { [weak self] _, _ in
            self?.refresh()
        }
    }

    private func loadOutputDevices() throws -> [AudioOutputDevice] {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var dataSize: UInt32 = 0
        try check(AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &dataSize
        ))

        let count = Int(dataSize) / MemoryLayout<AudioDeviceID>.size
        var deviceIDs = Array(repeating: AudioDeviceID(0), count: count)

        try check(AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &dataSize,
            &deviceIDs
        ))

        return deviceIDs.compactMap { deviceID in
            guard hasOutputStreams(deviceID: deviceID) else {
                return nil
            }
            return try? makeOutputDevice(from: deviceID)
        }
        .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private func makeOutputDevice(from deviceID: AudioDeviceID) throws -> AudioOutputDevice {
        let uid = try stringProperty(
            objectID: deviceID,
            selector: kAudioDevicePropertyDeviceUID,
            scope: kAudioObjectPropertyScopeGlobal
        )
        let name = try stringProperty(
            objectID: deviceID,
            selector: kAudioObjectPropertyName,
            scope: kAudioObjectPropertyScopeGlobal
        )

        return AudioOutputDevice(
            audioDeviceID: deviceID,
            uid: uid,
            name: name,
            canBeDefault: canBeDefaultOutputDevice(deviceID: deviceID)
        )
    }

    private func getDefaultOutputDeviceID() throws -> AudioDeviceID {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var deviceID = AudioDeviceID(0)
        var dataSize = UInt32(MemoryLayout<AudioDeviceID>.size)

        try check(AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &dataSize,
            &deviceID
        ))

        return deviceID
    }

    private func setDevice(_ deviceID: AudioDeviceID, selector: AudioObjectPropertySelector) throws {
        var address = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var mutableDeviceID = deviceID
        let dataSize = UInt32(MemoryLayout<AudioDeviceID>.size)

        try check(AudioObjectSetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            dataSize,
            &mutableDeviceID
        ))
    }

    private func stringProperty(
        objectID: AudioObjectID,
        selector: AudioObjectPropertySelector,
        scope: AudioObjectPropertyScope
    ) throws -> String {
        var address = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: scope,
            mElement: kAudioObjectPropertyElementMain
        )
        var value: Unmanaged<CFString>?
        var dataSize = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)

        let status = withUnsafeMutablePointer(to: &value) { pointer in
            AudioObjectGetPropertyData(
                objectID,
                &address,
                0,
                nil,
                &dataSize,
                pointer
            )
        }

        try check(status)

        guard let string = value?.takeUnretainedValue() else {
            throw AudioDeviceError.missingStringProperty
        }

        return string as String
    }

    private func hasOutputStreams(deviceID: AudioDeviceID) -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreams,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        var dataSize: UInt32 = 0
        let status = AudioObjectGetPropertyDataSize(deviceID, &address, 0, nil, &dataSize)
        return status == noErr && dataSize > 0
    }

    private func canBeDefaultOutputDevice(deviceID: AudioDeviceID) -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceCanBeDefaultDevice,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )

        guard AudioObjectHasProperty(deviceID, &address) else {
            return true
        }

        var value: UInt32 = 0
        var dataSize = UInt32(MemoryLayout<UInt32>.size)
        let status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &dataSize, &value)

        return status == noErr ? value != 0 : true
    }

    private func check(_ status: OSStatus) throws {
        guard status == noErr else {
            throw AudioDeviceError.coreAudioStatus(status)
        }
    }
}

enum AudioDeviceError: LocalizedError {
    case coreAudioStatus(OSStatus)
    case deviceUnavailable
    case deviceCannotBeDefault(String)
    case devicesNotConfigured
    case missingStringProperty

    var errorDescription: String? {
        switch self {
        case .coreAudioStatus(let status):
            return "CoreAudio returned status \(status)."
        case .deviceUnavailable:
            return "The selected output device is not connected."
        case .deviceCannotBeDefault(let name):
            return "\(name) cannot be used as the default output device."
        case .devicesNotConfigured:
            return "Choose two output devices in Settings first."
        case .missingStringProperty:
            return "Could not read the audio device name or UID."
        }
    }
}
