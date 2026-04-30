import SwiftUI

struct SettingsView: View {
    @ObservedObject var audioService: AudioDeviceService
    @ObservedObject var selectionStore: DeviceSelectionStore
    @ObservedObject var toggleController: OutputToggleController
    let hudService: HUDService

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sound Output Toggle")
                        .font(.title2.weight(.semibold))
                    Text("Launch the toggle app to switch output, then quit immediately.")
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    audioService.refresh()
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
            }

            Divider()

            HStack {
                Label("Current: \(toggleController.currentSlot().displayName)", systemImage: "speaker.wave.2.fill")
                    .font(.headline)

                Text(toggleController.currentDeviceName())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Spacer()
            }

            Form {
                Picker("Output A", selection: binding(for: \.primaryUID)) {
                    Text("Choose a device").tag("")
                    ForEach(audioService.outputDevices) { device in
                        Text(device.name).tag(device.uid)
                    }
                }

                Picker("Output B", selection: binding(for: \.secondaryUID)) {
                    Text("Choose a device").tag("")
                    ForEach(audioService.outputDevices) { device in
                        Text(device.name).tag(device.uid)
                    }
                }

                Toggle("Also switch system alert sounds", isOn: $selectionStore.includeSystemSounds)
                Toggle("Show switching HUD", isOn: $selectionStore.showHUD)
            }

            HStack {
                Button("Set A to Current") {
                    selectionStore.primaryUID = audioService.defaultOutputUID
                }

                Button("Set B to Current") {
                    selectionStore.secondaryUID = audioService.defaultOutputUID
                }

                Spacer()

                Button("Toggle Now") {
                    toggleController.toggle()
                    let deviceName = toggleController.currentDeviceName()

                    if selectionStore.showHUD {
                        let isError = toggleController.lastError != nil
                        hudService.show(
                            title: isError ? "Switch Failed" : deviceName,
                            subtitle: isError ? (toggleController.lastError ?? "Could not switch output") : "Sound Output",
                            isError: isError
                        ) {}
                    }
                }
                .keyboardShortcut("t", modifiers: [.command])
                .disabled(!selectionStore.isConfigured)
            }

            if let error = toggleController.lastError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            } else if let message = toggleController.lastMessage {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                configurationStatus
                    .font(.caption)
                    .foregroundStyle(selectionStore.isConfigured ? Color.secondary : Color.red)
            }
        }
        .padding(24)
        .onAppear {
            audioService.refresh()
        }
    }

    private var configurationStatus: Text {
        if selectionStore.isConfigured {
            return Text("Configured. Launch SoundOutputToggle.app from Spotlight, Alfred, or Raycast.")
        }

        return Text("Choose two different output devices before toggling.")
    }

    private func binding(for keyPath: ReferenceWritableKeyPath<DeviceSelectionStore, String?>) -> Binding<String> {
        Binding {
            selectionStore[keyPath: keyPath] ?? ""
        } set: { newValue in
            selectionStore[keyPath: keyPath] = newValue.isEmpty ? nil : newValue
        }
    }
}
