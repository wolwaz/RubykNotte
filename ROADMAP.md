# RubykNotte Roadmap

This roadmap tracks the direction of RubykNotte as a fast, lightweight, writer-focused Markdown editor built entirely with Ruby and Tk.

The priorities are:

1. Keep typing, scrolling, searching, and file loading responsive.
2. Add features that are useful for writers and planners.
3. Preserve plain Markdown files and local workflows.
4. Avoid unnecessary dependencies, cloud requirements, and built-in AI features.
5. Improve the UI without sacrificing performance or rewriting stable editor behavior without a clear reason.

## Current Focus

- Stabilize the current editor and fix known regressions.
- Finish the custom theme system.
- Improve UI consistency across ttk and classic Tk widgets.
- Keep large documents responsive while more features are added.
- Establish repeatable performance tests and a large Markdown stress-test file.

## Phase 1: Stabilization and Core Reliability

- [ ] Fix known Find/Replace edge cases, especially regex empty matches.
- [ ] Fix italic highlighting for single-asterisk emphasis.
- [ ] Fix header navigation popup closing behavior.
- [ ] Preserve text selection when moving lines.
- [ ] Fix duplication behavior for empty lines.
- [ ] Add overwrite confirmation when saving over an existing file.
- [ ] Add unsaved-change confirmation for New and Open actions.
- [ ] Verify keyboard shortcuts across supported platforms.
- [ ] Add clearer error handling for file read/write failures.
- [ ] Test undo/redo after formatting, replace, paste, and line movement.

## Phase 2: UI and Theme Foundation

- [ ] Centralize colors, fonts, spacing, and borders into one application theme system.
- [ ] Keep Clam as the ttk base while overriding widget styles consistently.
- [ ] Add subtle gray borders to buttons and controls.
- [ ] Improve toolbar grouping and spacing.
- [ ] Improve active and inactive notebook tab styling.
- [ ] Refine Sepia and Dark themes as first-class themes.
- [ ] Add a neutral Light theme later.
- [ ] Restyle scrollbars, comboboxes, dialogs, and status-bar widgets.
- [ ] Replace the native Tk menu with a custom menu bar and custom popup menus.
- [ ] Keep the existing Tk Text editor widget for performance.

## Phase 3: Writing Comfort

- [ ] Configurable editor font and font size.
- [ ] Adjustable internal editor padding.
- [ ] Adjustable line spacing and paragraph spacing.
- [ ] Comfortable reading-width presets: Narrow, Comfortable, Wide, and Full Width.
- [ ] Focus mode that hides nonessential UI.
- [ ] Fullscreen writing mode.
- [ ] Typewriter mode that keeps the active line near the center.
- [ ] Configurable word wrap.
- [ ] Optional first-line indentation for prose.
- [ ] Better selection, cursor, and current-line visibility.

## Phase 4: Large-Document Navigation

- [ ] Heading outline sidebar.
- [ ] Searchable quick-jump-to-heading dialog.
- [ ] Heading folding.
- [ ] Fold all and expand all commands.
- [ ] Fold to heading level.
- [ ] Back and forward navigation history.
- [ ] Bookmarks for arbitrary document positions.
- [ ] Better search-result navigation and match counters.
- [ ] Go to line improvements.

## Phase 5: Markdown Editing Features

- [ ] Expand syntax highlighting beyond headings, bold, and italic.
- [ ] Highlight links, images, code, blockquotes, lists, task lists, tables, and horizontal rules.
- [ ] Styled Raw mode: keep Markdown editable while visually reducing syntax noise.
- [ ] Smart list continuation for nested and numbered lists.
- [ ] Improve Markdown auto-pairing and paired-symbol deletion.
- [ ] Link insertion dialog.
- [ ] Image insertion helper.
- [ ] Table creation and editing helper.
- [ ] Task-list support.
- [ ] Table-of-contents generation.
- [ ] Optional footnote support.

## Phase 6: Preview and Split Views

