Event Flow

This document traces what happens for every user action.
File Operations
Ctrl+O → `open_file

Ctrl+O
  ↓
MarkdownEditor#open_file
  ↓
Tk.getOpenFile (user picks file)
  ↓
File.read(filename)
  ↓
@editor.text.value = content
  ↓
@editor.reset_auto_close_tracking
  ↓
@current_filepath = filename
@current_filename = File.basename(filename)
@is_modified = false
  ↓
notebook.itemconfigure(tab, text: filename)
status_center.text = filename
  ↓
update_status_left
  ↓
highlighter.parse_entire_document
  ↓
update_header_list
  ↓
[INVARIANTS: see architecture.md#after-open_file]
text
 
  
 
 

### Ctrl+S → `save_file
 
 

Ctrl+S
  ↓
MarkdownEditor#save_file
  ↓
@current_filepath.nil?
  ├── yes → Tk.getSaveFile
  │          ↓
  │          File.exist? → confirm overwrite?
  │          ↓
  │          @current_filepath = chosen
  └── no  → skip
  ↓
File.write(filepath, text.get('1.0', 'end - 1 char'))
  ↓
@is_modified = false
  ↓
notebook.itemconfigure(tab, text: filename)   ← removes the "* " prefix
status_center.text = filename
update_status_left
  ↓
