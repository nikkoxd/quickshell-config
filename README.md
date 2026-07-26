# Quickshell Configuration

## Prerequisites

Install dependencies with pacman:

```bash
sudo pacman -S hyprland quickshell qt6-multimedia-ffmpeg gpu-screen-recorder keepassxc cava
```

For lyrics, either [build my fork of lrcsnc from source](https://github.com/nikkoxd/lrcsnc) or install original version with pacman: `sudo pacman -S lrcsnc`

For LocalSend integration, [build my cli from source](https://github.com/nikkoxd/localsend-cli)

You can clone the config either into `~/.config/quickshell` and run it with `qs`,
or clone it into `~/.config/quickshell/{custom_name}` and run it with `qs -c {custom_name}`
to be able to run it alongside other configs, such as [quickshell-overview](https://github.com/Shanu-Kumawat/quickshell-overview).

## Features

- App launcher - `qs ipc call bar toggle launcher` 
    - Password manager (KeePassXC)
    - Clipboard history
    - Emoji picker
    - MPRIS controls
    - Theme selector
    - Calculator
- Control center - `qs ipc call bar toggle controlCenter`
    - Audio mixer
    - Bluetooth controls (soon™)
    - Notifications + mute toggle
- Wallpaper picker - `qs ipc call bar toggle wallpaperSelector`
    - Static wallpapers
    - Video wallpapers /w Wallpaper Engine integration
    - Fancy transitions (WIP)
- LocalSend integration
    - Drag any file onto the dynamic island to send a file
      to a device on the local network
- Screenshots + screen recording - `qs ipc call bar toggle recorder`
    - Screenshots (soon™)
    - Video recording
    - Replay recording (like ShadowPlay)

## TODO

- [x] Add player controls
- [x] Add system tray
- [x] Add notification OSD
- [x] Pause notification dismiss on hover
- [x] Add an application launcher
- [x] Add a calculator
- [x] Add a notification center
- [x] Add a theme selector
- [x] Add a wallpaper selector
- [x] Add Localsend support
- [x] Add a clipboard manager
- [x] Add an emoji picker
- [ ] Add a bluetooth menu
- [x] Add a settings menu
- [ ] Add a lockscreen
- [ ] Add power menu?
- [ ] Rewrite the StackView navigation
- [x] Rewrite the wallpaper service
- [ ] Add more transition effects
- [ ] Add an install script
- [ ] DO CLEANUP
