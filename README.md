# RubykNotte

**Disclaimer: this app is vibe-coded. Expect rough edges.**

A lightweight Markdown note editor written in pure Ruby + Tk.

**Current release on `main`: v0.1.0**

## Goals

- Fast startup
- Low memory usage
- Comfortable writing
- Pure Ruby
- Pure Tk
- No Electron
- Large document support (aspirational)

## Requirements

- Ruby with the `tk` extension available
- Tk / ttk (Tile) installed on the system

## Run

```bash
ruby tknote.rb
```

## Features (v0.1.0 / `main`)

### Core
- **Markdown highlighting** — H1 (`#`), H2 (`##`), bold (`**...**`), italic (`*...*`)
- **Find / Replace** — forward & backward search, replace current, replace all; optional regex and match-case
- **Themes** — Sepia and Dark
- **Header navigation** — popup list of H1/H2 headings; click or Enter to jump
- **Status bar** — word count, character count, estimated reading time, filename, Edit/Read-Only mode

### Editing
- Bold / Italic via toolbar or `Ctrl+B` / `Ctrl+I`
- H1 / H2 insertion via toolbar
- List continuation for `-`, `*`, `+`, and numbered lists on Enter
- Auto-pairing for `*`, `` ` ``, `[]`, `()`
- Arrow-key skip over Markdown delimiters
- Move line up/down (`Ctrl+Up` / `Ctrl+Down`), duplicate line (`Ctrl+Shift+D`)
- Zoom (`Ctrl++` / `Ctrl+-` / `Ctrl+0`) and adjustable line spacing
- Read-only toggle
- Go to line (`Ctrl+G`)
- New / Open / Save / Quit with unsaved-changes prompt on quit

### Not implemented yet
- Multi-tab editing (UI uses a Notebook with a single tab)
- H3–H6 highlighting and navigation
- Crash recovery / autosave backups
- Save As
- Overwrite confirmation on Save
- Code blocks, links, blockquotes, tables, task lists

## Known issues (v0.1.0)

- Undo can wipe the buffer back to blank (especially after Open) — tracked as [#19](https://github.com/wolwaz/RubykNotte/issues/19)
- Only H1 and H2 are recognized for highlighting and the Headings popup
- Header popup behavior can be flaky on some platforms
- Line move does not preserve multi-line selections well
- No confirmation when saving over an existing file path chosen via Save dialog
- Italic / nested emphasis edge cases

## Development branches

| Branch | Role |
|--------|------|
| `main` | Stable baseline — **v0.1.0** |
| `test` | Integration / next release work — see CHANGELOG for **v0.2.0** changes |

## License

See [LICENSE](LICENSE).
