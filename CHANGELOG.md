# Changelog

All notable versions of RubykNotte are documented here.

Format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

---

## [0.1.0] — 2026-08 — `main`

Initial public baseline of the Ruby/Tk Markdown note editor.

### Added

- Single-window Markdown editor built with Ruby and Tk/ttk
- Centralized theme module (Sepia and Dark) with shared spacing and fonts
- Line-based Markdown highlighter for **H1**, **H2**, **bold**, and **italic**
- Find & Replace dialog (forward/backward, wrap, replace current, replace all, regex, match case)
- Header navigation popup for H1/H2 headings
- Status bar: words, characters, reading-time estimate, filename, Edit / Read-Only mode
- Editing helpers: bold/italic shortcuts and toolbar buttons, H1/H2 insert, list continuation, auto-pairing, delimiter-aware arrow movement, line move, line duplicate
- Zoom and line-spacing controls
- Read-only toggle
- Go to Line dialog
- New / Open / Save / Quit with unsaved-changes prompt on quit
- Basic regression test harness under `test/` and CI workflow

### Known limitations

- Only one document tab is supported (Notebook UI is present but single-tab)
- Headers H3–H6 are not highlighted or listed in navigation
- No crash-recovery backups or autosave
- No Save As command
- No overwrite confirmation when choosing an existing path in the Save dialog
- Undo can clear the entire buffer after Open or heavy editing (see issue #19)
- No support for code blocks, links, blockquotes, tables, or task lists
- Header popup and some selection behaviors remain rough on certain platforms

### Notes

This is the stable baseline branch. Ongoing work (recovery backups, broader header support, improved undo, expanded tests and docs) lives on the `test` branch and is tracked as **v0.2.0** there.
