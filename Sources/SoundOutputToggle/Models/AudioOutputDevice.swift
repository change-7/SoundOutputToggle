import CoreAudio
import Foundation

struct AudioOutputDevice: Identifiable, Equatable {
    let id: String
    let audioDeviceID: AudioDeviceID
    let uid: String
    let name: String
    let canBeDefault: Bool

    init(audioDeviceID: AudioDeviceID, uid: String, name: String, canBeDefault: Bool) {
        self.id = uid
        self.audioDeviceID = audioDeviceID
        self.uid = uid
        self.name = name
        self.canBeDefault = canBeDefault
    }
}
