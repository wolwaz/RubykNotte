require 'tk'

# ==========================================
# 0. CENTRALIZED DESIGN SYSTEM
# ==========================================
module Theme
  SPACING = {
    xs: 4, sm: 6, md: 8, lg: 12, xl: 16,
    editor_x: 25, editor_y: 20
  }

  FONTS = {
    ui: ['Noto Sans', 10],
    editor: ['Noto Sans', 12] 
  }

  THEMES = {
    sepia: {
      window_bg: '#EFE6D2', toolbar_bg: '#E8DDC7', status_bg: '#E8DDC7',
      editor_bg: '#F8F1E3', text_fg: '#3E2C1F', muted_fg: '#705E4B',
      border: '#C8BDA8', button_bg: '#E5DAC1', button_hover: '#D9CBB0',
      button_pressed: '#CCBDA0', accent: '#3DAEE9', selection: '#B9DDF2',
      menu_hover: '#D9CBB0', md_symbol: '#A08C70'
    },
    dark: {
      window_bg: '#2B2420', toolbar_bg: '#241F1C', status_bg: '#241F1C',
      editor_bg: '#2F2925', text_fg: '#E2D5C2', muted_fg: '#AFA18E',
      border: '#4A4038', button_bg: '#39312C', button_hover: '#474039',
      button_pressed: '#51473E', accent: '#5AAFE3', selection: '#3E6E8C',
      menu_hover: '#474039', md_symbol: '#81705C'
    }
  }
end

