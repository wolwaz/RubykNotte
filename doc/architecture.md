# Architecture Overview

A single-window Markdown note editor written in Ruby/Tk. It provides live syntax highlighting, find/replace, header navigation, auto-pairing of `*`, `` ` ``, `[]`, and `()`, line moving/duplication, background crash recovery, and two themes (sepia, dark).

## High-level component diagram

```
┌──────────────────────────────────────────────────────────────┐
│                        MarkdownEditor                        │
│                                                              │
│  ┌─────────┐  ┌──────────┐  ┌──────────────────────────────┐ │
│  │ Menubar │  │ Toolbar  │  │          Notebook            │ │
│  └─────────┘  └──────────┘  │  ┌────────────────────────┐  │ │
│                              │  │       Tab Frame        │  │ │
│                              │  │  ┌──────────────────┐  │  │ │
│                              │  │  │    EditorPane    │  │  │ │
│                              │  │  │  ┌────────────┐  │  │  │ │
│                              │  │  │  │   TkText    │  │  │  │ │
│                              │  │  │  └─────┬──────┘  │  │  │ │
│                              │  │  │        │         │  │  │ │
│                              │  │  │ ┌──────┴──────┐  │  │  │ │
│                              │  │  │ │ Highlighter │  │  │  │ │
│                              │  │  │ └─────────────┘  │  │  │ │
│                              │  │  └──────────────────┘  │  │ │
│                              │  └────────────────────────┘  │ │
│                              │  ┌────────────────────────┐  │ │
│                              │  │       Status Bar       │  │ │
│                              │  └────────────────────────┘  │ │
│                              └──────────────────────────────┘ │
│                                                              │
│  Dialogs:  FindReplaceDialog · Go-to-Line · Header Popup     │
└──────────────────────────────────────────────────────────────┘
```

## Ownership tree

```
MarkdownEditor  (root TkRoot)
    ├── @menubar           (File / Edit / View / Theme + Headings button)
    ├── @toolbar           (Bold / Italic / H1–H6 / Read-Only)
    ├── @notebook          (single tab currently)
    │       └── @tab_frame
    │             ├── @status_bar  (left / center / right labels)
    │             └── @editor      (EditorPane)
    │                    ├── @text         (TkText)
    │                    └── @highlighter  (MarkdownHighlighter)
    ├── @find_dialog       (FindReplaceDialog, lazy)
    ├── @goto_dialog       (TkToplevel, lazy)
    └── @header_popup      (TkToplevel, lazy)
```

## Class: Theme

Module of design tokens. `SPACING`, `FONTS`, and `THEMES[:sepia|:dark]`. v0.3.0 adds `code_bg`, `code_fg`, `blockquote_fg`, `hr_color`, `strike_fg`.

## Class: MarkdownHighlighter

Line-local tagger. See [markdown_parser.md](markdown_parser.md).

Public methods: `setup_tags`, `apply_theme`, `apply_font_settings`, `parse_line(line_num, force_render = false)`, `parse_current_line`, `parse_entire_document`, `rebuild_headers_cache`, `get_headers`, `get_current_header_line`, `get_current_header_text`.

## Class: FindReplaceDialog

Modal find/replace. Operates on character offsets (`count … chars`) rather than byte offsets. Supports match-case and Ruby regex.

## Class: EditorPane

Owns the TkText, scrollbar, highlighter, shortcuts, auto-close marks, and line helpers.

| Method | Description |
|---|---|
| `reset_auto_close_tracking` | Unsets all tracked `[` / `(` marks |
| `insert_bold` / `insert_italic` | Wrap or insert `**` / `*` |
| `handle_return` | HR shortcut, then list continuation |
| `parse_after_paste` | Full re-parse after Ctrl+V |
| `parse_and_update` | Debounced: current line + headers + status |
| `move_line_up` / `move_line_down` | Swap block with neighbor; keep selection |
| `duplicate_line` | Duplicate current line below |
| `cancel_timers` | Cancel parse debounce on quit |

Readers: `:text`, `:highlighter`, `:app`, `:debounce_timer`.

`*` and `` ` `` always insert a closer (scaffold). `[` and `(` insert a closer and register a left-gravity mark so a later closer can skip.

## Class: MarkdownEditor

Top-level application: window, menus, toolbar, notebook, status, EditorPane, file I/O, theming, zoom/padding, backups, dialogs.

Notable methods added or changed in v0.3.0:

| Method | Description |
|---|---|
| `confirm_discard_changes(label)` | Yes/No/Cancel if modified; Yes runs `save_file` |
| `change_text_padding(amount)` | Adjust `@text_padding_x/y` (min 2) then `apply_font_settings` |
| `new_file` / `open_file` | Confirm discard first |
| `open_recovery_file` | Confirm discard; load without `new_file` / rotate |
| `rotate_backups` | Also called at startup |

Accessors: `:is_modified`, `:notebook`, `:tab_frame`, `:status_left`, `:root`, `:current_theme`, `:last_keypress_time`.

Instance state includes `@text_padding_x`, `@text_padding_y`, `@backup_dir`, `@backup_file`, `@backup_check_timer`, `@backup_due_time`.

## Invariants

### After `open_file`

- Buffer equals file contents
- `@is_modified == false`
- Tab and status show basename
- Auto-close marks reset
- Undo stack reset
- Highlighter has parsed the whole document

### After `save_file` (success)

- `@is_modified == false`
- Tab name has no `*` prefix

### After `new_file`

- Empty buffer, `Untitled.md`, no path
- `@is_modified == false`
- Previous recovery file rotated to `.bak`

### After `open_recovery_file`

- Buffer equals chosen backup
- Document is Untitled and marked modified
- Chosen backup file is left in place (not rotated)
