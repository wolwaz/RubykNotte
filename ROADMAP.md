# RubykNotte Roadmap

Direction for RubykNotte: a fast, lightweight, **writer-focused** Markdown editor built entirely with **Ruby and Tk**.

## Philosophy (do not break these)

1. **Responsiveness first** — typing, scrolling, searching, and file load stay snappy.
2. **Useful for writers and planners** — features must earn their place at the keyboard.
3. **Plain local Markdown** — normal `.md` files, no proprietary format, no cloud requirement.
4. **No Electron, no bundled AI** — pure Ruby + system Tk; keep the dependency surface tiny.
5. **Improve, don’t rewrite** — prefer small, reversible changes over tearing out a working editor core.

Features are added only when they help writing, planning, editing, safety, navigation, or organization **without** undermining responsiveness.

---

## Current release: v0.2.0

### Already in place

#### Core editor
- [x] Single-window Ruby/Tk editor with undo-capable Tk Text
- [x] Centralized theme module (Sepia, Dark) + Clam ttk base styling
- [x] Line-based Markdown highlight: H1–H6, bold, italic, muted markers
- [x] Find / Replace (forward, backward, wrap, replace, replace all, regex, match case)
- [x] Header navigation popup (H1–H6)
- [x] Status bar: words, characters, reading-time estimate, filename, Edit / Read-Only
- [x] Zoom and adjustable line spacing
- [x] Go to Line

