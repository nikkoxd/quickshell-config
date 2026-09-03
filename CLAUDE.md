# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A [Quickshell](https://quickshell.outfoxxed.me/) desktop shell config written in QML, targeting Hyprland on Wayland. It renders a "dynamic island" — a centered, top-anchored rounded panel that morphs between views (clock, media player, notifications, control center, launcher, etc.). The config directory name is `island`, so it runs as:

```sh
qs -c island        # run
qs log -c island    # view logs of the running instance
```

`shell.qml` is the entry point (referenced by the `//@ pragma UseQApplication` root). There is no build/lint/test tooling — QML is loaded and hot-reloaded live by Quickshell. `.qmlls.ini` is a symlink into Quickshell's VFS to power the `qmlls` language server; it is gitignored along with `Config/`.

## Module import scheme

Quickshell maps the config root to the `qs` import namespace. Directories become sub-modules automatically (no `qmldir` files):

- `qs.Core` → `Core/` — base components + the `Config` singleton
- `qs.Services` → `Services/` — singletons wrapping system state
- `qs.Modules`, `qs.Modules.Notifications`, etc. → `Modules/` and its subfolders (imported `as` an alias when nested)

Singletons are declared with `Singleton {}` imported from `Quickshell` and `pragma Singleton` at the top of the file and used by type name (e.g. `Config.island.height`, `MprisService.onTrackChanged`). Reusable QML types just live as `.qml` files and are referenced by filename.

## Core architecture: the view system

The island is a `StackView` of **views** that replace each other with a blur/scale transition. Understanding this flow requires reading `Bar.qml`, `Core/View.qml`, and any `Modules/*.qml`.

- **`Core/View.qml`** is the base type every top-level view extends (`View { ... }`). It is a `FocusScope` exposing:
  - `dismissable` — whether ambient events (workspace change, volume, track change, notifications) may auto-swap this view out. Interactive views set it `false`.
  - `focused` — drives `HyprlandFocusGrab` in `shell.qml` (keyboard grab + click-outside-to-close).
  - `displayInFullscreen` — promotes the layershell to `WlrLayer.Overlay`.
  - `popups`, and legacy signals `closeRequested` / `viewChangeRequested(view)` / `defaultViewChangeRequested(view)`. Views emit these; `Bar.qml` wires them up.

- **`Bar.qml`** owns the StackView and holds every view as a `Component` property (`clock`, `player`, `notifications`, `launcher`, …). Navigation goes through `openView(view, params)` / `openDefaultView()`, which `content.replace(...)` into the stack. **To add a view:** create `Modules/<Name>.qml` (or a subfolder) extending `View`, add a `property Component <name>: <Name> {}` line in `Bar.qml`, and reference it by the string key `"<name>"`.

- **Ambient triggers** live in `Bar.qml` as `Connections` blocks: track change → `player`, volume → `volume`, workspace focus → `workspaces`, `NotificationService` notification → `notification`, LocalSend upload → `localsend`, file drag → `localsend`. Each is gated on `content.currentView.dismissable` so it won't interrupt an interactive view.

- **External control:** an `IpcHandler` with target `"bar"` exposes `toggle(view)`. Trigger from anywhere with `qs -c island ipc call bar toggle <view>` (bind these in Hyprland).

## Config & theming

`Core/Config.qml` is the single source of truth for user settings. Each setting group is a `FileView` over a JSON file in `Config/` with a `JsonAdapter` defining schema + defaults. Files are written back on change and hot-reloaded (`watchChanges: true`), so editing `Config/*.json` at runtime updates the UI live, and missing files are recreated from defaults.

Colorschemes are separate: `Config/theme.json` names a scheme (e.g. `"Moonfly"`), and `Config.colorscheme` is a second `FileView` whose path is repointed to `Themes/<scheme>.json` when the name changes. Reference colors as `Config.colorscheme.bg` / `.fg` / `.accent` / `.accentAlt` etc. Add a scheme by dropping a new `Themes/<Name>.json` with the same keys.

> Note: `Core/ThemeLoader.qml` is a legacy/duplicate colorscheme singleton with a different key set (`bg2`/`bg3`/`bg4`). New code should use `Config.colorscheme`, not `ThemeLoader`.

Never hardcode a color, font or radius in a view — read it off `Config` through the shared components below.

