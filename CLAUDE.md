# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A [Quickshell](https://quickshell.outfoxxed.me/) desktop shell config written in QML, targeting Hyprland on Wayland. It renders a "dynamic island" — a centered, top-anchored rounded panel that morphs between views (clock, media player, notifications, control center, launcher, etc.). The config directory name is `island`, so it runs as:

```sh
qs -c island        # run
qs -c island -n     # daemonless / no-reload check
```

`shell.qml` is the entry point (referenced by the `//@ pragma UseQApplication` root). There is no build/lint/test tooling — QML is loaded and hot-reloaded live by Quickshell. `.qmlls.ini` is a symlink into Quickshell's VFS to power the `qmlls` language server; it is gitignored along with `Config/`.

## Module import scheme

Quickshell maps the config root to the `qs` import namespace. Directories become sub-modules automatically (no `qmldir` files):

- `qs.Core` → `Core/` — base components + the `Config` singleton
- `qs.Services` → `Services/` — singletons wrapping system state
- `qs.Modules`, `qs.Modules.ControlCenter`, etc. → `Modules/` and its subfolders (imported `as` an alias when nested)

Singletons are declared with `pragma Singleton` and used by type name (e.g. `Config.island.height`, `MprisService.onTrackChanged`). Reusable QML types just live as `.qml` files and are referenced by filename.

## Core architecture: the view system

The island is a `StackView` of **views** that replace each other with a blur/scale transition. Understanding this flow requires reading `Bar.qml`, `Core/View.qml`, and any `Modules/*.qml`.

- **`Core/View.qml`** is the base type every top-level view extends (`View { ... }`). It is a `FocusScope` exposing:
  - `dismissable` — whether ambient events (workspace change, volume, track change, notifications) may auto-swap this view out. Interactive views set it `false`.
  - `focused` — drives `HyprlandFocusGrab` in `shell.qml` (keyboard grab + click-outside-to-close).
  - `displayInFullscreen` — promotes the layershell to `WlrLayer.Overlay`.
  - `popups`, and legacy signals `closeRequested` / `viewChangeRequested(view)` / `defaultViewChangeRequested(view)`. Views emit these; `Bar.qml` wires them up.

- **`Bar.qml`** owns the StackView and holds every view as a `Component` property (`clock`, `player`, `controlCenter`, `launcher`, …). Navigation goes through `openView(view, params)` / `openDefaultView()`, which `content.replace(...)` into the stack. **To add a view:** create `Modules/<Name>.qml` (or a subfolder) extending `View`, add a `property Component <name>: <Name> {}` line in `Bar.qml`, and reference it by the string key `"<name>"`.

- **Ambient triggers** live in `Bar.qml` as `Connections` blocks: track change → `player`, volume → `volume`, workspace focus → `workspaces`, `NotificationService` notification → `notification`, LocalSend upload → `localsend`, file drag → `localsend`. Each is gated on `content.currentView.dismissable` so it won't interrupt an interactive view.

- **External control:** an `IpcHandler` with target `"bar"` exposes `toggle(view)`. Trigger from anywhere with `qs -c island ipc call bar toggle <view>` (bind these in Hyprland).

## Config & theming

`Core/Config.qml` is the single source of truth for user settings. Each setting group is a `FileView` over a JSON file in `Config/` with a `JsonAdapter` defining schema + defaults. Files are written back on change and hot-reloaded (`watchChanges: true`), so editing `Config/*.json` at runtime updates the UI live, and missing files are recreated from defaults.

Colorschemes are separate: `Config/theme.json` names a scheme (e.g. `"Moonfly"`), and `Config.colorscheme` is a second `FileView` whose path is repointed to `Themes/<scheme>.json` when the name changes. Reference colors as `Config.colorscheme.bg` / `.fg` / `.accent` / `.accentAlt` etc. Add a scheme by dropping a new `Themes/<Name>.json` with the same keys.

> Note: `Core/ThemeLoader.qml` is a legacy/duplicate colorscheme singleton with a different key set (`bg2`/`bg3`/`bg4`). New code should use `Config.colorscheme`, not `ThemeLoader`.

Use `Core/ThemedText.qml` (font from `Config.theme`) and `Core/ScrollingText.qml` for text so typography stays centralized.

## Services

Singletons in `Services/` wrap external systems and expose reactive properties/signals for views to bind to:

- `MprisService` — media players (emits `trackChanged`).
- `NotificationService` — wraps `NotificationServer`; `muted` gates OSD popups; `notify()` shells out to `notify-send`.
- `CavaService` — spawns `cava` as a `Process`, feeds it config via stdin, parses raw stdout into a `values` array for the visualizer.
- `WallpaperService` — drives `awww`/`awww-daemon` (images) and `mpvpaper` (video); folder models from `Config.wallpaper.staticWallpaperFolder`; video list via `Helpers/list_walls.py`.
- `LocalSendService`, `LyricsService`, `DateService`.

External CLI tools these depend on (must be on PATH): `cava`, `awww` + `awww-daemon`, `mpvpaper`, `notify-send`, plus `python3` for helpers.

## Conventions

- Views size themselves via `implicitWidth`/`implicitHeight` (usually content + `Config.island.padding`/`.height`); `Bar.qml` animates the island resize with `Behavior on implicit{Width,Height}`.
- Reach system state through a Service singleton or `Config`, not by spawning `Process` directly inside a view — put the process in a service.
- Commit style is Conventional Commits (`feat:`, `fix:`, `refactor:`, `chore:`, `docs:`, with optional scope e.g. `fix(themes):`).
