Architecture Overview
Purpose

A single-window, tabbed Markdown note editor written in Ruby/Tk.It provides live syntax highlighting, find/replace, header navigation,auto-pairing of *, `, [], and (), line moving/duplication,and two themes (sepia, dark).
High-Level Component Diagram

┌──────────────────────────────────────────────────────────────┐
│                        MarkdownEditor                        │
│                                                              │
│  ┌─────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────┐  │
│  │ Menubar │  │ Toolbar  │  │ Notebook │  │  Status Bar  │  │
│  └─────────┘  └──────────┘  └────┬─────┘  └──────────────┘  │
│                                   │                          │
│                          ┌────────┴────────┐                 │
│                          │   EditorPane    │                 │
│                          │  ┌────────────┐ │                 │
│                          │  │  TkText    │ │                 │
│                          │  └─────┬──────┘ │                 │
│                          │        │        │                 │
│                          │ ┌──────┴──────┐ │                 │
│                          │ │ Highlighter │ │                 │
│                          │ └─────────────┘ │                 │
│                          └─────────────────┘                 │
│                                                              │
│  Dialogs:  FindReplaceDialog · Go-to-Line · Header Popup     │
└──────────────────────────────────────────────────────────────┘
text
 
  
 
 

## Ownership Tree

 
 

MarkdownEditor  (root TkRoot)
    │
    ├── owns @menubar           (File / Edit / View / Theme buttons + menus)
    ├── owns @toolbar           (Bold / Italic / H1 / H2 / Headings / RO Toggle)
    ├── owns @notebook          (single tab currently)
    │       └── @tab_frame
    │             ├── @status_bar  (left / center / right labels)
    │             └── @editor      (EditorPane)
    │                    ├── @text         (TkText)
    │                    └── @highlighter  (MarkdownHighlighter)
    │
    ├── owns @find_dialog       (FindReplaceDialog, lazy)
    ├── owns @goto_dialog       (TkToplevel, lazy)
    └── owns @header_popup      (TkToplevel, lazy)
text
 
  
 
 
### Constants

| Constant                  | Value                                              |
|---------------------------|----------------------------------------------------|
| `PAIR_OPEN_TO_CLOSE`      | `{ '*' => '*', '`' => '`', '[' => ']', '(' => ')' }` |
| `SYMMETRIC_PAIR_CHARS`    | `['*', '`']` — chars that are their own closer     |
| `PAIR_CLOSER_CHARS`       | `[']', ')']` — chars that only ever close          |

### Public Methods

| Method                          | Returns  | Description                                       |
|---------------------------------|----------|---------------------------------------------------|
| `initialize(parent_frame, app)` | `self`   | Builds text frame, scrollbar, TkText, highlighter |
| `setup_shortcuts`               | `void`   | Binds all keyboard shortcuts                      |
| `register_auto_close_mark`      | `String` | Creates a tracked Tk mark at cursor; returns name |
| `consume_auto_close_mark`       | `Boolean`| If cursor is on a tracked mark, removes it; true  |
| `reset_auto_close_tracking`     | `void`   | Unsets all tracked marks                          |
| `insert_bold`                   | `String` | Wraps/inserts `**`; returns `'break'`             |
| `insert_italic`                 | `String` | Wraps/inserts `*`; returns `'break'`              |
| `handle_return`                 | `void`   | List continuation (bullets, numbered)             |
| `parse_after_paste`             | `void`   | Full re-parse after Ctrl+V                        |
| `parse_and_update`              | `void`   | Debounced: parse current line, update headers     |
| `move_line_up`                  | `void`   | Swaps current line with previous                  |
| `move_line_down`                | `void`   | Swaps current line with next                      |
| `duplicate_line`                | `void`   | Duplicates current line below                     |

### Public Readers (attr_reader)
- `:text` — the `TkText` widget
- `:highlighter` — the `MarkdownHighlighter`
- `:app` — the owning `MarkdownEditor`

### Important Instance Variables
- `@debounce_timer` — `Tk.after` handle for parse debounce
- `@auto_close_marks` — `Array<String>` of Tk mark names
- `@auto_close_seq` — monotonic counter for mark names
- `@text_frame` — container frame

### Who Calls It
- `MarkdownEditor#setup_ui` creates it
- `MarkdownEditor` delegates `insert_bold`, `insert_italic`, `insert_h1`, `insert_h2`, `toggle_readonly`, file ops, etc.
- `FindReplaceDialog` reads `@editor.text`, `@editor.highlighter`, `@editor.app`

---

## Class: `MarkdownEditor`

**Responsibility:** Top-level application. Owns the window, menus, toolbar,
notebook, status bar, and the `EditorPane`. Coordinates file I/O, theming,
zoom, and dialogs.

### Public Methods

| Method                     | Returns  | Description                                       |
|----------------------------|----------|---------------------------------------------------|
| `initialize`               | `self`   | Builds root, disables Emacs bindings, sets up UI  |
| `disable_tk_emacs_bindings`| `void`   | Neutralizes Ctrl-B/I/D/K on Text widgets          |
| `setup_ui`                 | `void`   | Builds menubar, toolbar, notebook, status, editor |
| `update_status_left`       | `void`   | Word/char/time count                              |
| `show_header_popup`        | `void`   | Popup listbox of headers; click to jump           |
| `close_header_popup`       | `void`   | Safely destroys popup, releases grab              |
| `open_find_dialog`         | `void`   | Creates or focuses FindReplaceDialog              |
| `insert_bold/italic/h1/h2` | `void`   | Delegates to EditorPane                           |
| `toggle_readonly`          | `void`   | Toggles text widget state                         |
| `new_file`                 | `void`   | Clears buffer, resets state                       |
| `open_file`                | `void`   | Reads file into buffer                            |
| `save_file`                | `void`   | Writes buffer to disk (prompts if unsaved)        |
| `apply_theme`              | `void`   | Applies current theme to all widgets              |
| `apply_font_settings`      | `void`   | Applies base font size + line spacing             |
| `update_header_list`       | `void`   | Delegates to `update_current_header`              |
| `update_current_header`    | `void`   | Updates the Headings button label                 |
| `zoom_in/out/reset_zoom`   | `void`   | Adjust `@base_font_size` (8–24)                   |
| `goto_line_dialog`         | `void`   | Prompt for line number, jump                      |
| `change_spacing(amount)`   | `void`   | Adjust `@line_spacing` (min 0)                    |
| `quit_app`                 | `void`   | Save prompt if modified, then destroy             |
| `run`                      | `void`   | `Tk.mainloop`                                     |

### Public Accessors (attr_accessor)
- `:is_modified`, `:notebook`, `:tab_frame`, `:status_left`, `:root`, `:current_theme`

### Important Instance Variables
- `@current_filename`, `@current_filepath`
- `@base_font_size` (default 12, range 8–24)
- `@line_spacing` (default 4, min 0)
- `@find_dialog`, `@goto_dialog`, `@header_popup`, `@header_popup_scroll`
- `@menubar`, `@toolbar`, `@file_menu`, `@edit_menu`, `@view_menu`, `@theme_menu`
- `@status_left`, `@status_right`, `@status_center`
- `@editor` — the `EditorPane`

### Who Calls It
- The script bottom: `app = MarkdownEditor.new; app.run`
- `EditorPane` callbacks reference `@app` for delegation