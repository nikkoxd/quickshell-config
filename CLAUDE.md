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

- **`Bar.qml`** owns the StackView and holds every view as a `Component` property (`default_`, `notifications`, `launcher`, …). Navigation goes through `openView(view, params)` / `openDefaultView()`, which `content.replace(...)` into the stack. **To add a view:** create `Modules/<Name>.qml` (or a subfolder) extending `View`, add a `property Component <name>: <Name> {}` line in `Bar.qml`, and reference it by the string key `"<name>"`.

- **Ambient triggers** live in `Bar.qml` as `Connections` blocks: volume → `volume`, `NotificationService` notification → `notification`, LocalSend upload → `localsend`, file drag → `localsend`. Each is gated on `content.currentView.dismissable` so it won't interrupt an interactive view. Workspace switches and track changes are *not* among them — `Modules/Default/Default.qml` handles those itself by swapping its own centre, so the surrounding indicators stay put.

- **External control:** an `IpcHandler` with target `"bar"` exposes `toggle(view)`. Trigger from anywhere with `qs -c island ipc call bar toggle <view>` (bind these in Hyprland).

## Desktop widgets

`Modules/Widgets/` is separate from the view system: `Widgets.qml` is a `LazyLoader` over a click-through `PanelWindow` on `WlrLayer.Bottom` (masked with `Region { item: null }`, `ExclusionMode.Ignore`), so widgets sit on the wallpaper under every window and never take input or screen space. `shell.qml` instantiates it alongside `Dock`/`ScreenCorners`. Settings live in `Config/widgets.json` (`Config.widgets`), GUI in `Modules/Settings/SettingsWidgets.qml`.