`Modules/Settings/` is the GUI over those JSON files. **To add a settings page:** create `Modules/Settings/Settings<Name>.qml` as a `ColumnLayout` of `SettingsOption`s (grouped under `SettingsSection`s), add a value to the `Settings.Tab` enum plus the instance in `Settings.qml`, and a `SettingsTab` in `SettingsSidebar.qml`.

## Core components

`Core/` also holds the reusable widgets every view is built from. Prefer these over raw `QtQuick.Controls` or hand-rolled rectangles — they already pull colors from `Config.colorscheme`, radii from `Config.island.radius`, and fonts from `Config.theme`, so a new colorscheme or font size propagates for free.

Text:

- `ThemedText` — the `Text` replacement (font from `Config.theme`, color `Config.colorscheme.fg`). `icon: true` switches the family to Phosphor so `text` is a ligature name (`ThemedText { icon: true; text: "push-pin" }`); `isHeading: true` bumps the size by 1.15.
- `ScrollingText` — `ThemedText` clipped to `maxWidth` that auto-scrolls back and forth when the text overflows, restarting on every `text` change. Used for track titles.

Controls (all emit a signal rather than mutating their own state, so the caller owns the value):

- `IconButton` — square Phosphor-glyph button, also usable as a toggle: `active` swaps in `activeIcon` and the accent background. `clicked(button)` carries the mouse button, so right-click menus hang off the same component.
- `Toggle` — the switch. Emits `toggled(checked)` only on real user input; it deliberately does *not* watch `checked`, because a binding resolving at load would otherwise write the config back over itself.
- `Slider` — horizontal or vertical (`vertical: true`) fill slider with a hover preview. Optional icon via `icon`, drawn as a Phosphor glyph (`iconAsText: true`, default) or a themed app icon (`iconAsText: false`, resolved through `Quickshell.iconPath`); it recolors itself once the fill grows behind it.
- `TextField` — themed `Controls.TextField` with `pill`, `borderless`, `radius` and `horizontalPadding` knobs.
- `SegmentPill` — segmented control over `options` (a list of `{ label, value }`) with a highlight that slides onto `current`; emits `selected(value)`. `icons: true` renders the labels as glyphs.
- `Dropdown` — single-select dropdown over the same option shape (plain strings also work); emits `selected(value)`. The list floats and the root stays trigger-height, so opening one never reflows the layout — but a clipping container has to grow by `listHeight` to reveal it, and `collapse()` closes it.
- `PopupMenu` — `PopupWindow` context menu built from a `menu` list of `{ text, triggered, isSeparator }`; `showMenu()` opens it, `closeRequested` fires on activation.

Chrome and helpers:

- `ViewHeader` — the title row every non-default view uses: `text` on the left, children going into the right-hand action `Row` (its `default` property).
- `Cava` / `CavaBars` — the two visualizer renderings fed by `CavaService`. `Cava` paints a gradient curve across the island background, `CavaBars` a few inline bars next to text; each is `visible` only for its own `Config.visualizer.mode` (`"background"` / `"bars"`), so both can be instantiated unconditionally.
- `RecordingIndicator` — the blinking dot shown while `RecordingService.recording`. `shown` is the extra gate default views use to keep it clear of the inline visualizer.
- `CommandQueue` — runs a list of shell commands one at a time through `sh -c`, warning on stderr with `label` as the prefix. Used for user-configured hook commands.

## Services

Singletons in `Services/` wrap external systems and expose reactive properties/signals for views to bind to:

