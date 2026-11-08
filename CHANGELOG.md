# Changelog

All notable versions of RubykNotte are documented here.

Format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

---

## [0.5.0] — unreleased — `v0.5.0`

UI consistency pass. No new editor features. The text widget stays; the chrome around it is what changed.

### Changed
- Menu bar buttons are flat at rest (hover/pressed only). Toolbar buttons keep a solid border. A thin separator sits between the two bars.
- Toolbar is grouped: Bold/Italic (with actual bold/italic fonts), then H1–H3, then H4–H6, then Undo/Redo. Read-Only shows a pressed state when active.
- Current heading moved off the Headings button into the status bar. Status order: words / chars / time, current heading, filename, Edit or Read-Only.
- Fake single notebook tab dropped. Filename lives in the window title (`name — RubykNotte`, with `*` when dirty) and the status bar.
- Find & Replace, Go to Line, recovery chooser, and headings popup use the active theme colors. Fixed dialog sizes removed so content can size itself.
- Neutral Light theme added (plain light, not warm). Sepia and Dark stay. Persisted the same way as the others.
- Extra 15px pad around the text frame removed so only the user text-padding setting controls the margin.

### Validation
- Manual GUI check recommended for menu/toolbar feel, theme switching, dialog theming, and status/title updates.

---

## [0.4.3] — unreleased — `v0.4.3`

Crash recovery is easier to get back, and harder to overwrite by accident.

### Changed
- Startup asks before touching a non-empty `recovery.md`: Restore, or start blank
- Starting blank rotates that file to `recovery.md.bak` once. New and Open no longer rotate it
- `recovery.json` remembers the source path and filename. Restore opens that file, still marked unsaved, so Save writes it back
- A successful Save or Save As deletes the current recovery. The previous `.bak` copy stays
- Open Recovery shows Latest and Previous with the source name, time, size, and first text line
- Only the first RubykNotte window writes recovery. A second window is told it will not

### Validation
- Regression coverage for rotation, startup restore/decline, New leaving recovery in place, summaries, save clearing the current copy, the sidecar, and the recovery lock

---

(Truncated for this call; full historical content follows in the real file.)
