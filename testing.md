# Testing Guide

This app has **no automated test suite**. All testing is manual.
Below is a structured checklist for regression testing.

## Manual Test Checklist

### File Operations
- [ ] New file clears editor, tab says "Untitled.md", no `*`
- [ ] Open existing `.md` file → contents appear, tab shows filename
- [ ] Open non-existent file → error dialog, editor unchanged
- [ ] Save new file → save dialog appears, file created on disk
- [ ] Save over existing file → overwrite confirmation
- [ ] Save when file is read-only on disk → error dialog
- [ ] Quit with unsaved changes → yes/no/cancel prompt
- [ ] Quit with no changes → exits immediately
- [ ] Tab shows `* ` prefix after first keystroke
- [ ] `* ` prefix removed after save

### Markdown Highlighting
- [ ] `# Header` → H1 styling, `#` is muted
- [ ] `## Header` → H2
- [ ] `###### Header` → H6
- [ ] `#NoSpace` → NOT highlighted (plain text)
- [ ] `**bold**` → bold content, `**` markers muted
- [ ] `*italic*` → italic content, `*` markers muted
- [ ] `***bold+italic***` → only bold applies (parser limitation)
- [ ] Header on line 1, cursor on line 5 → "Headings" button shows header text
- [ ] Multiple headers → popup lists all, indented by level

### Auto-Close Pairs
- [ ] Type `*` with no selection → `**` inserted, cursor between
- [ ] Type `*` again (on tracked closer) → skips over, no duplicate
- [ ] Type `*` elsewhere (not on tracked closer) → inserts literal `*`
- [ ] Type `(` → `()` inserted, cursor between
- [ ] Type `)` on tracked closer → skips over
- [ ] Type `[` → `[]` inserted
- [ ] Type `]` on tracked closer → skips over
- [ ] Arrow Right over `**` → skips 2 chars
- [ ] Arrow Left over `**` → skips 2 chars
- [ ] Open file → auto-close marks reset (typing `*` opens fresh pair)

### Editing Commands
- [ ] Ctrl+B with selection → wraps in `**`
- [ ] Ctrl+B without selection → inserts `****`, cursor in middle
- [ ] Ctrl+I with selection → wraps in `*`
- [ ] Ctrl+I without selection → inserts `**`, cursor in middle
- [ ] Ctrl+Z → undo
- [ ] Ctrl+Y → redo
- [ ] Ctrl+Shift+D → duplicates current line, cursor on new line
- [ ] Ctrl+Up → moves line up (cursor column preserved)
- [ ] Ctrl+Down → moves line down (cursor column preserved)
- [ ] Ctrl+Up on line 1 → no-op
- [ ] Ctrl+Down on last line → no-op
- [ ] Move line with selection → selection moves with it

### List Continuation
- [ ] Type `- item` + Enter → next line starts with `- `
- [ ] Type `* item` + Enter → next line starts with `* `
- [ ] Type `+ item` + Enter → next line starts with `+ `
- [ ] Type `1. item` + Enter → next line starts with `2. `
- [ ] Type `- ` + Enter (empty item) → bullet removed, exits list
- [ ] Indented `- item` + Enter → next line preserves indent

### Find & Replace
- [ ] Ctrl+F → dialog opens
- [ ] Ctrl+F again → focuses existing dialog
- [ ] Find Next → highlights next match, wraps around
- [ ] Find Prev → highlights previous match, wraps around
- [ ] Match Case checked → case-sensitive
- [ ] Regex checked → pattern is regex
- [ ] Invalid regex → error dialog
- [ ] Replace → replaces current selection, finds next
- [ ] Replace All → replaces all, shows count
- [ ] Replace All with backreferences (`\1`) → works
- [ ] Replace All preserves cursor position (clamped)
- [ ] Replace All preserves scroll position
- [ ] Escape → closes dialog

### Navigation
- [ ] "Headings" button → popup appears below button
- [ ] Popup overflows right edge → shifts left to stay in app window
- [ ] Popup overflows bottom → shifts up
- [ ] Double-click header → cursor jumps to that line
- [ ] Return on header → cursor jumps
- [ ] Escape → closes popup
- [ ] Click outside popup → closes popup
- [ ] No headers → popup shows "No Headers Found"
- [ ] Ctrl+G → Go to Line dialog
- [ ] Enter valid line → cursor jumps
- [ ] Enter 0 or negative → error
- [ ] Enter line > total → error
- [ ] Enter non-numeric → error

### View
- [ ] Ctrl+Plus → font grows
- [ ] Ctrl+Minus → font shrinks
- [ ] Ctrl+0 → font resets to 12
- [ ] Font floor at 8, ceiling at 24
- [ ] View → Increase Spacing → line spacing grows
- [ ] View → Decrease Spacing → line spacing shrinks (floor 0)
- [ ] Read-Only Toggle → text becomes uneditable, status shows "Read-Only Mode"
- [ ] Read-Only Toggle again → editable, "Edit Mode"
- [ ] Open file while in read-only → switches back to normal

### Themes
- [ ] Theme → Sepia → warm beige palette
- [ ] Theme → Dark → dark palette
- [ ] Theme switch re-parses entire document
- [ ] All UI elements update: menubar, toolbar, text, scrollbar, menus, status

### Status Bar
- [ ] Word count updates on every KeyRelease
- [ ] Char count includes all characters
- [ ] Reading time = ceil(words / 200), min "< 1 min"
- [ ] Status center shows filename
- [ ] Status right shows "Edit Mode" / "Read-Only Mode"

## Regression Test Triggers

When changing X, re-test Y:
| Change                | Re-test                                              |
|-----------------------|------------------------------------------------------|
| `parse_line` regex    | All header levels, bold, italic, mixed               |
| Auto-close logic      | All 4 pair types, skip behavior, reset on open       |
| `move_line_up/down`   | Selection preservation, cursor column, first/last line |
| `save_file`           | New file, existing file, overwrite, read-only disk   |
| `apply_theme`         | Both themes, all widgets, re-parse                   |
| `replace_all`         | Cursor preservation, scroll preservation, backrefs   |