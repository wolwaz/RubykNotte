# frozen_string_literal: true

class FindReplaceDialog
  def initialize(root, editor)
    @editor = editor
    @text = editor.text
    @root = root
    @callback_refs = []

    @dialog = TkToplevel.new(@root) { title "Find & Replace" }
    @dialog.transient(@root)
    # Let content size the window; no fixed 450x200

    @match_case = TkVariable.new(false)
    @use_regex = TkVariable.new(false)

    build_ui
    apply_theme_to_dialog

    dialog_close_proc = proc { @dialog.destroy }
    @callback_refs << dialog_close_proc
    @dialog.protocol('WM_DELETE_WINDOW', dialog_close_proc)
    @dialog.grab_set
    @dialog.focus
    @find_entry.focus
  end

  def exist?
    @dialog && @dialog.exist?
  end

  def focus
    @dialog.focus
  end

  def build_ui
    me = self

    @find_label = Tk::Tile::Label.new(@dialog) { text "Find:" }
    @find_label.grid(row: 0, column: 0, padx: 10, pady: 10, sticky: 'w')
    @find_entry = Tk::Tile::Entry.new(@dialog) { width 35 }
    @find_entry.grid(row: 0, column: 1, padx: 10, pady: 10, columnspan: 2, sticky: 'ew')

    @replace_label = Tk::Tile::Label.new(@dialog) { text "Replace:" }
    @replace_label.grid(row: 1, column: 0, padx: 10, pady: 5, sticky: 'w')
    @replace_entry = Tk::Tile::Entry.new(@dialog) { width 35 }
    @replace_entry.grid(row: 1, column: 1, padx: 10, pady: 5, columnspan: 2, sticky: 'ew')

    @match_case_cb = Tk::Tile::CheckButton.new(@dialog) { text "Match Case"; variable @match_case }
    @match_case_cb.grid(row: 2, column: 1, padx: 5, pady: 5, sticky: 'w')
    @use_regex_cb = Tk::Tile::CheckButton.new(@dialog) { text "Regex"; variable @use_regex }
    @use_regex_cb.grid(row: 2, column: 2, padx: 5, pady: 5, sticky: 'w')

    @btn_frame = Tk::Tile::Frame.new(@dialog)
    @btn_frame.grid(row: 3, column: 0, columnspan: 3, pady: 15)

    find_backward_proc = proc { me.find(:backward) }
    @callback_refs << find_backward_proc
    @find_prev_btn = Tk::Tile::Button.new(@btn_frame) { text "Find Prev"; command find_backward_proc }
    @find_prev_btn.pack(side: 'left', padx: 5)

    find_forward_proc = proc { me.find(:forward) }
    @callback_refs << find_forward_proc
    @find_next_btn = Tk::Tile::Button.new(@btn_frame) { text "Find Next"; command find_forward_proc }
    @find_next_btn.pack(side: 'left', padx: 5)

    replace_current_proc = proc { me.replace_current }
    @callback_refs << replace_current_proc
    @replace_btn = Tk::Tile::Button.new(@btn_frame) { text "Replace"; command replace_current_proc }
    @replace_btn.pack(side: 'left', padx: 5)

    replace_all_proc = proc { me.replace_all }
    @callback_refs << replace_all_proc
    @replace_all_btn = Tk::Tile::Button.new(@btn_frame) { text "Replace All"; command replace_all_proc }
    @replace_all_btn.pack(side: 'left', padx: 5)

    @dialog.grid_columnconfigure(1, weight: 1)

    find_entry_return_proc = proc { me.find(:forward) }
    @callback_refs << find_entry_return_proc
    @find_entry.bind('Return', find_entry_return_proc)

    dialog_escape_proc = proc { @dialog.destroy }
    @callback_refs << dialog_escape_proc
    @dialog.bind('Escape', dialog_escape_proc)
  end

  def apply_theme_to_dialog
    return unless @editor && @editor.app
    c = Theme::THEMES[@editor.app.current_theme] || Theme::THEMES[:sepia]
    @dialog.background(c[:window_bg])
    # ttk widgets pick up styles from the app's apply_theme; just set toplevel bg
  end

  def document_text
    @text.get('1.0', 'end - 1 char')
  end

  def cursor_char_offset
    n = @text.count('1.0', 'insert', 'chars')
    n = n.first if n.is_a?(Array)
    (n || 0).to_i
  end

  def char_offset_to_index(char_offset)
    @text.index("1.0 + #{char_offset} chars")
  end

  def build_pattern(pattern_text)
    flags = @match_case.value == '1' ? 0 : Regexp::IGNORECASE
    @use_regex.value == '1' ? Regexp.new(pattern_text, flags) : Regexp.new(Regexp.escape(pattern_text), flags)
  end

  def find(direction)
    pattern_text = @find_entry.value
    return if pattern_text.empty?

    begin
      regex = build_pattern(pattern_text)
    rescue RegexpError => e
      Tk.messageBox(type: 'ok', icon: 'error', title: "Invalid Pattern", message: e.message)
      return
    end

    text = document_text
    char_offset = cursor_char_offset
    m = nil

    if direction == :forward
      m = regex.match(text, char_offset + 1)
      m ||= regex.match(text, 0)
    else
      last_before = nil
      last_overall = nil
      text.scan(regex) do
        cur = Regexp.last_match
        last_overall = cur
        last_before = cur if cur.begin(0) < char_offset
      end
      m = last_before || last_overall
    end

    if m
      match_start = char_offset_to_index(m.begin(0))
      match_end   = char_offset_to_index(m.end(0))
      @text.tag_remove('sel', '1.0', 'end')
      @text.tag_add('sel', match_start, match_end)
      @text.mark_set('insert', match_start)
      @text.see(match_start)
    else
      Tk.messageBox(type: 'ok', icon: 'info', title: "Not Found", message: "Cannot find: \"#{pattern_text}\"")
    end
  end

  def replace_current
    if @text.tag_ranges('sel').any?
      match_start = @text.index('sel.first')
      match_end   = @text.index('sel.last')

      @text.edit_separator
      @text.replace(match_start, match_end, @replace_entry.value)
      @text.edit_separator
      @editor.app.mark_modified

      @editor.highlighter.parse_entire_document
      @editor.app.update_header_list

      @text.mark_set('insert', match_start)
      find(:forward)
    else
      find(:forward)
    end
  end

  def replace_all
    pattern_text = @find_entry.value
    replace_text = @replace_entry.value
    return if pattern_text.empty?

    begin
      regex = build_pattern(pattern_text)
    rescue RegexpError => e
      Tk.messageBox(type: 'ok', icon: 'error', title: "Invalid Pattern", message: e.message)
      return
    end

    text = document_text
    replace_count = text.scan(regex).size
    
    cursor_line = @text.index('insert').split('.')[0].to_i
    first, _last = @text.yview

    if @use_regex.value == '1'
      new_text = text.gsub(regex, replace_text)
    else
      new_text = text.gsub(regex) { replace_text }
    end

    @text.edit_separator
    @text.replace('1.0', 'end - 1 char', new_text)
    @text.edit_separator
    @editor.app.mark_modified if new_text != text

    total_lines = @text.index('end').split('.')[0].to_i - 1
    cursor_line = [cursor_line, total_lines].min
    @text.mark_set('insert', "#{cursor_line}.0")

    @text.yview_moveto(first)

    @editor.highlighter.parse_entire_document
    @editor.app.update_header_list

    Tk.messageBox(type: 'ok', icon: 'info', title: "Replace All", message: "Replaced #{replace_count} occurrences.")
  end
end
