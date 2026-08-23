# Testing Guide

Automated tests live in `test/regression_test.rb` and run in GitHub Actions:

```bash
ruby -c tknote.rb
ruby -Itest test/regression_test.rb
```

The suite loads application classes **without** starting Tk/Tile. It is not a substitute for the GUI checklist below.

## Automated coverage (v0.3.0)

- H1–H6 header discovery
- Bold, italic, bold+italic, inline code, strikethrough, blockquote, and HR tags
- Backward Find wrap-around
- Italic insertion without a selection
- Empty-line duplication
- Open file loads contents and clears modified (after discard confirm)
- Open/New abort when unsaved-change confirmation is cancelled
- New file clears the buffer
- HR Enter shortcut keeps `***` and drops the mirrored closers
- Save-and-quit does not destroy the window if save did not clear modified

## Manual test checklist

### File operations
- [ ] New file clears editor, tab says "Untitled.md", no `*`
- [ ] New with unsaved changes → Save / Don't Save / Cancel
- [ ] Open existing `.md` file → contents appear, tab shows filename
- [ ] Open with unsaved changes → Save / Don't Save / Cancel
- [ ] Open non-existent / unreadable file → error dialog, editor unchanged
- [ ] Save new file → save dialog appears, file created on disk
- [ ] Save As (Ctrl+Shift+S) → prompts for new filename, checks overwrite
- [ ] Save when file is read-only on disk → error dialog
- [ ] Quit with unsaved changes → yes/no/cancel prompt
- [ ] Quit with no changes → exits immediately
- [ ] Tab shows `* ` prefix after first keystroke
- [ ] `* ` prefix removed after save

### Crash recovery & backups
- [ ] Type text, wait 5+ seconds → `~/.markdown_editor_backups/recovery.md` is updated
- [ ] Kill app process (crash) → `emergency_save!` triggers, recovery.md contains latest text
- [ ] Restart app → previous `recovery.md` rotated to `recovery.md.bak`
- [ ] Open Recovery Backup → choose primary/secondary by timestamp, confirm discard, opens Untitled marked modified
- [ ] Open Recovery Backup does **not** delete the file that was just loaded
- [ ] No recovery data exists → "No Recovery Data" info dialog

### Markdown highlighting
- [ ] `# Header` → H1 styling, `#` is muted
- [ ] `##` … `######` → H2–H6
- [ ] `#NoSpace` → NOT highlighted (plain text)
- [ ] `**bold**` → bold content, `**` markers muted
- [ ] `*italic*` → italic content, `*` markers muted
- [ ] `***bold+italic***` → bold italic content, `***` muted
- [ ] `` `code` `` → code colors, backticks muted
- [ ] `~~strike~~` → strikethrough
- [ ] `> quote` → indented, muted quote
- [ ] `---` / `***` / `___` on their own line → separator bar after leaving the line
- [ ] Typing on an HR line shows the raw markers, not the bar
- [ ] Header on line 1, cursor on line 5 → "Headings" button shows header text
- [ ] Multiple headers → popup lists all, indented by level

### Auto-close pairs
- [ ] Type `*` with no selection → `**` inserted, cursor between
- [ ] Type `*` again → scaffolds toward `****` / `***|***` (always scaffold)
- [ ] Type `(` → `()` inserted, cursor between
- [ ] Type `)` on tracked closer → skips over
- [ ] Type `[` → `[]` inserted
- [ ] Type `]` on tracked closer → skips over
- [ ] Arrow Right over `**` → skips 2 chars
- [ ] Arrow Left over `**` → skips 2 chars
- [ ] Open file → auto-close marks reset
- [ ] Max 10 tracked `[`/`(` marks → typing 11+ pairs unsets older marks

### Editing commands
- [ ] Ctrl+B with selection → wraps in `**`
- [ ] Ctrl+B without selection → inserts `****`, cursor in middle
- [ ] Ctrl+I with selection → wraps in `*`
- [ ] Ctrl+I without selection → inserts `**`, cursor in middle
- [ ] Ctrl+Z → undo
- [ ] Ctrl+Y → redo
- [ ] Ctrl+Shift+D → duplicates current line, cursor on new line
- [ ] Ctrl+Up / Ctrl+Down → moves line (cursor column preserved)
- [ ] Ctrl+Up on line 1 / Ctrl+Down on last line → no-op
- [ ] Move line with multi-line selection → block moves, selection preserved
- [ ] Type `***` (scaffolded `***|***`) + Enter → line becomes `***` HR, newline below

### List continuation
- [ ] Type `- item` + Enter → next line starts with `- `
- [ ] Type `* item` + Enter → next line starts with `* `
- [ ] Type `+ item` + Enter → next line starts with `+ `
- [ ] Type `1. item` + Enter → next line starts with `2. `
- [ ] Type `- ` + Enter (empty item) → bullet removed, exits list
- [ ] Indented `- item` + Enter → next line preserves indent

### Find & Replace
- [ ] Ctrl+F → dialog opens
- [ ] Ctrl+F again → focuses existing dialog
- [ ] Find Next / Prev wrap around
- [ ] Match Case / Regex
- [ ] Invalid regex → error dialog
- [ ] Replace → replaces current selection, finds next
- [ ] Replace All → replaces all, shows count, keeps scroll
- [ ] Escape → closes dialog

### Navigation
- [ ] "Headings" button → popup appears below button
- [ ] Popup stays on screen if it would overflow
- [ ] Double-click / Return → jump
- [ ] Escape / click outside → close
- [ ] No headers → "No Headers Found"
- [ ] Ctrl+G → Go to Line; valid jump; 0 / too large / non-numeric error
- [ ] Escape closes Go to Line

### View
- [ ] Ctrl+Plus / Minus / 0 → zoom 8–24, reset 12
- [ ] Increase/Decrease Line Spacing (floor 0)
- [ ] Increase/Decrease Text Padding (floor 2)
- [ ] Read-Only Toggle → uneditable, status "Read-Only Mode"
- [ ] Open file while in read-only → switches back to normal

### Themes
- [ ] Theme → Sepia / Dark
- [ ] Code, quote, HR, and strike colors follow the theme
- [ ] All UI elements update: menubar, toolbar, text, scrollbar, menus, status

### Status bar
- [ ] Word / char / reading time update after typing pauses
- [ ] Status center shows filename
- [ ] Status right shows "Edit Mode" / "Read-Only Mode"

## Regression test triggers

When changing X, re-test Y:

| Change | Re-test |
|---|---|
| `parse_line` regex | Headers, bold, italic, `***`, code, strike, quote, HR |
| Auto-close logic | Scaffold `*` / `` ` ``, skip `[` / `(`, reset on open |
| `handle_return` | Lists + HR shortcut |
| `move_line_up/down` | Selection preservation, first/last line |
| `save_file` / `save_as_file` / `confirm_discard_changes` | New, Open, Recovery, Quit |
| `apply_theme` | Both themes, code/quote/HR/strike tags |
| `replace_all` | Cursor, scroll, backrefs |
| Backup logic | Idle trigger, startup rotate, recovery without clobber |