# ==========================================
# 1. MARKDOWN HIGHLIGHTER
# ==========================================
class MarkdownHighlighter
  def initialize(text_widget)
    @text = text_widget
    @current_headers = []
    setup_tags
  end

  def byte_to_char_offset(str, byte_offset)
    byte_offset = [0, [byte_offset, str.bytesize].min].max
    str.byteslice(0, byte_offset).length
  end

  def setup_tags
    f = Theme::FONTS[:editor]
    @text.tag_configure('md_symbol', foreground: '#888888')
    @text.tag_configure('bold', font: [f[0], f[1], 'bold'])
    @text.tag_configure('italic', font: [f[0], f[1], 'italic'])
    @text.tag_configure('h1', font: [f[0], f[1] + 6, 'bold'], foreground: '#333333')
    @text.tag_configure('h2', font: [f[0], f[1] + 4, 'bold'], foreground: '#444444')
    @text.tag_raise('md_symbol')
  end

  def apply_theme(colors)
    @text.tag_configure('md_symbol', foreground: colors[:md_symbol])
    @text.tag_configure('h1', foreground: colors[:text_fg])
    @text.tag_configure('h2', foreground: colors[:text_fg])
    parse_entire_document
  end

  def apply_font_settings(base_font_size)
    f = Theme::FONTS[:editor]
    @text.tag_configure('bold', font: [f[0], base_font_size, 'bold'])
    @text.tag_configure('italic', font: [f[0], base_font_size, 'italic'])
    @text.tag_configure('h1', font: [f[0], base_font_size + 6, 'bold'])
    @text.tag_configure('h2', font: [f[0], base_font_size + 4, 'bold'])
  end

  def parse_line(line_num)
    start_idx = "#{line_num}.0"
    end_idx = "#{line_num}.end"
    line_text = @text.get(start_idx, end_idx)

    ['h1', 'h2', 'bold', 'italic', 'md_symbol'].each do |tag|
      @text.tag_remove(tag, start_idx, end_idx)
    end

    if line_text.match(/^#{1,6}\s*(.*)/)
      hash_count = line_text.match(/^#+/)[0].length
      if hash_count == 1
        @text.tag_add('h1', start_idx, end_idx)
        @text.tag_add('md_symbol', "#{line_num}.0", "#{line_num}.1")
      elsif hash_count == 2
        @text.tag_add('h2', start_idx, end_idx)
        @text.tag_add('md_symbol', "#{line_num}.0", "#{line_num}.2")
      end
    end

    line_text.scan(/\*\*(?!\*)(.+?)(?<!\*)\*\*/) do
      m = Regexp.last_match
      content_start = byte_to_char_offset(line_text, m.begin(1))
      content_end   = byte_to_char_offset(line_text, m.end(1))
      symbol_start  = byte_to_char_offset(line_text, m.begin(0))

      @text.tag_add('bold', "#{line_num}.#{content_start}", "#{line_num}.#{content_end}")
      @text.tag_add('md_symbol', "#{line_num}.#{symbol_start}", "#{line_num}.#{symbol_start + 2}")
      @text.tag_add('md_symbol', "#{line_num}.#{content_end}", "#{line_num}.#{content_end + 2}")
    end

    line_text.scan(/(?<!\*)\*([^*]+?)\*(?!\*)/) do
      m = Regexp.last_match
      content_start = byte_to_char_offset(line_text, m.begin(1))
      content_end   = byte_to_char_offset(line_text, m.end(1))
      symbol_start  = byte_to_char_offset(line_text, m.begin(0))

      @text.tag_add('italic', "#{line_num}.#{content_start}", "#{line_num}.#{content_end}")
      @text.tag_add('md_symbol', "#{line_num}.#{symbol_start}", "#{line_num}.#{symbol_start + 1}")
      @text.tag_add('md_symbol', "#{line_num}.#{content_end}", "#{line_num}.#{content_end + 1}")
    end
  end

  def parse_current_line
    line_num = @text.index('insert').split('.')[0].to_i
    parse_line(line_num)
    parse_line(line_num - 1) if line_num > 1
  end

  def parse_entire_document
    total_lines = @text.index('end').split('.')[0].to_i - 1
    (1..total_lines).each do |line_num|
      parse_line(line_num)
    end
  end

  def get_headers
    headers = []
    total_lines = @text.index('end').split('.')[0].to_i - 1

    (1..total_lines).each do |line_num|
      line_text = @text.get("#{line_num}.0", "#{line_num}.end")
      if line_text.match(/^#{1,6}\s*(.*)/)
        hash_count = line_text.match(/^#+/)[0].length
        indent = "    " * (hash_count - 1)
        headers << { line: line_num, text: "#{indent}#{$1.strip}" }
      end
    end
    headers
  end
  
  def get_current_header_line
    current_line = @text.index('insert').split('.')[0].to_i
    current_header_line = nil
    
    get_headers.each do |h|
      if h[:line] <= current_line
        current_header_line = h[:line]
      else
        break
      end
    end
    current_header_line
  end
  
  def get_current_header_text
    line = get_current_header_line
    return nil unless line
    get_headers.find { |h| h[:line] == line }&.dig(:text)
  end
end

# ==========================================
# 2. FIND & REPLACE DIALOG
# ==========================================
class FindReplaceDialog
  def initialize(root, editor)
    @editor = editor
    @text = editor.text
    @root = root

    @dialog = TkToplevel.new(@root) { title "Find & Replace" }
    @dialog.transient(@root)
    @dialog.geometry("450x200")

    @match_case = TkVariable.new(false)
    @use_regex = TkVariable.new(false)

    build_ui

    @dialog.protocol('WM_DELETE_WINDOW', proc { @dialog.destroy })
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

    Tk::Tile::Label.new(@dialog) { text "Find:" }.grid(row: 0, column: 0, padx: 10, pady: 10, sticky: 'w')
    @find_entry = Tk::Tile::Entry.new(@dialog) { width 35 }
    @find_entry.grid(row: 0, column: 1, padx: 10, pady: 10, columnspan: 2, sticky: 'ew')

    Tk::Tile::Label.new(@dialog) { text "Replace:" }.grid(row: 1, column: 0, padx: 10, pady: 5, sticky: 'w')
    @replace_entry = Tk::Tile::Entry.new(@dialog) { width 35 }
    @replace_entry.grid(row: 1, column: 1, padx: 10, pady: 5, columnspan: 2, sticky: 'ew')

    Tk::Tile::CheckButton.new(@dialog) { text "Match Case"; variable @match_case }.grid(row: 2, column: 1, padx: 5, pady: 5, sticky: 'w')
    Tk::Tile::CheckButton.new(@dialog) { text "Regex"; variable @use_regex }.grid(row: 2, column: 2, padx: 5, pady: 5, sticky: 'w')

    btn_frame = Tk::Tile::Frame.new(@dialog)
    btn_frame.grid(row: 3, column: 0, columnspan: 3, pady: 15)

    Tk::Tile::Button.new(btn_frame) { text "Find Prev"; command proc { me.find(:backward) } }.pack(side: 'left', padx: 5)
    Tk::Tile::Button.new(btn_frame) { text "Find Next"; command proc { me.find(:forward) } }.pack(side: 'left', padx: 5)
    Tk::Tile::Button.new(btn_frame) { text "Replace"; command proc { me.replace_current } }.pack(side: 'left', padx: 5)
    Tk::Tile::Button.new(btn_frame) { text "Replace All"; command proc { me.replace_all } }.pack(side: 'left', padx: 5)

    @dialog.grid_columnconfigure(1, weight: 1)

    @find_entry.bind('Return', proc { me.find(:forward) })
    @dialog.bind('Escape', proc { @dialog.destroy })
  end

  def document_text
    @text.get('1.0', 'end - 1 char')
  end

  def cursor_byte_offset
    char_count = @text.count('1.0', 'insert', 'chars')
    char_count = char_count.first if char_count.is_a?(Array)
    document_text.slice(0, char_count.to_i).bytes.length
  end

  def byte_offset_to_index(byte_offset)
    text = document_text
    char_offset = text.byteslice(0, byte_offset).length
    @editor.text.index("1.0 + #{char_offset} chars")
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
    byte_offset = cursor_byte_offset
    m = nil

    if direction == :forward
      m = regex.match(text, byte_offset + 1)
      m ||= regex.match(text, 0)
    else
      last_before = nil
      text.scan(regex) do
        cur = Regexp.last_match
        last_before = cur if cur.begin(0) < byte_offset
      end
      m = last_before || regex.match(text, text.length - 1) || regex.match(text, 0)
    end

    if m
      match_start = byte_offset_to_index(m.begin(0))
      match_end   = byte_offset_to_index(m.end(0))
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

      @text.replace(match_start, match_end, @replace_entry.value)

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
    new_text = text.gsub(regex) { replace_text }

    # Save cursor position and scroll position
    cursor_index = @text.index('insert')
    first, last = @text.yview
    
    @text.replace('1.0', 'end - 1 char', new_text)
    
    # Restore cursor position (adjust if text length changed)
    new_text_length = new_text.length
    old_text_length = text.length
    if new_text_length != old_text_length
      # Try to keep cursor at same relative position
      char_offset = @text.count('1.0', cursor_index, 'chars').first.to_i
      if char_offset < new_text_length
        @text.mark_set('insert', "1.0 + #{char_offset} chars")
      else
        @text.mark_set('insert', 'end - 1 char')
      end
    else
      @text.mark_set('insert', cursor_index)
    end
    
    @text.yview_moveto(first)

    @editor.highlighter.parse_entire_document
    @editor.app.update_header_list

    Tk.messageBox(type: 'ok', icon: 'info', title: "Replace All", message: "Replaced #{replace_count} occurrences.")
  end
end

# ==========================================
# 3. EDITOR PANE
# ==========================================
class EditorPane
  attr_reader :text, :highlighter, :app

  def initialize(parent_frame, app)
    @app = app
    @debounce_timer = nil
    @text_frame = Tk::Tile::Frame.new(parent_frame)
    @text_frame.pack(fill: 'both', expand: true, padx: 15, pady: 15)

    scroll = Tk::Tile::Scrollbar.new(@text_frame)

    @text = TkText.new(@text_frame) {
      width 80
      height 24
      wrap 'word'
      font Theme::FONTS[:editor]
      borderwidth 0
      highlightthickness 1
      padx Theme::SPACING[:editor_x]
      pady Theme::SPACING[:editor_y]
      yscrollcommand proc { |first, last| scroll.set(first, last) }
    }

    scroll.pack(side: 'right', fill: 'y')
    @text.pack(side: 'left', fill: 'both', expand: true)
    text_widget = @text
    scroll.command proc { |*args| text_widget.yview(*args) }

    @highlighter = MarkdownHighlighter.new(@text)
    setup_shortcuts
  end

  def setup_shortcuts
    @text.bind('Control-s', proc { @app.save_file; 'break' })
    @text.bind('Control-o', proc { @app.open_file; 'break' })
    @text.bind('Control-n', proc { @app.new_file; 'break' })
    @text.bind('Control-q', proc { @app.quit_app; 'break' })

    @text.bind('Control-b', proc { insert_bold; 'break' })
    @text.bind('Control-i', proc { insert_italic; 'break' })

    @text.bind('Control-z', proc { @text.undo; 'break' })
    @text.bind('Control-y', proc { @text.redo; 'break' })

    @text.bind('Control-plus', proc { @app.zoom_in; 'break' })
    @text.bind('Control-equal', proc { @app.zoom_in; 'break' })
    @text.bind('Control-minus', proc { @app.zoom_out; 'break' })
    @text.bind('Control-0', proc { @app.reset_zoom; 'break' })
    @text.bind('Control-Up', proc { move_line_up; 'break' })
    @text.bind('Control-Down', proc { move_line_down; 'break' })

    @text.bind('Control-Shift-D', proc { duplicate_line; 'break' })

    @text.bind('Control-g', proc { @app.goto_line_dialog; 'break' })
    @text.bind('Control-f', proc { @app.open_find_dialog; 'break' })

    @text.bind('ButtonRelease-1') { @app.update_current_header }
    @text.bind('KeyRelease-Up') { @app.update_current_header }
    @text.bind('KeyRelease-Down') { @app.update_current_header }
    @text.bind('KeyRelease-Prior') { @app.update_current_header }
    @text.bind('KeyRelease-Next') { @app.update_current_header }

    @text.bind('Return', proc { handle_return })

    @text.bind('Right', proc {
      next_two = @text.get('insert', 'insert + 2 chars')
      next_one = next_two[0] || ''
      prev_char = @text.get('insert - 1 char', 'insert')

      if next_two == '**' || next_two == '``'
        @text.mark_set('insert', 'insert + 2 chars')
        'break'
      elsif ['*', '`'].include?(next_one)
        @text.mark_set('insert', 'insert + 1 char')
        'break'
      elsif next_one == ']' && prev_char == '['
        @text.mark_set('insert', 'insert + 1 char')
        'break'
      elsif next_one == ')' && prev_char == '('
        @text.mark_set('insert', 'insert + 1 char')
        'break'
      else
        nil
      end
    })

    @text.bind('Left', proc {
      prev_two = @text.get('insert - 2 chars', 'insert')
      prev_one = prev_two[-1] || ''
      next_char = @text.get('insert', 'insert + 1 char')

      if prev_two == '**' || prev_two == '``'
        @text.mark_set('insert', 'insert - 2 chars')
        'break'
      elsif ['*', '`'].include?(prev_one)
        @text.mark_set('insert', 'insert - 1 char')
        'break'
      elsif prev_one == '[' && next_char == ']'
        @text.mark_set('insert', 'insert - 1 char')
        'break'
      elsif prev_one == '(' && next_char == ')'
        @text.mark_set('insert', 'insert - 1 char')
        'break'
      else
        nil
      end
    })

    @text.bind('KeyPress', proc { |ev|
      char = ev.char
      closing_pairs = { '*' => '*', '`' => '`', '[' => ']', '(' => ')' }

      if closing_pairs.key?(char) && @text.tag_ranges('sel').empty?
        closing_char = closing_pairs[char]
        Tk.after(0, proc {
          @text.insert('insert', closing_char)
          @text.mark_set('insert', 'insert - 1 char')
        })
      end

      next if ev.keysym.nil? || ev.keysym =~ /Shift|Control|Alt|Left|Right|Up|Down|Home|End|Prior|Next/

      if !@app.is_modified
        @app.is_modified = true
        current_text = @app.notebook.itemcget(@app.tab_frame, 'text')
        unless current_text.start_with?('*')
          @app.notebook.itemconfigure(@app.tab_frame, text: "* #{current_text}")
        end
      end
    })

    @text.bind('KeyRelease') do
      Tk.after_cancel(@debounce_timer) if @debounce_timer
      @debounce_timer = Tk.after(300, method(:parse_and_update))

      text_content = @text.value
      words = text_content.split.size
      chars = text_content.length
      minutes = (words / 200.0).ceil
      time_str = minutes < 1 ? "< 1 min" : "#{minutes} min"

      @app.status_left.text = "Words: #{words} | Chars: #{chars} | Time: #{time_str}"
    end

    @text.bind('Control-v') do
      Tk.after(50, method(:parse_after_paste))
    end
  end

  def get_char_offset(index)
    n = @text.count('1.0', index, 'chars')
    n = n.first if n.is_a?(Array)
    n.to_i
  end

  def insert_bold
    if @text.tag_ranges('sel').any?
      start_idx = @text.index('sel.first')
      end_idx = @text.index('sel.last')

      start_offset = get_char_offset(start_idx)
      end_offset = get_char_offset(end_idx)

      @text.insert(start_idx, '**')
      @text.insert("1.0 + #{end_offset + 2} chars", '**')

      @text.tag_remove('sel', '1.0', 'end')
      @text.mark_set('insert', "1.0 + #{end_offset + 4} chars")
    else
      @text.insert('insert', '****')
      @text.mark_set('insert', 'insert - 2 chars')
    end
    'break'
  end

  def insert_italic
    if @text.tag_ranges('sel').any?
      start_idx = @text.index('sel.first')
      end_idx = @text.index('sel.last')

      start_offset = get_char_offset(start_idx)
      end_offset = get_char_offset(end_idx)

      @text.insert(start_idx, '*')
      @text.insert("1.0 + #{end_offset + 1} chars", '*')

      @text.tag_remove('sel', '1.0', 'end')
      @text.mark_set('insert', "1.0 + #{end_offset + 2} chars")
    else
      @text.insert('insert', '*')
      @text.mark_set('insert', 'insert - 1 char')
    end
    'break'
  end

  def handle_return
    current_line = @text.index('insert').split('.')[0].to_i
    line_text = @text.get("#{current_line}.0", "#{current_line}.end")

    if line_text.match(/^(\s*)([-*+])\s+/)
      indent = $1
      bullet = $2

      if line_text.strip == bullet
        @text.delete("#{current_line}.0", "#{current_line}.end")
        return
      end

      Tk.after(0, proc {
        @text.insert('insert', "#{indent}#{bullet} ")
      })
      return
    end

    if line_text.match(/^(\s*)(\d+)\.\s+/)
      indent = $1
      num = $2.to_i

      if line_text.strip == "#{num}."
        @text.delete("#{current_line}.0", "#{current_line}.end")
        return
      end

      Tk.after(0, proc {
        @text.insert('insert', "#{indent}#{num + 1}. ")
      })
      return
    end
  end

  def parse_after_paste
    @highlighter.parse_entire_document
    @app.update_header_list
    @app.status_left.text = "Words: #{@text.value.split.size}"
  end

  def parse_and_update
    @highlighter.parse_current_line
    @app.update_header_list
    @app.update_current_header
  end

  def move_line_up
    current_line = @text.index('insert').split('.')[0].to_i
    return if current_line <= 1

    # Save selection
    has_selection = @text.tag_ranges('sel').any?
    sel_start = has_selection ? @text.index('sel.first') : @text.index('insert')
    sel_end = has_selection ? @text.index('sel.last') : @text.index('insert')

    line_text = @text.get("#{current_line}.0", "#{current_line}.end")
    prev_text = @text.get("#{current_line - 1}.0", "#{current_line - 1}.end")

    @text.replace("#{current_line - 1}.0", "#{current_line}.end", "#{line_text}\n#{prev_text}")
    
    # Restore selection on the moved line
    if has_selection
      new_sel_start = sel_start.sub(current_line.to_s, (current_line - 1).to_s)
      new_sel_end = sel_end.sub(current_line.to_s, (current_line - 1).to_s)
      @text.tag_add('sel', new_sel_start, new_sel_end)
    end
    
    @text.mark_set('insert', "#{current_line - 1}.0")
    @text.see('insert')

    @highlighter.parse_line(current_line)
    @highlighter.parse_line(current_line - 1)
  end

  def move_line_down
    current_line = @text.index('insert').split('.')[0].to_i
    total_lines = @text.index('end').split('.')[0].to_i - 1
    return if current_line >= total_lines

    # Save selection
    has_selection = @text.tag_ranges('sel').any?
    sel_start = has_selection ? @text.index('sel.first') : @text.index('insert')
    sel_end = has_selection ? @text.index('sel.last') : @text.index('insert')

    line_text = @text.get("#{current_line}.0", "#{current_line}.end")
    next_text = @text.get("#{current_line + 1}.0", "#{current_line + 1}.end")

    @text.replace("#{current_line}.0", "#{current_line + 1}.end", "#{next_text}\n#{line_text}")
    
    # Restore selection on the moved line
    if has_selection
      new_sel_start = sel_start.sub(current_line.to_s, (current_line + 1).to_s)
      new_sel_end = sel_end.sub(current_line.to_s, (current_line + 1).to_s)
      @text.tag_add('sel', new_sel_start, new_sel_end)
    end
    
    @text.mark_set('insert', "#{current_line + 1}.0")
    @text.see('insert')

    @highlighter.parse_line(current_line)
    @highlighter.parse_line(current_line + 1)
  end

  def duplicate_line
    current_line = @text.index('insert').split('.')[0].to_i
    line_text = @text.get("#{current_line}.0", "#{current_line}.end")

    # Only add newline if line is not empty
    separator = line_text.strip.empty? ? "" : "\n"
    @text.insert("#{current_line}.end", "#{separator}#{line_text}")
    @text.mark_set('insert', "#{current_line + 1}.0")
    @text.see('insert')

    @highlighter.parse_line(current_line + 1)
  end
end

# ==========================================
# 4. MAIN APPLICATION
# ==========================================
class MarkdownEditor
  attr_accessor :is_modified, :notebook, :tab_frame, :status_left, :root, :current_theme

  def initialize
    @root = TkRoot.new { title "Markdown Note App v2 - OOP" }
    Tk::Tile::Style.theme_use('clam')

    disable_tk_emacs_bindings

    @root.minsize(800, 600)
    @root.geometry('900x700')
    @root.pack_propagate(false)

    @is_modified = false
    @current_filename = 'New File'
    @current_filepath = nil
    @base_font_size = 12
    @line_spacing = 4

    @root.protocol('WM_DELETE_WINDOW', method(:quit_app))

    @current_theme = :sepia
    @find_dialog = nil
    @goto_dialog = nil
    @header_popup = nil

    setup_ui
    apply_theme
    apply_font_settings
    
    @header_menu_var = TkVariable.new('')
    update_current_header
  end

  def disable_tk_emacs_bindings
    kill_proc = proc { 'break' }
    Tk.bind('Text', 'Control-b', kill_proc)
    Tk.bind('Text', 'Control-i', kill_proc)
    Tk.bind('Text', 'Control-d', kill_proc)
    Tk.bind('Text', 'Control-h', kill_proc)
    Tk.bind('Text', 'Control-k', kill_proc)
  end

  def setup_ui
    me = self

    @menubar = Tk::Tile::Frame.new(@root)
    @menubar.style = 'Toolbar.TFrame'
    @menubar.pack(fill: 'x')

    @file_menu = TkMenu.new(@root, tearoff: 0, font: Theme::FONTS[:ui])
    @file_menu.add('command', label: 'New', accel: 'Ctrl+N', command: method(:new_file))
    @file_menu.add('command', label: 'Open...', accel: 'Ctrl+O', command: method(:open_file))
    @file_menu.add('command', label: 'Save', accel: 'Ctrl+S', command: method(:save_file))
    @file_menu.add('separator')
    @file_menu.add('command', label: 'Quit', accel: 'Ctrl+Q', command: method(:quit_app))

    @file_btn = Tk::Tile::Button.new(@menubar)
    @file_btn.style = 'Menubar.TButton'
    @file_btn.text = "File"
    @file_btn.command = proc {
      x = @file_btn.winfo_rootx
      y = @file_btn.winfo_rooty + @file_btn.winfo_height
      @file_menu.popup(x, y)
    }
    @file_btn.pack(side: 'left', padx: Theme::SPACING[:sm], pady: 2)

    @edit_menu = TkMenu.new(@root, tearoff: 0, font: Theme::FONTS[:ui])
    @edit_menu.add('command', label: 'Find / Replace...', accel: 'Ctrl+F', command: method(:open_find_dialog))

    @edit_btn = Tk::Tile::Button.new(@menubar)
    @edit_btn.style = 'Menubar.TButton'
    @edit_btn.text = "Edit"
    @edit_btn.command = proc {
      x = @edit_btn.winfo_rootx
      y = @edit_btn.winfo_rooty + @edit_btn.winfo_height
      @edit_menu.popup(x, y)
    }
    @edit_btn.pack(side: 'left', padx: Theme::SPACING[:sm], pady: 2)

    @view_menu = TkMenu.new(@root, tearoff: 0, font: Theme::FONTS[:ui])
    @view_menu.add('command', label: 'Zoom In', accel: 'Ctrl++', command: method(:zoom_in))
    @view_menu.add('command', label: 'Zoom Out', accel: 'Ctrl+-', command: method(:zoom_out))
    @view_menu.add('command', label: 'Reset Zoom', accel: 'Ctrl+0', command: method(:reset_zoom))
    @view_menu.add('separator')
    @view_menu.add('command', label: 'Increase Spacing', command: proc { change_spacing(2) })
    @view_menu.add('command', label: 'Decrease Spacing', command: proc { change_spacing(-2) })
    @view_menu.add('separator')
    @view_menu.add('command', label: 'Go to Line...', accel: 'Ctrl+G', command: method(:goto_line_dialog))

    @view_btn = Tk::Tile::Button.new(@menubar)
    @view_btn.style = 'Menubar.TButton'
    @view_btn.text = "View"
    @view_btn.command = proc {
      x = @view_btn.winfo_rootx
      y = @view_btn.winfo_rooty + @view_btn.winfo_height
      @view_menu.popup(x, y)
    }
    @view_btn.pack(side: 'left', padx: Theme::SPACING[:sm], pady: 2)

    @theme_menu = TkMenu.new(@root, tearoff: 0, font: Theme::FONTS[:ui])
    @theme_menu.add('command', label: 'Sepia', command: proc { @current_theme = :sepia; apply_theme })
    @theme_menu.add('command', label: 'Dark', command: proc { @current_theme = :dark; apply_theme })

    @theme_btn = Tk::Tile::Button.new(@menubar)
    @theme_btn.style = 'Menubar.TButton'
    @theme_btn.text = "Theme"
    @theme_btn.command = proc {
      x = @theme_btn.winfo_rootx
      y = @theme_btn.winfo_rooty + @theme_btn.winfo_height
      @theme_menu.popup(x, y)
    }
    @theme_btn.pack(side: 'left', padx: Theme::SPACING[:sm], pady: 2)

    @toolbar = Tk::Tile::Frame.new(@root)
    @toolbar.style = 'Toolbar.TFrame'
    @toolbar.pack(fill: 'x')

    Tk::Tile::Button.new(@toolbar) { text "Bold"; style 'Toolbar.TButton'; command me.method(:insert_bold) }.pack(side: 'left', padx: Theme::SPACING[:sm])
    Tk::Tile::Button.new(@toolbar) { text "Italic"; style 'Toolbar.TButton'; command me.method(:insert_italic) }.pack(side: 'left', padx: Theme::SPACING[:sm])
    Tk::Tile::Button.new(@toolbar) { text "H1"; style 'Toolbar.TButton'; command me.method(:insert_h1) }.pack(side: 'left', padx: Theme::SPACING[:sm])
    Tk::Tile::Button.new(@toolbar) { text "H2"; style 'Toolbar.TButton'; command me.method(:insert_h2) }.pack(side: 'left', padx: Theme::SPACING[:sm])

    # Removed native TkMenu for headers, replaced with custom popup
    @header_btn = Tk::Tile::Button.new(@toolbar)
    @header_btn.style = 'Toolbar.TButton'
    @header_btn.text = "Headings"
    @header_btn.command = proc { me.show_header_popup }
    @header_btn.pack(side: 'right', padx: Theme::SPACING[:sm])

    Tk::Tile::Button.new(@toolbar) { text "Read-Only Toggle"; style 'Toolbar.TButton'; command me.method(:toggle_readonly) }.pack(side: 'right', padx: Theme::SPACING[:sm])

    @notebook = Tk::Tile::Notebook.new(@root)
    @notebook.pack(fill: 'both', expand: true)

    @tab_frame = Tk::Tile::Frame.new(@notebook) { style 'Tab.TFrame' }
    @notebook.add(@tab_frame, text: 'Untitled.md')

    @status_bar = Tk::Tile::Frame.new(@tab_frame) { style 'Status.TFrame' }
    @status_bar.pack(fill: 'x', side: 'bottom')

    @status_left = Tk::Tile::Label.new(@status_bar) { text "Words: 0"; style 'Status.TLabel' }
    @status_right = Tk::Tile::Label.new(@status_bar) { text "Edit Mode"; style 'Status.TLabel' }
    @status_center = Tk::Tile::Label.new(@status_bar) { text @current_filename; style 'Status.TLabel'; anchor 'center' }

    @status_left.pack(side: 'left', padx: 15, pady: 5)
    @status_right.pack(side: 'right', padx: 15, pady: 5)
    @status_center.pack(side: 'left', fill: 'x', expand: true, padx: 15, pady: 5)

    @editor = EditorPane.new(@tab_frame, self)
  end

  # NEW: Custom dropdown popup for headers with a scrollable listbox
  def show_header_popup
    headers = @editor.highlighter.get_headers
    c = Theme::THEMES[@current_theme]

    x = @header_btn.winfo_rootx
    y = @header_btn.winfo_rooty + @header_btn.winfo_height

    @header_popup = TkToplevel.new(@root) do
      overrideredirect true
      borderwidth 1
      relief 'solid'
      background c[:border]
    end
    @header_popup.geometry("+#{x}+#{y}")

    list_frame = TkFrame.new(@header_popup) { background c[:editor_bg] }.pack(fill: 'both', expand: true)
    
    scroll = Tk::Tile::Scrollbar.new(list_frame).pack(side: 'right', fill: 'y')
    
    # Limit to 15 visible rows max so it doesn't take up the whole screen
    visible_rows = [headers.size, 15].min
    visible_rows = 1 if visible_rows == 0

    list = TkListbox.new(list_frame) do
      font Theme::FONTS[:ui]
      height visible_rows
      width 35
      background c[:editor_bg]
      foreground c[:text_fg]
      selectbackground c[:selection]
      selectforeground c[:text_fg]
      borderwidth 0
      highlightthickness 0
      activestyle 'none'
      yscrollcommand proc { |first, last| scroll.set(first, last) }
    end
    list.pack(side: 'left', fill: 'both', expand: true)
    scroll.command proc { |*args| list.yview(*args) }

    if headers.empty?
      list.insert('end', 'No Headers Found')
      list.state = 'disabled'
    else
      current_header_line = @editor.highlighter.get_current_header_line
      headers.each_with_index do |h, idx|
        list.insert('end', h[:text])
        if h[:line] == current_header_line
          list.selection_set(idx)
          list.see(idx) # Auto-scroll to the active header
        end
      end
    end

    jump_proc = proc {
      sel_indices = list.curselection
      if sel_indices && !sel_indices.empty? && !headers.empty?
        sel_idx = sel_indices[0].to_i
        line_num = headers[sel_idx][:line]
        @editor.text.mark_set('insert', "#{line_num}.0")
        @editor.text.see("#{line_num}.0")
        @editor.text.focus
      end
      @header_popup.destroy if @header_popup
    }

    list.bind('<Return>', jump_proc)
    list.bind('<Double-Button-1>', jump_proc)
    list.bind('<Escape>', proc { @header_popup.destroy if @header_popup })
    
    @header_popup.bind('<Button-1>', proc { @header_popup.destroy if @header_popup })
    list_frame.bind('<Button-1>', proc { @header_popup.destroy if @header_popup })

    @header_popup.deiconify
    @header_popup.raise
    @header_popup.grab
    list.focus
  end

  def open_find_dialog
    if @find_dialog && @find_dialog.exist?
      @find_dialog.focus
    else
      @find_dialog = FindReplaceDialog.new(@root, @editor)
    end
  end

  def insert_bold; @editor.insert_bold; end
  def insert_italic; @editor.insert_italic; end

  def insert_h1; @editor.text.insert('insert', "# "); end
  def insert_h2; @editor.text.insert('insert', "## "); end

  def toggle_readonly
    if @editor.text.cget('state') == 'normal'
      @editor.text.state = 'disabled'
      @status_right.text = "Read-Only Mode"
    else
      @editor.text.state = 'normal'
      @status_right.text = "Edit Mode"
    end
  end

  def new_file
    @editor.text.state = 'normal'
    @editor.text.value = ""
    @editor.text.edit_reset
    @editor.text.tag_names.each do |tag|
      @editor.text.tag_remove(tag, '1.0', 'end')
    end
    @is_modified = false
    @current_filename = 'Untitled.md'
    @current_filepath = nil
    tab_text = @notebook.itemcget(@tab_frame, 'text').sub(/^\*\s*/, '')
    @notebook.itemconfigure(@tab_frame, text: @current_filename)
    @status_center.text = @current_filename
    @status_left.text = "Words: 0"
    update_header_list
  end

  def open_file
    filename = Tk.getOpenFile(filetypes: [["Markdown Files", ".md"], ["All Files", "*"]])
    return if filename.nil? || filename.empty?

    begin
      content = File.read(filename)
    rescue => e
      Tk.messageBox(type: 'ok', icon: 'error', title: "Error Opening File", message: e.message)
      return
    end

    @editor.text.state = 'normal'
    @editor.text.value = content
    @current_filepath = filename
    @current_filename = File.basename(filename)
    @is_modified = false
    @notebook.itemconfigure(@tab_frame, text: @current_filename)
    @status_center.text = @current_filename
    @status_left.text = "Words: #{@editor.text.value.split.size}"

    @editor.highlighter.parse_entire_document
    update_header_list
  end

  def save_file
    if @current_filepath.nil?
      filename = Tk.getSaveFile(filetypes: [["Markdown Files", ".md"], ["All Files", "*"]])
      return if filename.nil? || filename.empty?
      @current_filepath = filename
      @current_filename = File.basename(filename)
    else
      # Check if file exists and ask for confirmation
      if File.exist?(@current_filepath)
        answer = Tk.messageBox(type: 'yesno', icon: 'question', title: 'Overwrite File?', 
                              message: "File '#{@current_filename}' already exists. Overwrite?")
        return if answer != 'yes'
      end
    end

    begin
      File.write(@current_filepath, @editor.text.get('1.0', 'end - 1 char'))
    rescue => e
      Tk.messageBox(type: 'ok', icon: 'error', title: "Error Saving File", message: e.message)
      return
    end

    @is_modified = false
    @notebook.itemconfigure(@tab_frame, text: @current_filename)
    @status_center.text = @current_filename
    @status_left.text = "Words: #{@editor.text.value.split.size}"
  end

  def apply_theme
    c = Theme::THEMES[@current_theme]
    ui_font = Theme::FONTS[:ui]

    @root.background(c[:window_bg])

    @editor.text.background(c[:editor_bg])
    @editor.text.foreground(c[:text_fg])
    @editor.text.configure(insertbackground: c[:text_fg], selectbackground: c[:selection], highlightbackground: c[:border], highlightcolor: c[:border])

    Tk::Tile::Style.configure('TFrame', background: c[:window_bg])
    Tk::Tile::Style.configure('Toolbar.TFrame', background: c[:toolbar_bg])
    Tk::Tile::Style.configure('Status.TFrame', background: c[:status_bg])
    Tk::Tile::Style.configure('Tab.TFrame', background: c[:window_bg])

    Tk::Tile::Style.configure('TButton', font: ui_font, background: c[:button_bg], foreground: c[:text_fg], borderwidth: 1, relief: 'solid', focusthickness: 0, padding: "#{Theme::SPACING[:md]} #{Theme::SPACING[:sm]}")
    Tk::Tile::Style.map('TButton',
      background: [:active, c[:button_hover], :pressed, c[:button_pressed]],
      bordercolor: [:active, c[:border], :focus, c[:accent]],
      foreground: [:active, c[:text_fg]]
    )

    Tk::Tile::Style.configure('Toolbar.TButton', font: ui_font, background: c[:button_bg], foreground: c[:text_fg], borderwidth: 1, relief: 'solid', focusthickness: 0, padding: "#{Theme::SPACING[:md]} #{Theme::SPACING[:sm]}")
    Tk::Tile::Style.map('Toolbar.TButton',
      background: [:active, c[:button_hover], :pressed, c[:button_pressed]],
      bordercolor: [:active, c[:border], :focus, c[:accent]],
      foreground: [:active, c[:text_fg]]
    )

    Tk::Tile::Style.configure('Menubar.TButton', font: ui_font, background: c[:toolbar_bg], foreground: c[:text_fg], borderwidth: 1, relief: 'solid', focusthickness: 0, padding: "#{Theme::SPACING[:md]} #{Theme::SPACING[:xs]}")
    Tk::Tile::Style.map('Menubar.TButton',
      background: [:active, c[:menu_hover], :pressed, c[:button_pressed]],
      bordercolor: [:active, c[:border], :focus, c[:border]],
      foreground: [:active, c[:text_fg]]
    )

    Tk::Tile::Style.configure('TLabel', font: ui_font, background: c[:window_bg], foreground: c[:text_fg])
    Tk::Tile::Style.configure('Status.TLabel', font: ui_font, background: c[:status_bg], foreground: c[:muted_fg])
    Tk::Tile::Style.configure('Toolbar.TLabel', font: ui_font, background: c[:toolbar_bg], foreground: c[:text_fg])

    Tk::Tile::Style.configure('TNotebook', background: c[:window_bg], borderwidth: 0)
    Tk::Tile::Style.configure('TNotebook.Tab', font: ui_font, padding: "#{Theme::SPACING[:lg]} #{Theme::SPACING[:sm]}", background: c[:toolbar_bg], foreground: c[:muted_fg], borderwidth: 0)
    Tk::Tile::Style.map('TNotebook.Tab',
      background: [:selected, c[:editor_bg]],
      foreground: [:selected, c[:text_fg]]
    )

    Tk::Tile::Style.configure('Vertical.TScrollbar', background: c[:button_bg], troughcolor: c[:editor_bg], borderwidth: 0, arrowsize: 15, arrowcolor: c[:muted_fg])
    Tk::Tile::Style.map('Vertical.TScrollbar', background: [:active, c[:button_hover]])

    [@file_menu, @edit_menu, @view_menu, @theme_menu].each do |menu|
      menu.configure(
        background: c[:toolbar_bg],
        foreground: c[:text_fg],
        activebackground: c[:menu_hover],
        activeforeground: c[:text_fg],
        borderwidth: 1,
        relief: 'solid',
        activeborderwidth: 0
      )
    end

    @editor.highlighter.apply_theme(c)
  end

  def apply_font_settings
    f = Theme::FONTS[:editor]
    @editor.text.configure(font: [f[0], @base_font_size], spacing1: @line_spacing, spacing2: @line_spacing, spacing3: @line_spacing)
    @editor.highlighter.apply_font_settings(@base_font_size)
    @editor.highlighter.parse_entire_document
  end

  def update_header_list
    update_current_header
  end

  def update_current_header
    header_text = @editor.highlighter.get_current_header_text
    current_line = @editor.highlighter.get_current_header_line
    
    if header_text
      display_text = header_text.length > 30 ? header_text[0..27] + "..." : header_text
      @header_btn.text = display_text
      @header_menu_var.value = current_line.to_s if current_line
    else
      @header_btn.text = "Headings"
      @header_menu_var.value = ""
    end
  end

  def zoom_in
    @base_font_size = [24, @base_font_size + 1].min
    apply_font_settings
  end

  def zoom_out
    @base_font_size = [8, @base_font_size - 1].max
    apply_font_settings
  end

  def reset_zoom
    @base_font_size = 12
    apply_font_settings
  end

  def goto_line_dialog
    if @goto_dialog && @goto_dialog.exist?
      @goto_dialog.focus
      return
    end

    @goto_dialog = TkToplevel.new(@root) { title "Go to Line" }
    @goto_dialog.transient(@root)
    @goto_dialog.geometry("300x100")

    Tk::Tile::Label.new(@goto_dialog) { text "Enter line number:" }.pack(pady: 10)
    entry = Tk::Tile::Entry.new(@goto_dialog) { width 20 }
    entry.pack(pady: 5)
    entry.focus

    jump_command = lambda {
      line_num = entry.value.to_i
      if line_num > 0
        @editor.text.mark_set('insert', "#{line_num}.0")
        @editor.text.see("#{line_num}.0")
        @editor.text.focus
      end
      @goto_dialog.destroy
    }

    entry.bind('Return', jump_command)
    Tk::Tile::Button.new(@goto_dialog) { text "Go"; command jump_command }.pack(pady: 5)
  end

  def change_spacing(amount)
    @line_spacing = [0, @line_spacing + amount].max
    apply_font_settings
  end

  def quit_app
    if @is_modified
      answer = Tk.messageBox(type: 'yesnocancel', icon: 'question', title: 'Unsaved Changes', message: 'You have unsaved changes. Do you want to save before quitting?')
      if answer == 'yes'
        save_file
        @root.destroy
      elsif answer == 'no'
        @root.destroy
      end
    else
      @root.destroy
    end
  end

  def run
    Tk.mainloop
  end
end

app = MarkdownEditor.new
app.run