- [ ] Rendered Markdown preview.
- [ ] Raw, Styled Raw, and Rendered view types.
- [ ] Adjustable split panes.
- [ ] Horizontal and vertical splits.
- [ ] Multiple splits instead of a fixed two-pane layout.
- [ ] Multiple views of the same document at different scroll positions.
- [ ] Save and restore split layouts.
- [ ] Keep preview rendering debounced and independent from typing.
- [ ] Synchronize preview position without forcing full-document rendering on every scroll event.

## Phase 7: Companion Files and Workspaces

- [ ] Recognize companion files using a convention such as `[name]_companion_[number].md`.
- [ ] Opening a main document can optionally open its companion files.
- [ ] Allow descriptive companion titles through optional metadata.
- [ ] Restore companion files into a saved split layout.
- [ ] Support companion roles such as Characters, Timeline, Research, Worldbuilding, TODO, and Scratchpad.
- [ ] Keep all companion content as normal Markdown files.
- [ ] Lazy-load hidden companion files where possible.

## Phase 8: Metadata and Note Linking

- [ ] Optional YAML front matter.
- [ ] Document titles, types, tags, and companion metadata.
- [ ] Links between related notes.
- [ ] Backlinks or related-note navigation.
- [ ] Workspace restoration metadata.
- [ ] Keep metadata optional so ordinary Markdown files remain fully usable.

## Phase 9: Writer Statistics and Revision Tools

- [ ] Selection word count.
- [ ] Session word count.
- [ ] Daily writing goal.
- [ ] Character, paragraph, heading, and reading-time statistics.
- [ ] Word-frequency and repetition analysis.
- [ ] Average sentence and paragraph length.
- [ ] Local snapshots.
- [ ] Version comparison and diff view.
- [ ] Comments, annotations, and TODO markers.
- [ ] Writing timer or optional Pomodoro mode.

## Phase 10: Settings and Customization

- [ ] Appearance settings: theme, UI font, accent, and interface density.
- [ ] Editor settings: font, size, line spacing, paragraph spacing, reading width, wrapping, and tabs.
- [ ] File settings: autosave, encoding, recovery options, session restore, and close confirmations.
- [ ] Interface settings: toolbar, status bar, focus mode defaults, and outline visibility.
- [ ] Shortcut viewer and later customizable keybindings.
- [ ] Save settings locally without cloud requirements.

## Phase 11: Safety features

- [ ] Auto save (and options) -- rotating files, threshold for each files, file slots
- [ ] Version history
- [ ] Better crash recovery/crash handling
- [ ] Force save when issue detected (every time when an error window popup)
- [ ] Clean up manager (auto clean up, manual clean up)

## Experimental Features

These are optional stress tests for the architecture rather than immediate priorities.

- [ ] Command palette.
- [ ] Multi-cursor editing.
- [ ] Column or block selection.
- [ ] Minimap.
- [ ] Customizable toolbar.
- [ ] Built-in performance diagnostics.
- [ ] Workspace manager for multiple document projects.

## Performance Targets

These targets should be checked after every major subsystem is added.

- Startup on an HDD: under 10 seconds.
- Open the current 45,000-word benchmark document: under 4 seconds.
- Typing in the 45,000-word document: no noticeable delay.
- Search in the benchmark document: under 1 second.
- Memory usage: ideally under 50 MB; 200 MB is the warning ceiling.
- Large preview jump or half-file scroll in Styled Raw/preview mode: visible result within 1 second.
- Saving a large document should feel immediate.
- Tab switching, heading folding, menu opening, and resizing should remain responsive.

## Long-Term Identity

RubykNotte should become a lightweight local Markdown workspace for writers and planners, with:

- Fast handling of very large Markdown documents.
- As mistake tolerant as possible.
- Strong heading navigation and folding.
- Comfortable typography and writing-focused UI.
- Raw, Styled Raw, and rendered views.
- Flexible split layouts and companion documents.
- Plain files, local storage, and no Electron dependency.

Features should be added only when they improve writing, planning, editing, safety, navigation, or organization without undermining responsiveness.
