# AKeyboardSwitcher

[![Build](https://github.com/gyptazy/akeyboardswitcher/actions/workflows/build.yml/badge.svg)](https://github.com/gyptazy/akeyboardswitcher/actions/workflows/build.yml)

<p align="center">
  <img src="https://cdn.gyptazy.com/img/akeyboardswitcher.jpg" alt="AKeyboardSwitcher logo" width="256">
</p>

A macOS menu bar app for quickly moving paired Apple Magic Keyboard, Mouse and Trackpad between Macs.

## Motivation

Working from my home office, I share a single Apple Magic Keyboard and Magic Mouse between my corporate Mac
and my personal Mac. Until now, the easiest way to switch the active device was to plug in the cable on
the Mac that should take over the keyboard and mouse. With AKeyboardSwitcher this gets much easier: you
simply need to click :)

## Screenshot

<p align="center">
  <img src="https://cdn.gyptazy.com/img/akeyboardswitcher-screenshot.jpg" alt="AKeyboardSwitcher screenshot" width="500">
</p>

For quick changes, you can also group multiple devices together that can be connected or released (even by hotkeys).

<p align="center">
  <img src="https://cdn.gyptazy.com/img/akeyboardswitcher-screenshot-device-grouping.jpg" alt="AKeyboardSwitcher device groups screenshot" width="500">
</p>


## Features

- Overview of all or only connected devices
- Quickly connect/release single Bluetooth devices
- Group devices together to quickly connect/release them
- Hotkey support

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
- **Options…**: set up a device group and global hotkeys (see below).

### Device group and hotkeys

In **Options…** you can give your group a name and select the devices that belong to it, e.g. your
Magic Keyboard and Magic Mouse. The group then shows up in the menu with its own **Connect** and
**Release** buttons, and can be switched from anywhere with these global hotkeys:

| Hotkey | Action |
| --- | --- |
| <kbd>⌘ Command</kbd> + <kbd>⌥ Option</kbd> + <kbd>C</kbd> | Connect all devices in the group |
| <kbd>⌘ Command</kbd> + <kbd>⌥ Option</kbd> + <kbd>R</kbd> | Release all devices in the group |

The hotkeys can be turned off in **Options…**. While they're on, they take priority over the same shortcuts in
other apps (e.g. Finder's "Copy as Pathname"). If another app already reserved them, Options shows a warning.

A Bluetooth keyboard, mouse or trackpad can only be connected to one host at a time. To move a device,
run the app on both Macs. Press **Release** on the Mac that has the device, then **Connect** on the Mac that should get it.
