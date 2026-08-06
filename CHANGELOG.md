# Changelog

## Unreleased — `test` branch

This entry summarizes the changes currently present on the `test` branch compared with `main`.

### Application and Editing

- Expanded the main Ruby/Tk editor implementation with a more structured application architecture and centralized theme/design configuration.
- Added or expanded Markdown editing and highlighting support, including headers, bold, italic, and muted Markdown marker styling.
- Added Find/Replace functionality with forward/backward search, wrap-around behavior, replace-current, Replace All, regex mode, and case-sensitive matching.
- Added header navigation through a dedicated popup with document header discovery and cursor jumping.
- Added editing helpers for bold/italic insertion, header insertion, list continuation, line movement, line duplication, and Markdown auto-pairing.
- Added smarter cursor movement around Markdown delimiter pairs.
- Added adjustable font zoom and line spacing controls.
- Added read-only mode and live status information for words, characters, reading time, filename, and editor mode.
- Added Sepia and Dark theme support with centralized theme colors and widget styling.
- Added paste-triggered document re-parsing and debounced Markdown parsing/current-header updates.
- Added file open/save/new-file workflows and improved document state handling.

### Reliability and Safety

- Added persistent emergency backup/recovery support for modified documents.
- Added atomic backup writing for recovery data.
- Added an application-level crash handler that attempts an emergency save before re-raising the exception.
- Added recovery-oriented handling around application shutdown and editor timers.

### Automated Testing and CI

- Added GitHub Actions CI for Ruby 4.0.5.
- CI now performs a Ruby syntax check with `ruby -c tknote.rb`.
- Added a Minitest-based unit/regression suite covering core editor logic and previously identified regressions.
- Regression coverage includes byte-offset handling, header detection, backward Find wrap-around, italic insertion, empty-line duplication, file opening state, and save-and-quit behavior.
- Updated the test harness so application classes can be loaded without starting the GUI, without depending on the Ruby/Tk Tile extension being installed on the CI runner, and without executing the application's real GUI entry point.

### Documentation

- Added architecture documentation describing the application structure and ownership model.
- Added event-flow documentation covering file operations, editing commands, auto-pairing, parsing, Find/Replace, header navigation, zoom, and theme switching.
- Added Markdown parser documentation describing syntax detection, tag application, parsing strategy, and current limitations.
- Added Tk Text widget documentation covering configuration, theming, spacing, read-only behavior, and Markdown tag stacking.
- Added a structured manual testing guide and regression-test triggers.
- Added a documented limitations/known-issues reference.

### Current Limitations / Not Yet Implemented

- Multi-tab support is not implemented yet, despite the current Notebook-based UI structure.
- Markdown header support and navigation remain limited compared with full Markdown implementations.
- Some advanced GUI behavior may vary by platform, particularly around popup behavior and native Tk/ttk widgets.
- Some editing edge cases remain under manual testing, including certain italic/highlighting cases, regex edge cases, selection preservation during line movement, and empty-line duplication behavior.
- Automatic autosave and long-term version history are future work; the current safety layer is focused on persistent crash/emergency recovery.

### Validation Status

- The `test` branch is intended as the next integration point for the automated testing system.
- GitHub Actions is configured to validate syntax and run the regression suite.
- Manual testing remains required for full GUI behavior and platform-specific Tk behavior.
