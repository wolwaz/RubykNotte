#Architecture Overview Purpose

A single-window, tabbed Markdown note editor written in Ruby/Tk. It provides live syntax highlighting, find/replace, header navigation, auto-pairing of *, `, [], and (), line moving/duplication, background crash recovery, and two themes (sepia, dark).High-Level Component Diagram

┌──────────────────────────────────────────────────────────────┐│                        MarkdownEditor                        ││                                                              ││  ┌─────────┐  ┌──────────┐  ┌──────────────────────────────┐││  │ Menubar │  │ Toolbar  │  │          Notebook            │││  └─────────┘  └──────────┘  │  ┌────────────────────────┐  │││                              │  │       Tab Frame        │  │││                              │  │  ┌──────────────────┐  │  │││                              │  │  │    EditorPane    │  │  │││                              │  │  │  ┌────────────┐  │  │  │││                              │  │  │  │   TkText    │  │  │  │││                              │  │  │  └─────┬──────┘  │  │  │││                              │  │  │        │        │  │  │││                              │  │  │ ┌──────┴──────┐  │  │  │││                              │  │  │ │ Highlighter │  │  │  │││                              │  │  │ └─────────────┘  │  │  │││                              │  │  └──────────────────┘  │  │││                              │  └────────────────────────┘  │││                              │  ┌────────────────────────┐  │││                              │  │       Status Bar       │  │││                              │  └────────────────────────┘  │││                              └──────────────────────────────┘││                                                              ││  Dialogs:  FindReplaceDialog · Go-to-Line · Header Popup     │└──────────────────────────────────────────────────────────────┘text
##Ownership Tree

MarkdownEditor  (root TkRoot)    │    ├── owns @menubar           (File / Edit / View / Theme buttons + menus)    ├── owns @toolbar           (Bold / Italic / H1-H6 / Headings / Read-Only)    ├── owns @notebook          (single tab currently)    │       └── @tab_frame    │             ├── @status_bar  (left / center / right labels)    │             └── @editor      (EditorPane)    │                    ├── @text         (TkText)    │                    └── @highlighter  (MarkdownHighlighter)    │    ├── owns @find_dialog       (FindReplaceDialog, lazy)    ├── owns @goto_dialog       (TkToplevel, lazy)    └── owns @header_popup      (TkToplevel, lazy)

| reset_auto_close_tracking     | void   | Unsets all tracked marks                          || insert_bold                   | String | Wraps/inserts **; returns 'break'             || insert_italic                 | String | Wraps/inserts *; returns 'break'              || handle_return                 | void   | List continuation (bullets, numbered)             || parse_after_paste             | void   | Full re-parse after Ctrl+V                        || parse_and_update              | void   | Debounced: parse current line, update headers     || move_line_up                  | void   | Swaps current block with previous (preserves selection) || move_line_down                | void   | Swaps current block with next (preserves selection)   || duplicate_line                | void   | Duplicates current line below                     || cancel_timers                 | void   | Cleans up debounce timer on quit                  |
Public Readers (attr_reader)

    :text — the TkText widget
    :highlighter — the MarkdownHighlighter
    :app — the owning MarkdownEditor
    :debounce_timer — Tk.after handle for parse debounce

##Important Instance Variables

    @debounce_timer — Tk.after handle for parse debounce
    @auto_close_marks — Array<String> of Tk mark names (max 10)
    @auto_close_seq — monotonic counter for mark names
    @text_frame — container frame

Who Calls It

    MarkdownEditor#setup_ui creates it
    MarkdownEditor delegates insert_bold, insert_italic, insert_h1-h6, toggle_readonly, file ops, etc.
    FindReplaceDialog reads @editor.text, @editor.highlighter, @editor.app

##Class: MarkdownEditor

Responsibility: Top-level application. Owns the window, menus, toolbar,notebook, status bar, and the EditorPane. Coordinates file I/O, theming,zoom, background backups, and dialogs.
Public Methods
Method	Returns	Description
initialize	self	Builds root, disables Emacs bindings, sets up UI
disable_tk_emacs_bindings	void	Neutralizes Ctrl-B/I/K/F/G/S/O/N/Q on Text widgets
setup_ui	void	Builds menubar, toolbar, notebook, status, editor
update_status_left	void	Word/char/time count
show_header_popup	void	Popup listbox of headers; click to jump
close_header_popup	void	Safely destroys popup, releases scroll
open_find_dialog	void	Creates or focuses FindReplaceDialog
insert_bold/italic/h1-h6	void	Delegates to EditorPane or inserts header marks
toggle_readonly	void	Toggles text widget state
new_file	void	Clears buffer, rotates backup, resets state
open_file	void	Reads file into buffer, resets state
open_recovery_file	void	Loads recovery.md into a new Untitled buffer
save_file	void	Writes buffer to disk (prompts if unsaved)
save_as_file	void	Prompts for path, confirms overwrite, saves
apply_theme	void	Applies current theme to all widgets
apply_font_settings	void	Applies base font size + line spacing
update_header_list	void	Delegates to rebuild_headers_cache & update_current_header
update_current_header	void	Updates the Headings button label
zoom_in/out/reset_zoom	void	Adjust @base_font_size (8–24)
goto_line_dialog	void	Prompt for line number, jump
change_spacing(amount)	void	Adjust @line_spacing (min 0)
quit_app	void	Save prompt if modified, then destroy
schedule_next_backup_check	void	Sets next Tk.after timer for backup check
check_backup	void	Checks if 5s idle time reached to trigger backup
perform_background_backup	void	Extracts text, calls write_backup_atomic
write_backup_atomic	void	Writes to tmp file, moves to recovery.md
rotate_backups	void	Moves recovery.md to .bak
emergency_save!	void	Called on exception, triggers backup write
run	void	Tk.mainloop
Public Accessors (attr_accessor)

    :is_modified, :notebook, :tab_frame, :status_left, :root, :current_theme, :last_keypress_time

##Important Instance Variables

    @current_filename, @current_filepath
    @base_font_size (default 12, range 8–24)
    @line_spacing (default 4, min 0)
    @find_dialog, @goto_dialog, @header_popup, @header_popup_scroll
    @menubar, @toolbar, @file_menu, @edit_menu, @view_menu, @theme_menu
    @status_left, @status_right, @status_center
    @editor — the EditorPane
    @backup_dir, @backup_file — paths for crash recovery
    @backup_check_timer, @backup_check_proc, @backup_due_time — backup loop state

Who Calls It

    The script bottom: app = MarkdownEditor.new; app.run
    EditorPane callbacks reference @app for delegation
