# SoundOutputToggle

One-shot macOS output switcher.

Build:

```bash
./script/build_and_run.sh --verify
```

Generated apps:

- `dist/SoundOutputToggle.app`: toggles between Output A and Output B, then exits.
- `dist/SoundOutputToggle Settings.app`: chooses Output A and Output B.

For Spotlight, Alfred, or Raycast, copy both generated apps into `/Applications`
or another indexed Applications folder. Launch `SoundOutputToggle Settings` once
to choose the two output devices, then launch `SoundOutputToggle` whenever you
want to switch outputs.

Install to the current user's Applications folder:

```bash
./script/build_and_run.sh install
```

Install to the system Applications folder:

```bash
./script/build_and_run.sh install-system
```