- `MprisService` — media players (emits `trackChanged`); also exposes `position`/`length`, refreshed by a timer since `MprisPlayer.position` is not self-updating.
- `NotificationService` — wraps `NotificationServer`; `muted` gates OSD popups; `notify()` shells out to `notify-send`.
- `CavaService` — spawns `cava` as a `Process`, feeds it config via stdin, parses raw stdout into a `values` array for the visualizer.
- `WallpaperService` — drives `awww`/`awww-daemon` (images) and `mpvpaper` (video); folder models from `Config.wallpaper.staticWallpaperFolder`; video list via `Helpers/list_walls.py`.
- `LyricsService` — fetches the whole timestamped LRC once per track via `Helpers/lyrics.py fetch` (lrclib.net, cached under `$XDG_CACHE_HOME/island/lyrics/`); exposes `state`, `lines`, `plain`, `currentIndex`, `currentText` and `seek()`. The active line is derived in QML from `MprisService.position`, not by re-spawning the helper.
- `DockService` — builds the dock model: one item per application (`{ appId, entry, toplevels, pinned }`), pinned apps first in the order saved to `Config.dock.pinned`, then running-but-unpinned apps. Owns `move()`/`persistOrder()` (drag reorder; only pinned positions survive a restart), `setPinned()`/`togglePin()`, and `activate()`/`launch()`/`close()`.
- `IrisService` / `MatugenService` — the two colorscheme generators, each a no-op unless `Config.theme.colorscheme` names it. Both are called from `WallpaperService.generateColors()`, and again whenever the colorscheme changes, so picking a generator re-themes from the wallpaper already on screen.
- `TemplateService` — owns the app-theming templates shared by both generators (see below).
- `LocalSendService`, `DateService`.

External CLI tools these depend on (must be on PATH): `cava`, `awww` + `awww-daemon`, `mpvpaper`, `notify-send`, `iris`/`matugen` for colorscheme generation, plus `python3` for helpers.

## Templates

`Templates/` holds the theme files the shell renders for other apps (GTK, Qt, ghostty, Emacs, Discord, Telegram, and its own `Themes/<generator>.json`). `Templates/Iris/<file>` and `Templates/Matugen/<file>` are two renderings of the *same* target file — same output path, same theme name — so switching generators needs no change inside the apps themselves.

`Config/templates.json` is the registry, keyed by template name:

```json
"gtk3": { "enabled": true, "template": "gtk.css", "output": "~/.config/gtk-3.0/colors.css", "postHook": "..." }
```

`template` is the file name looked up in `Templates/<generator>/` and defaults to the key (so two entries can share one source file, as gtk3/gtk4 do). `output` and `postHook` may contain `{generator}` (`Iris`/`Matugen`) and `{mode}` (`dark`/`light`). It is shaped too freely for a `JsonAdapter`, so `Core/Config.qml` parses it by hand and exposes `Config.templates` plus `Config.saveTemplates()`; `Modules/Settings/SettingsTemplates.qml` is the GUI. **To add a template:** drop the file in *both* `Templates/Iris/` and `Templates/Matugen/`, then add an entry — the iris copy is symlinked into `~/.config/iris/templates/` automatically.

`Services/TemplateService.qml` drives it:

- Matugen renders its own templates, so the service keeps `Config/matugen-config.toml` (generated: `Templates/matugen-base.toml` plus one `[templates.*]` per enabled entry) in sync with the registry, and `MatugenService` passes it with `-c`. Never put template sections in `matugen-base.toml`.
- Iris hardcodes both ends — it renders `~/.config/iris/templates/<file>` into `~/.cache/iris/<file>` and nothing else — so `syncIris()` symlinks each enabled `Templates/Iris/<file>` into that directory, and `installIris()` copies the results out of the cache to the configured outputs afterwards. Iris does all the rendering; the shell only moves files, so none of its color logic is duplicated here. The sync prunes with `find -type l -lname`, which touches only links pointing into `Templates/Iris/` and never a real file the user put there.
- `{mode}` for iris comes from the `dark` flag in `~/.cache/iris/colors.json`, watched by a `FileView`. It is read opportunistically and `installIris()` never waits on it: a `FileView` only signals when content actually changes, so gating a run on one silently stops after the first render (this was a real bug).
- Post hooks are always run by the shell (not by matugen's `post_hook`), so an enabled template behaves identically under either generator. They run before the generator's own `Config.<generator>.after` commands.
- `TemplateService` syncs on `Component.onCompleted` as well as on registry change. Singletons load lazily, and by the time anything first reaches for this one the registry has usually already loaded and its change signal is long gone.

## Conventions

- Views size themselves via `implicitWidth`/`implicitHeight` (usually content + `Config.island.padding`/`.height`); `Bar.qml` animates the island resize with `Behavior on implicit{Width,Height}`.
- Reach system state through a Service singleton or `Config`, not by spawning `Process` directly inside a view — put the process in a service.
- Commit style is Conventional Commits (`feat:`, `fix:`, `refactor:`, `chore:`, `docs:`, with optional scope e.g. `fix(themes):`).
