# Audio Output Toggle — DMS Plugin

Quickly switch between audio outputs (speakers, headphones, etc.) from the DankBar.

## Features

- Single click to cycle through available audio outputs
- Dynamic icon: shows 🎧 `headset` for USB audio devices, 🔊 `speaker` for built-in
- Toast notification on switch with output name
- Works with any number of audio outputs (not just 2)

## Installation

```bash
# Clone into your DMS plugins directory
git clone https://github.com/lelabdev/dms-plugin-audio-output.git \
  ~/.config/DankMaterialShell/plugins/audioOutputToggle

# Enable the plugin
dms ipc plugins enable audioOutputToggle
```

## Usage

Click the widget in your DankBar to cycle to the next audio output.
Move it in **Settings → Bar widgets** to your preferred position.

## Uninstall

```bash
dms ipc plugins disable audioOutputToggle
rm -rf ~/.config/DankMaterialShell/plugins/audioOutputToggle
```

## Requirements

- DMS (DankMaterialShell) >= 0.3.0
- PipeWire (for Pipewire.defaultAudioSink / preferredDefaultAudioSink)

## License

MIT
