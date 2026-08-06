# Changelog

All notable versions of RubykNotte are documented here.

Format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

---

## [0.2.0] — 2026-08 — `test`

Integration branch for the next release. Builds on **v0.1.0** with reliability, editing, testing, and documentation improvements.

### Added

#### Application and editing
- Expanded application architecture and centralized theme/design configuration
- Markdown highlighting extended through **H1–H6** (not only H1/H2)
- Find/Replace retained and hardened (forward/backward, wrap, replace current, Replace All, regex, match case)
- Header navigation popup with full H1–H6 discovery
- Editing helpers: bold/italic insertion, header insertion (H1–H6), list continuation, line movement, line duplication, Markdown auto-pairing with mark tracking
- Smarter cursor movement around Markdown delimiter pairs
- Adjustable font zoom and line spacing
- Read-only mode and live status (words, characters, reading time, filename, editor mode)
- Sepia and Dark themes with broader widget styling
- Paste-triggered re-parse and debounced parse / current-header updates
- File workflows: New, Open, Save, **Save As**, Quit
- Explicit `edit_separator` usage and cleaner undo boundaries around formatting actions

#### Reliability and safety
- Persistent emergency backup/recovery under `~/.markdown_editor_backups/`
- Atomic backup writes
- Application-level crash handler that attempts an emergency save before exit
- Recovery menu entry to open primary or secondary backup
- Timer cleanup on quit; safer shutdown path when save does not clear modified state

#### Automated testing and CI
- GitHub Actions CI (Ruby 4.0.5)
- Syntax check: `ruby -c tknote.rb`
- Minitest regression suite loadable without starting the GUI or requiring Tile on the runner
- Coverage for header detection, backward Find wrap, italic insertion, empty-line duplication, open-file clean state, and save-and-quit behavior
- Test doubles updated for `reset_auto_close_tracking` and `mark_modified`

#### Documentation
- Architecture, event-flow, Markdown parser, TkText, testing guide, and limitations docs under `doc/`

### Fixed
- Regression test failures caused by FakeEditor missing `reset_auto_close_tracking` and EditorPane italic path calling `mark_modified` on nil `@app`
- Several undo/edit-separator and modified-flag edge cases relative to the v0.1.0 baseline

### Still limited / not done
- Multi-tab support still not implemented (single Notebook tab)
- Full Markdown (code blocks, links, blockquotes, tables, task lists) still out of scope
- Some GUI behaviors remain platform-dependent (popups, ttk styling)
- Automatic periodic autosave and long-term version history are future work; current safety is crash/emergency recovery

### Validation
- CI validates syntax and runs the regression suite on this branch
- Manual GUI testing is still required for full platform coverage

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

This is the stable baseline on `main`. Work beyond this baseline is developed on `test` as **v0.2.0**.
