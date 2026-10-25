# Audio Output Toggle — DMS Plugin

Quickly switch between audio outputs (speakers, headphones, etc.) from the DankBar.

## Features

- Single click to cycle through the audio outputs you have enabled
- Right-click to open the output list and include or exclude devices from the cycle
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

- **Left-click** the widget to cycle to the next enabled audio output.
- **Right-click** the widget to open the output list. Click a device card to
  include or exclude it from the cycle. Clicking a card does not change the
  current output.
- Devices marked with the highlighted card color are included in the cycle;
  cards with the normal inactive surface are excluded.
- Exclusions are stored by device name in the plugin settings. They survive DMS
  restarts and temporary disconnects, and newly connected devices start
  enabled.
- If every output is excluded, left-click does nothing and shows a reminder to
  re-enable an output from the right-click panel.

Move the widget in **Settings → Bar widgets** to your preferred position.

## Uninstall

```bash
dms ipc plugins disable audioOutputToggle
rm -rf ~/.config/DankMaterialShell/plugins/audioOutputToggle
```

## Requirements

- DMS (DankMaterialShell) >= 2.0.0
- PipeWire (for the DMS audio backend)

## License

MIT
