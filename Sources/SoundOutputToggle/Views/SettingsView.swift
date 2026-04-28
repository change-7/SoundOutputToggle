import SwiftUI

struct SettingsView: View {
    @ObservedObject var audioService: AudioDeviceService
    @ObservedObject var selectionStore: DeviceSelectionStore
    @ObservedObject var toggleController: OutputToggleController
    let iconService: IconService

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
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
            }

            HStack {
                Button("Set A to Current") {
                    selectionStore.primaryUID = audioService.defaultOutputUID
                    iconService.updateToggleAppIcon(
                        slot: toggleController.currentSlot(),
                        deviceName: toggleController.currentDeviceName()
                    )
                }

                Button("Set B to Current") {
                    selectionStore.secondaryUID = audioService.defaultOutputUID
                    iconService.updateToggleAppIcon(
                        slot: toggleController.currentSlot(),
                        deviceName: toggleController.currentDeviceName()
                    )
                }

                Spacer()

                Button("Toggle Now") {
                    let slot = toggleController.toggle() ?? toggleController.currentSlot()
                    iconService.updateToggleAppIcon(
                        slot: slot,
                        deviceName: toggleController.currentDeviceName()
                    )
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
            iconService.updateToggleAppIcon(
                slot: toggleController.currentSlot(),
                deviceName: toggleController.currentDeviceName()
            )
        }
        .onChange(of: selectionStore.primaryUID) { _ in
            iconService.updateToggleAppIcon(
                slot: toggleController.currentSlot(),
                deviceName: toggleController.currentDeviceName()
            )
        }
        .onChange(of: selectionStore.secondaryUID) { _ in
            iconService.updateToggleAppIcon(
                slot: toggleController.currentSlot(),
                deviceName: toggleController.currentDeviceName()
            )
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