[INVARIANTS: see architecture.md#after-save_file]
text
 
  
 
 

### Ctrl+N → `new_file
 
 

Ctrl+N
  ↓
text.state = 'normal'
text.value = ""
reset_auto_close_tracking
text.edit_reset
  ↓
remove all tags from '1.0' to 'end'
  ↓
@is_modified = false
@current_filename = 'Untitled.md'
@current_filepath = nil
  ↓
notebook.itemconfigure(tab, text: 'Untitled.md')
status_center.text = 'Untitled.md'
update_status_left
update_header_list
text
 
  
 
 

### Ctrl+Q → `quit_app
 
 

Ctrl+Q
  ↓
@is_modified?
  ├── yes → messageBox yes/no/cancel
  │          ├── yes   → save_file → destroy (only if save succeeded)
  │          ├── no    → destroy
  │          └── cancel → abort
  └── no  → destroy
text
 
  
 
 

---

## Editing Commands

### Ctrl+B → `insert_bold
 
 

Ctrl+B
  ↓
selection?
  ├── yes → insert '' at sel.last
  │          insert '' at sel.first
  │          remove 'sel' tag
  │          mark_set('insert', sel.last + 4 chars)
  └── no  → insert '****'
            mark_set('insert', insert - 2 chars)
  ↓
return 'break'   ← prevents Tk default
text
 
  
 
 

### Ctrl+I → `insert_italic
 
 

Ctrl+I
  ↓
selection?
  ├── yes → insert '' at sel.last
  │          insert '' at sel.first
  │          remove 'sel' tag
  │          mark_set('insert', sel.last + 2 chars)
  └── no  → insert '**'
            mark_set('insert', insert - 1 char)
text
 
  
 
 

### Return (Enter) → `handle_return
 
 

Return
  ↓
read current line
  ↓
matches /^(\s*)([-+])\s+/ ?
  ├── yes → line is just bullet? (strip == bullet)
  │          ├── yes → delete line (exit list)
  │          └── no  → insert "#{indent}#{bullet} " on next line
  └── matches /^(\s)(\d+).\s+/ ?
           ├── yes → line is just "N."?
           │          ├── yes → delete line (exit list)
           │          └── no  → insert "#{indent}#{num+1}. " on next line
           └── no  → default Return (Tk inserts newline)
text
 
  
 
 

### Ctrl+Shift+D → `duplicate_line
 
 

Ctrl+Shift+D
  ↓
current_line = insert line number
line_text = get(line.0, line.end)
  ↓
insert "\n#{line_text}" at line.end
  ↓
mark_set('insert', (line+1).0)
see('insert')
  ↓
highlighter.parse_line(line + 1)
text
 
  
 
 

### Ctrl+Up → `move_line_up
 
 

Ctrl+Up
  ↓
current_line <= 1? → no-op
  ↓
capture selection (if any)
capture cursor column
  ↓
read current line text
read previous line text
  ↓
replace(prev.0, current.end, "#{current}\n#{prev}")
  ↓
if selection: shift selection line numbers by -1
  ↓
mark_set('insert', (current_line - 1).col)
see('insert')
  ↓
parse_line(current_line)
parse_line(current_line - 1)
text
 
  
 
 

### Ctrl+Down → `move_line_down`
(Mirror of Ctrl+Up; swaps with next line instead of previous.)

---

## Auto-Close Pair Flow

### Typing `*` (or `` ` ``) with no selection
 
 

KeyPress ''
  ↓
selection empty? → yes
  ↓
PAIR_OPEN_TO_CLOSE.key?('') → yes (closer = '')
  ↓
SYMMETRIC_PAIR_CHARS.include?('') → yes
  ↓
next_char == '' AND consume_auto_close_mark?
  ├── yes → this '' was meant to close
  │          ↓
  │          mark_set('insert', 'insert + 1 char')   ← skip over
  │          return 'break'
  └── no  → Tk.after(0) {
              insert('')        ← the opener
              insert('')        ← the closer
              register_auto_close_mark   ← track the closer
              mark_set('insert', 'insert - 1 char')  ← cursor between
            }
text
 
  
 
 

### Typing `)` or `]
 
 

KeyPress ')'
  ↓
selection empty? → yes
  ↓
PAIR_CLOSER_CHARS.include?(',') → yes
  ↓
next_char == ')' AND consume_auto_close_mark?
  ├── yes → mark_set('insert', 'insert + 1 char')  ← skip
  │          return 'break'
  └── no  → fall through; Tk inserts literal ')'
text
 
  
 
 

### Arrow Key Skip Logic
 
 

Right arrow
  ↓
next_two = get(insert, insert + 2 chars)
next_one = next_two[0]
prev_char = get(insert - 1 char, insert)
  ↓
next_two == '**' or '``'   → skip 2 chars
next_one in ['*','`']      → skip 1 char
next_one == ']' && prev == '[' → skip 1 char
next_one == ')' && prev == '(' → skip 1 char
otherwise → normal Right
text
 
  
 
 
(Left arrow is the mirror.)

---

## Debounced Parse Flow

 
 

Any KeyRelease
  ↓
Tk.after_cancel(@debounce_timer) if @debounce_timer
  ↓
@debounce_timer = Tk.after(300, method(:parse_and_update))
  ↓
[300ms passes with no further KeyRelease]
  ↓
parse_and_update
  ↓
highlighter.parse_current_line   ← parses current + previous line
  ↓
app.update_header_list
  ↓
app.update_current_header
text
 
  
 
 

Also, on every KeyRelease (immediately, not debounced):
 
 

app.update_status_left   ← word/char/time count
text
 
  
 
 

And on first keystroke after save:
 
 

@is_modified == false?
  ↓
@is_modified = true
  ↓
tab text doesn't start with ''?
  ↓
notebook.itemconfigure(tab, text: " #{current_text}")
text
 
  
 
 

---

## Ctrl+V (Paste) Flow
 
 

Ctrl+V
  ↓
Tk.after(50, method(:parse_after_paste))   ← deferred so paste completes first
  ↓
[50ms]
  ↓
highlighter.parse_entire_document
  ↓
app.update_header_list
  ↓
app.update_status_left
text
 
  
 
 

---

## Find & Replace Flow

### Ctrl+F → `open_find_dialog
 
 

Ctrl+F
  ↓
@find_dialog&.exist?
  ├── yes → @find_dialog.focus
  └── no  → FindReplaceDialog.new(@root, @editor)
text
 
  
 
 

### Find Next (in dialog)
 
 

"Find Next" clicked / Return in find entry
  ↓
build_pattern(find_text)   ← Regexp.escape unless regex checkbox
  ↓
document_text = text.get('1.0', 'end - 1 char')
cursor_offset = count chars from '1.0' to 'insert'
  ↓
direction == :forward?
  ├── yes → regex.match(text, cursor + 1)
  │          ↓ miss? → regex.match(text, 0)   ← wrap
  └── no  → scan all matches; find last before cursor
            ↓ miss? → use last overall match  ← wrap
  ↓
match found?
  ├── yes → tag_remove('sel', '1.0', 'end')
  │          tag_add('sel', match_start, match_end)
  │          mark_set('insert', match_start)
  │          see(match_start)
  └── no  → messageBox "Cannot find: ..."
text
 
  
 
 

### Replace All
 
 

"Replace All" clicked
  ↓
build_pattern
  ↓
text = document_text
count = text.scan(regex).size
  ↓
new_text = text.gsub(regex, replace_text)   ← supports \0, \1, etc.
  ↓
save cursor index + yview first
  ↓
text.replace('1.0', 'end - 1 char', new_text)
  ↓
restore cursor (clamped to new length)
restore yview
  ↓
highlighter.parse_entire_document
app.update_header_list
  ↓
messageBox "Replaced N occurrences."
text
 
  
 
 

---

## Header Navigation Flow

### Click "Headings" button → `show_header_popup
 
 

Button click
  ↓
close_header_popup (if open)
  ↓
headers = highlighter.get_headers
  ↓
create TkToplevel (overrideredirect = true → borderless popup)
  ↓
build TkListbox with headers (indented by level)
  ↓
if headers empty → insert "No Headers Found", disable listbox
else → highlight current header line, see(it)
  ↓
Tk.update_idletasks   ← force geometry calculation
  ↓
clamp popup position to app window + screen bounds
  ↓
@header_popup.geometry("+#{x}+#{y}")
  ↓
deiconify, raise, grab_set
list.focus
text
 
  
 
 

### Double-click / Return in popup
 
 

list.curselection
  ↓
headers[sel_idx][:line]
  ↓
text.mark_set('insert', "#{line}.0")
text.see("#{line}.0")
text.focus
  ↓
close_header_popup
text
 
  
 
 

---

## Zoom Flow
 
 

Ctrl+Plus / Ctrl+Equal
  ↓
zoom_in
  ↓
@base_font_size = [24, @base_font_size + 1].min
  ↓
apply_font_settings
  ↓
text.configure(font: [..., @base_font_size], spacing1/2/3: @line_spacing)
highlighter.apply_font_settings(@base_font_size)
text
 
  
 
 
(Ctrl+Minus and Ctrl+0 are mirrors; floor is 8, reset is 12.)

---

## Theme Switch Flow
 
 

Theme menu → "Dark"
  ↓
@current_theme = :dark
  ↓
apply_theme
  ↓
c = Theme::THEMES[:dark]
  ↓
root.background(c[:window_bg])
text.background/foreground/insertbackground/selectbackground
  ↓
Tile::Style.configure for TFrame, Toolbar.TFrame, Status.TFrame, Tab.TFrame,
  TButton, Toolbar.TButton, Menubar.TButton, TLabel, Status.TLabel,
  TNotebook, TNotebook.Tab, Vertical.TScrollbar
  ↓
Tile::Style.map for hover/pressed/focus states
  ↓
configure each TkMenu (file/edit/view/theme)
  ↓
highlighter.apply_theme(c)
  ↓
  └── parse_entire_document   ← re-parse so md_symbol + h1-h6 pick up new colors