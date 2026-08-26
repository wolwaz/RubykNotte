# RubykNotte

**Disclaimer: this app is vibe-coded. Expect rough edges.**

A lightweight Markdown note editor written in pure Ruby + Tk.

**Current release: v0.3.0** (branch `v0.3.0` → `main`)

See [CHANGELOG.md](CHANGELOG.md) for full history.

## Goals

- Fast startup
- Low memory usage
- Comfortable writing
- Pure Ruby
- Pure Tk
- No Electron
- Large document support (still aspirational)

## Requirements

- Ruby with the `tk` extension available
- Tk / ttk (Tile) installed on the system

## Run

```bash
ruby tknote.rb
```

## Features (v0.3.0)

### Core
- **Markdown highlighting** — H1–H6, bold (`**...**`), italic (`*...*`), bold+italic (`***...***`), inline code (`` `...` ``), strikethrough (`~~...~~`), blockquotes (`>`), horizontal rules (`---`, `***`, `___`)
- **Find / Replace** — forward & backward search, replace current, replace all; optional regex and match-case
- **Themes** — Sepia and Dark with centralized colors and widget styling
- **Header navigation** — popup list of H1–H6 headings; click or Enter to jump
- **Status bar** — word count, character count, estimated reading time, filename, Edit / Read-Only mode

### Editing
- Bold / Italic via toolbar or `Ctrl+B` / `Ctrl+I`
- H1–H6 insertion via toolbar
- List continuation for `-`, `*`, `+`, and numbered lists on Enter
- Horizontal-rule shortcut: type `***` (auto-close scaffolds `***|***`) then Enter
- Auto-pairing for `*`, `` ` ``, `[]`, `()` (`*` / `` ` `` always scaffold so `**` / `***` / ``` work)
- Arrow-key skip over Markdown delimiters
- Move line up/down (`Ctrl+Up` / `Ctrl+Down`), duplicate line (`Ctrl+Shift+D`)
- Zoom (`Ctrl++` / `Ctrl+-` / `Ctrl+0`), line spacing, and text padding
- Read-only toggle
- Go to line (`Ctrl+G`)
- New / Open / Save / **Save As** / Quit with unsaved-changes prompts on New, Open, Recovery, and Quit
- Improved undo boundaries via `edit_separator` around formatting actions

### Reliability
- Emergency crash recovery backups under `~/.markdown_editor_backups/`
- Atomic backup writes; primary + secondary (`.bak`) recovery files
- Previous session rotated to `.bak` on startup
- **Open Recovery Backup…** in the File menu (does not rotate away the chosen backup)
- Crash handler attempts an emergency save before exit

### Testing & CI
- GitHub Actions CI (Ruby syntax check + Minitest regression suite)
- Tests load application classes without starting the GUI

### Documentation
- Architecture, event flow, parser, TkText, testing guide, and limitations under `doc/`

### Not implemented yet
- Multi-tab editing (Notebook UI is present but still single-tab)
- Fenced code blocks, links, images, tables, task lists
- Periodic named autosave and long-term version history (recovery backups only)
- Light theme / user-customizable themes
- Persisted theme, zoom, and padding

## Known issues

- Some header-popup and selection behaviors can still be flaky across platforms
- Line move may not preserve complex multi-line selections perfectly
- Nested mixed emphasis inside other spans is still limited by the line-based parser
- Full GUI behavior still needs manual testing beyond CI

## License

See [LICENSE](LICENSE).
