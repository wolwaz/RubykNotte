# Event Flow

This document traces what happens for every user action.

## File operations

### Ctrl+O → `open_file`

```
Ctrl+O
  ↓
confirm_discard_changes('opening another file')
  ├── cancel / failed save → abort
  └── ok
        ↓
Tk.getOpenFile
  ↓
File.read(filename)
  ↓
rotate_backups
  ↓
text.delete + text.value = content
reset_auto_close_tracking
edit_reset
  ↓
@current_filepath / @current_filename
@is_modified = false
  ↓
highlighter.parse_entire_document
update_current_header
```

### Ctrl+S → `save_file`

```
Ctrl+S
  ↓
@current_filepath.nil?
  ├── yes → save_as_file (Tk.getSaveFile + overwrite confirm)
  └── no  → File.write
        ↓
@is_modified = false
tab name loses "* " prefix
```

### Ctrl+Shift+S → `save_as_file`

Prompts for a path, confirms overwrite if the file exists, then `save_file`.

### Ctrl+N → `new_file`

```
Ctrl+N
  ↓
confirm_discard_changes('creating a new document')
  ↓
rotate_backups
  ↓
text.delete('1.0', 'end')
reset_auto_close_tracking
edit_reset
remove tags
  ↓
Untitled.md, no path, @is_modified = false
```

### Ctrl+Q → `quit_app`

If modified: Yes → `save_file` (abort quit if still modified), No → destroy, Cancel → abort. Then cancel backup and debounce timers.

### Open Recovery Backup

```
File → Open Recovery Backup…
  ↓
none → "No Recovery Data"
both → Yes = primary, No = secondary (timestamps shown)
  ↓
confirm_discard_changes('opening recovery backup')
  ↓
read chosen file
  ↓
clear buffer WITHOUT new_file / rotate_backups
  ↓
Untitled.md, @is_modified = true, full parse
```

## Editing commands

### Ctrl+B / Ctrl+I

Wrap selection in `**` / `*`, or insert `****` / `**` with the cursor in the middle.

### Return → `handle_return`

```
Return
  ↓
before/after cursor are only asterisks (***|*** or similar)?
  ├── yes → delete mirrored closers, mark modified,
  │         after(0) parse_line(line, true)  → HR bar
  │         return nil so Tk still inserts the newline
  ↓
bullet list line?
  ├── empty bullet → delete line (exit list)
  └── else after(0) insert same bullet on the new line
  ↓
numbered list line?
  ├── empty "N." → delete line
  └── else after(0) insert N+1
  ↓
else default Return
```

### Ctrl+Shift+D / Ctrl+Up / Ctrl+Down

Duplicate current line; move current line or selected block up/down, re-applying `sel` when there was a selection.

## Auto-close pair flow

### Typing `*` or `` ` `` (no selection)

Tk inserts the character, then `after(0)` inserts a matching closer and moves the cursor back. Always scaffolds (no skip-on-closer). Right/Left arrow still skip `*` / `**` / `` ` `` / `` `` ``.

### Typing `[` or `(`

If the next character is the tracked closer, skip it. Otherwise `after(0)` inserts the closer, places the cursor between, and `register_auto_close_mark`.

### Typing `]` or `)`

If next character matches and a mark sits at the cursor, skip and consume the mark. Otherwise insert literally.

## Debounced parse

Any KeyRelease cancels the previous 300ms timer and starts a new one → `parse_and_update` (current + previous line, header cache, status).

Ctrl+V schedules `parse_after_paste` after 100ms (full document).

First non-navigation keystroke after a clean save calls `mark_modified` (tab gets `* `).

## Find & Replace

Ctrl+F focuses an existing dialog or creates one. Find Next/Prev wrap. Replace All gsub's the whole document, restores cursor line and yview, then full-parses.

## Header navigation

Headings button builds a borderless listbox of cached headers, highlights the current section, clamps to the screen, jumps on Return/double-click, closes on Escape or outside click.

## Zoom / spacing / padding

- Ctrl++ / Ctrl+= → font size up (max 24)
- Ctrl+- → font size down (min 8)
- Ctrl+0 → 12
- View → Increase/Decrease Line Spacing (min 0)
- View → Increase/Decrease Text Padding (min 2)

Each path calls `apply_font_settings` (widget font, spacing1/2/3, padx/pady, highlighter fonts).

## Theme switch

Sets `@current_theme` and `apply_theme`: root, text colors, ttk styles, menus, highlighter tag colors. Existing tags pick up new colors without a full re-parse.

## Background backup & crash recovery

```
App start
  ↓
rotate_backups          ← recovery.md becomes recovery.md.bak
  ↓
schedule_next_backup_check(10000)
  ↓
if modified and idle > 2s (or due ≥ 5s while still typing)
  → atomic write to recovery.md
```

On uncaught exception: `emergency_save!` then `Tk.exit`.