#### Editing comfort
- [x] Bold / italic shortcuts and toolbar actions
- [x] H1–H6 toolbar insertion
- [x] List continuation (`-`, `*`, `+`, numbered)
- [x] Auto-pairing for `*`, `` ` ``, `[]`, `()` with mark tracking
- [x] Arrow-key skip over Markdown delimiters
- [x] Move line / block up–down; duplicate line
- [x] Manual `edit_separator` boundaries around major edits
- [x] Save As with overwrite confirmation

#### Safety (baseline)
- [x] Emergency crash recovery under `~/.markdown_editor_backups/`
- [x] Atomic backup write; primary + `.bak` rotation
- [x] Open Recovery Backup menu action
- [x] Crash handler attempts emergency save before exit
- [x] Unsaved-changes prompt on Quit

#### Engineering
- [x] Regression suite (Minitest) loadable without GUI
- [x] CI: Ruby syntax check + regression tests
- [x] Docs under `doc/` (architecture, event flow, parser, limitations, testing)

### Still rough in v0.2.0 (known gaps)

- [ ] Find/Replace edge cases (empty regex matches, find-in-selection)
- [ ] Nested / triple-asterisk emphasis remains limited
- [ ] Header popup reliability across platforms
- [ ] Multi-line selection edge cases when moving lines
- [ ] Unsaved-change confirmation on **New** and **Open** (Quit only today)
- [ ] Theme and font choices are not persisted across restarts
- [ ] Multi-tab is UI-only (single tab still)

---

## Near term — stabilize before expanding

Goal: make the current surface trustworthy. No big new subsystems until these feel solid.

### Reliability and safety

- [ ] Unsaved-change confirmation for New and Open
- [ ] Clearer file read/write error messages and recovery paths
- [ ] Systematic undo/redo checks after format, replace, paste, line move
- [ ] Verify shortcuts on Linux / macOS / Windows (where Tk is available)
- [ ] Optional idle autosave (separate from crash recovery), with simple on/off
- [ ] Recovery folder cleanup (manual + optional size/age limits)

### Editor polish

- [ ] Harden Find/Replace (empty matches, selection scope, match counter)
- [ ] Improve italic / mixed-emphasis highlighting within the line-based model
- [ ] Header popup: reliable outside-click close, keyboard type-ahead if cheap
- [ ] Preserve selection more consistently on line/block move
- [ ] Empty-line duplicate behavior remains predictable

### UI consistency

- [x] Centralize colors, fonts, spacing (Theme module)
- [x] Keep Clam + explicit ttk style overrides
- [x] Keep Tk Text as the editing surface
- [ ] Tighten toolbar grouping and spacing
- [ ] Restyle dialogs / status / scrollbars for Sepia and Dark consistency
- [ ] Neutral **Light** theme
- [ ] Persist last theme (and later: font size, spacing) locally

---

## Next — writing comfort

Only after near-term stability is in good shape.

- [x] Runtime font size (zoom) and line spacing
- [ ] Configurable editor font family (still hardcoded to Noto Sans)
- [ ] Adjustable editor padding
- [ ] Reading-width presets: Narrow / Comfortable / Wide / Full
- [ ] Focus mode (hide nonessential chrome)
- [ ] Fullscreen writing mode
- [ ] Typewriter scrolling (active line near center)
- [ ] Configurable word wrap
- [ ] Stronger current-line / selection visibility

---

## Next — large-document navigation

Supports the “large Markdown” goal without leaving plain files.

- [x] Basic go-to-heading popup
- [x] Go to line
- [ ] Heading outline sidebar (lazy, cheap updates)
- [ ] Searchable quick-jump-to-heading
- [ ] Heading fold / unfold (and fold-to-level)
- [ ] Back / forward navigation history
- [ ] Simple bookmarks
- [ ] Search match counters and clearer result navigation

---

## Later — deeper Markdown (still plain text)

Stay line-friendly and performance-aware; avoid a full CommonMark rewrite unless needed.

- [x] H1–H6, bold, italic
- [x] Basic list continuation and auto-pairing
- [ ] Highlight links, images, inline code, fenced code, blockquotes, lists, task lists, tables, rules
- [ ] Styled Raw mode (editable Markdown with quieter syntax)
- [ ] Nested list continuation
- [ ] Better paired-symbol deletion
- [ ] Small helpers: link insert, image insert, simple table scaffold
- [ ] Task-list toggle
- [ ] TOC generation into the document
- [ ] Optional footnotes if they stay lightweight

---

## Later — preview and layout

Preview must stay **debounced** and independent of the typing path.

- [ ] Rendered Markdown preview
- [ ] Raw / Styled Raw / Rendered modes
- [ ] Simple split (horizontal or vertical)
- [ ] Optional multiple views of one file (only if memory stays sane)
- [ ] Save/restore simple layout state locally

---

## Later — writer workflow (local only)

Aligned with planners/writers; still no cloud and no proprietary store.

### Companion files and light workspace

- [ ] Convention such as `[name]_companion_[n].md`
- [ ] Optional open of companions with a main file
- [ ] Companion roles as ordinary Markdown (Characters, Timeline, Research, …)
- [ ] Lazy-load hidden companions when possible

### Optional metadata

- [ ] Optional YAML front matter
- [ ] Titles / tags only if they never break plain-Markdown usability
- [ ] Simple related-note links / backlinks **if** they stay file-based and fast

### Stats and revision

- [x] Whole-document word / char / reading-time stats
- [ ] Selection and session word counts
- [ ] Optional daily writing goal
- [ ] Local snapshots (not a full VCS)
- [ ] Simple diff between snapshots
- [ ] Lightweight TODO / annotation markers in Markdown itself

### Settings

- [ ] Local settings file (theme, font, spacing, recovery options, confirmations)
- [ ] Shortcut viewer; customizable bindings only if complexity stays low

---

## Safety roadmap (beyond crash recovery)

Crash recovery in v0.2.0 is a floor, not the ceiling.

- [x] Emergency / idle backup to recovery files
- [x] Crash-time emergency save attempt
- [ ] User-facing autosave options (interval, enable/disable)
- [ ] Optional rotating autosave slots per file
- [ ] Short local version history for the active file
- [ ] Recovery cleanup tools

---

## Experimental (explicitly low priority)

Architecture stress tests — not commitments.

- [ ] Command palette
- [ ] Multi-cursor / column selection
- [ ] Minimap
- [ ] Customizable toolbar
- [ ] Built-in performance diagnostics
- [ ] Multi-document workspace manager

**Not planned:** Electron, cloud sync as a core feature, or built-in AI assistants.

---

## Performance targets

Re-check after each major subsystem.

| Target | Goal |
|--------|------|
| Startup (HDD) | under 10 s |
| Open ~45k-word document | under 4 s |
| Typing in that document | no noticeable lag |
| Search in that document | under 1 s |
| Memory | prefer under ~200 MB; investigate above that |
| Save large document | feels immediate |
| Menus, resize, heading UI | stay responsive |

---

## Long-term identity

RubykNotte should remain a **local Markdown workspace for writers and planners**:

- Fast enough for large plain Markdown files
- Tolerant of mistakes (undo, recovery, confirmations)
- Strong heading navigation (and later folding)
- Comfortable typography and a calm UI
- Optional preview and simple splits without becoming an IDE
- Companion notes as normal files beside the main document
- No Electron, no required cloud, no proprietary lock-in
