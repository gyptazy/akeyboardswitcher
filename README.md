# AKeyboardSwitcher

A macOS menu bar app for quickly moving paired Apple Magic Keyboard, Mouse and Trackpad between Macs.

## Build

Requires macOS 13+ and the Swift toolchain (Command Line Tools are enough).

```sh
./build-app.sh
open build/AKeyboardSwitcher.app
```

On first launch macOS asks for Bluetooth permission. Allow it.

## Usage

Click the keyboard icon in the menu bar to see your paired input devices:

- **Connect**: connect the device to this Mac.
- **Release**: disconnect the device from this Mac so another Mac can take it.
- **Connect All / Release All**: do the same for every listed device.
- **Show all paired devices**: also list non-input devices (headphones etc.).

A Bluetooth keyboard, mouse or trackpad can only be connected to one host at a time. To move a device,
run the app on both Macs. Press **Release** on the Mac that has the device, then **Connect** on the Mac that should get it.