`Modules/Widgets/Lyrics.qml` is the scrolling karaoke panel the dashboard used to show, kept generic: `fontScale`, `horizontalAlignment` (the fill follows the per-row `x` the layout hands it, so centred text fills correctly), `idleOpacity`/`minOpacity` for how the off-lines dim, `lineSpacing`, and `wheelEnabled`/`seekOnClick` for a surface that cannot take input. `LyricsWidget.qml` sizes it to `Config.widgets.lyricsRows` rows — the panel keeps the active line centred, so three rows read as previous/current/next — and fades itself out when there are no lyrics or playback is paused.

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
- `Chip` — labelled toggle pill. Independent of its neighbours, so a row of them reads as a multi-select filter (the wallpaper browser's categories/purity); emits `clicked()`.
- `SegmentPill` — segmented control over `options` (a list of `{ label, value }`) with a highlight that slides onto `current`; emits `selected(value)`. `icons: true` renders the labels as glyphs.
- `Dropdown` — single-select dropdown over the same option shape (plain strings also work); emits `selected(value)`. The list floats and the root stays trigger-height, so opening one never reflows the layout — but a clipping container has to grow by `listHeight` to reveal it, and `collapse()` closes it.
- `PopupMenu` — `PopupWindow` context menu built from a `menu` list of `{ text, triggered, isSeparator }`; `showMenu()` opens it, `closeRequested` fires on activation.

Chrome and helpers:

- `ViewHeader` — the title row every non-default view uses: `text` on the left, children going into the right-hand action `Row` (its `default` property).
- `Cava` / `CavaBars` — the two visualizer renderings fed by `CavaService`. `Cava` paints a gradient curve across the island background, `CavaBars` a few inline bars next to text; each is `visible` only for its own `Config.visualizer.mode` (`"background"` / `"bars"`), so both can be instantiated unconditionally.
- `PlaybackClock` — playback position on the frame clock, for anything that has to move with the music. `MprisService.position` only ticks five times a second, so a fill bound to it steps rather than sweeps; this predicts forward from the last published position and steers out the stale reads players send instead of snapping onto them. Both karaoke fills (`Modules/Default/LyricsText.qml`, `Modules/Widgets/Lyrics.qml`) run off one. `active` gates the `FrameAnimation` behind it — it drives the render loop, so one left running repaints the shell for nothing.
- `PopIn` — wrapper that animates an ambient indicator in and out: the slot it takes in its `Row` grows and shrinks while the child scales and fades inside it. The child must *not* hide itself — the condition goes on the wrapper's `shown`, so there is still something laid out to animate on the way out; the default-view indicators therefore expose their condition as `active` instead of binding it to `visible`. `animateOnLoad` pops on creation, for delegates where being built is the same event as arriving. `pop` (default true) is the overshoot past full size; turn it off where the wrapper shares its slot.
- `CrossFade` — the fade-and-scale half of `PopIn` on its own, for a slot several elements share: each member wraps its child and is `shown` one at a time, they overlap on the way past each other, and nothing touches the layout. `pop` defaults to *false* here — an overshoot reads as arriving out of nothing, which is wrong for a swap — so the default view's centre (clock/lyrics/track/workspaces) and its artwork-vs-visualizer slot use it plain, while `PopIn` builds on it with `pop` on.
- `RecordingIndicator` — the blinking dot shown while `RecordingService.recording`. `shown` is the extra gate default views use to keep it clear of the inline visualizer.
- `ScreenshotIndicator` / `RecordingSavedIndicator` — the glyph-with-a-check badges shown for a couple of seconds after a capture or a recording lands, instead of a notification: `RecordingService` owns the timing (`screenshotFlash` / `recordingFlash`) and each indicator only exposes it as `active` for a `PopIn` to drive.
- `CommandQueue` — runs a list of shell commands one at a time through `sh -c`, warning on stderr with `label` as the prefix. Used for user-configured hook commands.

## Services

Singletons in `Services/` wrap external systems and expose reactive properties/signals for views to bind to:

- `MprisService` — media players (emits `trackChanged`); also exposes `position`/`length`, refreshed by a timer since `MprisPlayer.position` is not self-updating. That property is an *extrapolation*: quickshell reads `Position` off the bus only when the track or the playback status changes and runs a wall clock forward from there, so a player that is still buffering — reporting the position it has actually reached, which is none — leaves the clock counting from a start that has not happened and everything following playback sits that far ahead for the rest of the track. `Helpers/mpris_position.py` reads the real `Position` back twice a second while something is playing; `positionOffset` carries the gap (eased out while it is small, taken off at once past `offsetSnap`, since players report at their own granularity — Sonora a whole second at a time), and `stalled` is the player claiming to play while its position has not moved for `stallTimeout`. `position` is the corrected value every view should read, and `Core/PlaybackClock.qml` stops predicting while `stalled`.
- `NotificationService` — wraps `NotificationServer`; `muted` (do not disturb) gates OSD popups and is mirrored to `Config.notifications.doNotDisturb` so it survives a reload; `notify()` shells out to `notify-send`.
- `CavaService` — spawns `cava` as a `Process`, feeds it config via stdin, parses raw stdout into a `values` array for the visualizer. `Config.visualizer.source` picks what cava listens to: `"auto"` writes no `[input]` section at all (cava's default, the sink monitor, so every app at once), `"player"` resolves the active MPRIS player to its own PipeWire stream through `Helpers/audio_nodes.py` and captures only that, and any other value is passed through verbatim as a `node.name`. cava reads its input once at startup, so a new target means stopping and relaunching it; the stream also appears a moment after the player does, so a miss is retried with a growing delay before falling back to system audio.
- `WallpaperService` — drives `awww`/`awww-daemon` (images) and `mpvpaper` (video); folder models from `Config.wallpaper.staticWallpaperFolder`; video list via `Helpers/list_walls.py`.
- `LyricsService` — fetches the whole timestamped lyrics once per track via `Helpers/lyrics.py fetch`, asking Kugou first and falling back to lrclib.net (`--providers` sets the order, driven by `Config.island.lyricsProviders` — a list of `{ name, enabled }` the Island settings page reorders and toggles, normalized by the service's `providers`; cached under `$XDG_CACHE_HOME/island/lyrics/`, each record keeping the providers it `asked` so a hit is dropped once a provider now ranked ahead of it was never tried, and a miss is only cached when every provider actually answered). Kugou serves KRC — word-synced for nearly every track, zlib behind a fixed XOR key — looked up through Kugou's song search and then by that song's hash (its keyword-only lyrics search misses much of the catalogue, and is only the fallback), and accepted only within `DURATION_TOLERANCE` of the track's length; its leading "Title - Artist" and credit lines are dropped; exposes `state`, `lines`, `plain`, `currentIndex`, `currentText` and `seek()`. The active line is derived in QML from `MprisService.position`, not by re-spawning the helper; `currentIndex` follows the 5Hz published position, so views that fill on a `PlaybackClock` pick their line with `lineIndexAt(clock.position, lead)` and pass it to `sweepAt()` instead — otherwise each line swaps in up to a tick after its first word, which Kugou's onset-exact stamps make visible. Lines carry their own `end` where the source gave one, and a `words` list where the source is word-synced — Kugou's KRC, enhanced LRC (`<mm:ss.xx>` stamps) or, more usually, LRCLIB's `lyricsfile` YAML, which needs PyYAML and is what `worded` reports on. A word is `{ time, end, from, to }`, `from`/`to` being character offsets into the line rather than a copy of its text, so a view can measure the line it already drew. `sweepAt(position)` turns all of that into the stretch being filled right now (`{ from, to, progress }`): the word being sung where there are words, the whole line where there aren't, so both fills are the same code. Word ends are capped at the next word's start in the helper, so a fill lands exactly on each boundary instead of being dragged across it. `Config.island.lyricsOffset` (milliseconds, positive holds the lines back) shifts the whole lyrics timeline against playback: the service applies it in `timelineAt()` and reads every position through that, so the line index, both fills and click-to-seek all move together and no view has to know about it.
- `DockService` — builds the dock model: one item per application (`{ appId, entry, toplevels, pinned }`), pinned apps first in the order saved to `Config.dock.pinned`, then running-but-unpinned apps. Owns `move()`/`persistOrder()` (drag reorder; only pinned positions survive a restart), `setPinned()`/`togglePin()`, and `activate()`/`launch()`/`close()`.
- `IrisService` / `MatugenService` — the two colorscheme generators, each a no-op unless `Config.theme.colorscheme` names it. Both are called from `WallpaperService.generateColors()`, and again whenever the colorscheme changes, so picking a generator re-themes from the wallpaper already on screen.
- `TemplateService` — owns the app-theming templates shared by both generators (see below).
- `WallhavenService` — search and download against wallhaven.cc through `Helpers/wallhaven.py`; exposes `results`, `loading`, `error`, `page`/`lastPage`, `search()`/`loadMore()`/`download()` and `downloaded`/`downloadFailed`. Filters live in `Config.wallhaven` (categories/purity bit strings, sorting, ratio, API key); `Modules/Wallpapers/WallpaperBrowser.qml` is the GUI and applies a finished download through `WallpaperService`.
- `ProcessService` — the process table behind the launcher's process manager: re-runs `ps` every 2s while `polling` is set (the provider sets it, so nothing is spawned for a view nobody has open) and publishes `rows`, already filtered, grouped and sorted per `Config.launcher`; also `sendSignal()`, `copyPid()`, `focusWindow()` and `hasWindow()`. Rows are QObjects pooled by pid, not plain objects rebuilt each tick: `ScriptModel` can't compare two structurally identical JS objects, so a fresh array reset the whole model and threw the launcher's selection away. For the same reason the whole table is built here rather than in the provider — the provider's `entries()` runs inside the model's binding, and a binding that writes to the rows it reads is a binding loop. `Modules/Launcher/Providers/ProcessProvider.qml` is the GUI: the table, a per-process action list and a signal picker, all drawn as ordinary launcher results, with Escape walking back up through `goBack()`. It stamps the launcher-side fields (icon, `execute`) onto the rows off `rowsChanged`, every refresh — the rows outlive the launcher view, so a closure kept from a previous open would call into a destroyed provider.
- `LocalSendService`, `DateService`.

External CLI tools these depend on (must be on PATH): `cava`, `awww` + `awww-daemon`, `mpvpaper`, `notify-send`, `iris`/`matugen` for colorscheme generation, `tesseract` for OCR, `wayfreeze` for freezing the screen during a screenshot selection, `pw-dump` (pipewire) for resolving a player's audio stream, plus `python3` for helpers (with PyYAML for LRCLIB's word-synced lyrics and PyGObject for reading a player's real MPRIS position). `ffmpeg` is used for video-wallpaper thumbnails and ImageMagick (`magick`) for the Telegram theme background.

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

Telegram is the one target that is not a plain rendered file. A `.tdesktop-theme` is a zip of `colors.tdesktop-theme` plus a `background.jpg` (or `tiled.jpg`) that Telegram shows behind the chats, so the template renders only the palette, to `~/.config/telegram/island.tdesktop-palette`, and the post hook runs `Helpers/telegram-theme.py` to zip that together with the current wallpaper into `~/.config/telegram/island.tdesktop-theme`. The helper reads the wallpaper out of `Config/wallpaper.json` when `--wallpaper` is not given, pulls a still out of a video wallpaper with ffmpeg, and takes `--blur`, `--dim`, `--size` and `--tiled` for how the background is rendered. `--solid` drops the wallpaper for a flat fill instead: bare it uses the palette's own generated `windowBg`, and it also accepts any other palette key (`--solid msgInBg`) or a `#rrggbb` literal. Telegram does not watch the file, so the theme has to be re-imported after a wallpaper change.

The `kde` entry is the other one. KDE apps — Dolphin, Gwenview, Okular — take their palette from `~/.config/kdeglobals` through `KColorScheme` and ignore the qt5ct/qt6ct palette `qtct.conf` writes, so a Qt theme alone leaves them on whatever wrote kdeglobals last. kdeglobals also holds settings that have nothing to do with color, though, so the template renders a standalone KDE color scheme to `~/.local/share/color-schemes/Island.colors` and the post hook runs `Helpers/kde-theme.py` to merge only its `Colors:*`/`ColorEffects:*`/`WM` groups into kdeglobals, converting the `#rrggbb` values into the `r,g,b` triples KConfig reads as a `QColor` and dropping color groups the scheme no longer defines (a leftover group from a previous theme otherwise keeps overriding the new one). It then fires the `org.kde.KGlobalSettings` palette signal and a `kwriteconfig6 --notify`; apps that listen to neither pick the theme up on restart.

## Conventions

- Views size themselves via `implicitWidth`/`implicitHeight` (usually content + `Config.island.padding`/`.height`); `Bar.qml` animates the island resize with `Behavior on implicit{Width,Height}`.
- Reach system state through a Service singleton or `Config`, not by spawning `Process` directly inside a view — put the process in a service.
- Commit style is Conventional Commits (`feat:`, `fix:`, `refactor:`, `chore:`, `docs:`, with optional scope e.g. `fix(themes):`).
