# frozen_string_literal: true

class EditorPane
  attr_reader :text, :highlighter, :app, :debounce_timer

  PAIR_OPEN_TO_CLOSE = { '*' => '*', '`' => '`', '[' => ']', '(' => ')' }.freeze
  SYMMETRIC_PAIR_CHARS = ['*', '`'].freeze
  PAIR_CLOSER_CHARS = [']', ')'].freeze

  def initialize(parent_frame, app)
    @app = app
    @debounce_timer = nil
    @auto_close_marks = []
    @auto_close_seq = 0
    @callback_refs = []
    
    @text_frame = Tk::Tile::Frame.new(parent_frame)
    @text_frame.pack(fill: 'both', expand: true)

    @scroll = Tk::Tile::Scrollbar.new(@text_frame)

    yscroll_proc = proc { |first, last| @scroll.set(first, last) }
    @callback_refs << yscroll_proc

    @text = TkText.new(@text_frame) {
      width 80
      height 24
      wrap 'word'
      font Theme::FONTS[:editor]
      borderwidth 0
      highlightthickness 1
      padx Theme::SPACING[:editor_x]
      pady Theme::SPACING[:editor_y]
      undo true
      autoseparators false
      yscrollcommand yscroll_proc
    }

    @scroll.pack(side: 'right', fill: 'y')
    @text.pack(side: 'left', fill: 'both', expand: true)
    
    yview_proc = proc { |*args| @text.yview(*args) }
    @callback_refs << yview_proc
    @scroll.command yview_proc

    @highlighter = MarkdownHighlighter.new(@text)
    setup_shortcuts
  end

  def cancel_timers
    Tk.after_cancel(@debounce_timer) if @debounce_timer
  end

  def setup_shortcuts
    ctrl_s = proc { @app.save_file; 'break' }
    @callback_refs << ctrl_s
    @text.bind('Control-s', ctrl_s)

    ctrl_shift_s = proc { @app.save_as_file; 'break' }
    @callback_refs << ctrl_shift_s
    @text.bind('Control-Shift-S', ctrl_shift_s)

    ctrl_o = proc { @app.open_file; 'break' }
    @callback_refs << ctrl_o
    @text.bind('Control-o', ctrl_o)

    ctrl_n = proc { @app.new_file; 'break' }
    @callback_refs << ctrl_n
    @text.bind('Control-n', ctrl_n)

    ctrl_q = proc { @app.quit_app; 'break' }
    @callback_refs << ctrl_q
    @text.bind('Control-q', ctrl_q)

    ctrl_b = proc { insert_bold; 'break' }
    @callback_refs << ctrl_b
    @text.bind('Control-b', ctrl_b)

    ctrl_i = proc { insert_italic; 'break' }
    @callback_refs << ctrl_i
    @text.bind('Control-i', ctrl_i)

    ctrl_z = proc { @text.edit_undo rescue nil; 'break' }
    @callback_refs << ctrl_z
    @text.bind('Control-z', ctrl_z)

    ctrl_y = proc { @text.edit_redo rescue nil; 'break' }
    @callback_refs << ctrl_y
    @text.bind('Control-y', ctrl_y)

    ctrl_shift_z = proc { @text.edit_redo rescue nil; 'break' }
    @callback_refs << ctrl_shift_z
    @text.bind('Control-Z', ctrl_shift_z)

    ctrl_a = proc { 
      @text.tag_add('sel', '1.0', 'end - 1 char')
      'break' 
    }
    @callback_refs << ctrl_a
    @text.bind('Control-a', ctrl_a)

    ctrl_plus = proc { @app.zoom_in; 'break' }
    @callback_refs << ctrl_plus
    @text.bind('Control-plus', ctrl_plus)

    ctrl_equal = proc { @app.zoom_in; 'break' }
    @callback_refs << ctrl_equal
    @text.bind('Control-equal', ctrl_equal)

    ctrl_minus = proc { @app.zoom_out; 'break' }
    @callback_refs << ctrl_minus
    @text.bind('Control-minus', ctrl_minus)

    ctrl_0 = proc { @app.reset_zoom; 'break' }
    @callback_refs << ctrl_0
    @text.bind('Control-0', ctrl_0)

    ctrl_up = proc { move_line_up; 'break' }
    @callback_refs << ctrl_up
    ['Control-Up', 'Control-Key-Up'].each { |seq| @text.bind(seq, ctrl_up) }

    ctrl_down = proc { move_line_down; 'break' }
    @callback_refs << ctrl_down
    ['Control-Down', 'Control-Key-Down'].each { |seq| @text.bind(seq, ctrl_down) }

    duplicate_proc = proc { duplicate_line; 'break' }
    @callback_refs << duplicate_proc
    ['Control-Shift-D', 'Control-Shift-d', 'Control-Shift-Key-D', 'Control-Shift-Key-d'].each do |seq|
      @text.bind(seq, duplicate_proc)
    end

    # X11 often reports Ctrl+Shift+D as keysym "d" plus the Shift bit, which
    # also matches the Text class Control-d "delete character" binding.
    ctrl_d = proc { |ev|
      state = ev.respond_to?(:state) ? ev.state.to_i : 0
      if (state & 1) != 0
        duplicate_line
        'break'
      end
    }
    @callback_refs << ctrl_d
    @text.bind('Control-d', ctrl_d)
    @text.bind('Control-Key-d', ctrl_d)

    ctrl_g = proc { @app.goto_line_dialog; 'break' }
    @callback_refs << ctrl_g
    @text.bind('Control-g', ctrl_g)

    ctrl_f = proc { @app.open_find_dialog; 'break' }
    @callback_refs << ctrl_f
    @text.bind('Control-f', ctrl_f)

    btn_release_1 = proc { 
      @text.edit_separator
      @app.update_current_header 
    }
    @callback_refs << btn_release_1
    @text.bind('ButtonRelease-1', btn_release_1)

    key_release_up = proc { @app.update_current_header }
    @callback_refs << key_release_up
    @text.bind('KeyRelease-Up', key_release_up)

    key_release_down = proc { @app.update_current_header }
    @callback_refs << key_release_down
    @text.bind('KeyRelease-Down', key_release_down)

    key_release_prior = proc { @app.update_current_header }
    @callback_refs << key_release_prior
    @text.bind('KeyRelease-Prior', key_release_prior)

    key_release_next = proc { @app.update_current_header }
    @callback_refs << key_release_next
    @text.bind('KeyRelease-Next', key_release_next)

    return_key = proc { handle_return }
    @callback_refs << return_key
    @text.bind('Return', return_key)

    right_key = proc {
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
    }
    @callback_refs << right_key
    @text.bind('Right', right_key)

    left_key = proc {
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
    }
    @callback_refs << left_key
    @text.bind('Left', left_key)

    key_press = proc { |ev|
      unless ev.keysym.nil? || ev.keysym =~ /Shift|Control|Alt|Left|Right|Up|Down|Home|End|Prior|Next/
        @text.edit_separator
      end

      char = ev.char

      if @text.tag_ranges('sel').empty?
        if PAIR_OPEN_TO_CLOSE.key?(char)
          closer = PAIR_OPEN_TO_CLOSE[char]
          if SYMMETRIC_PAIR_CHARS.include?(char)
            # Always scaffold *, ` so **, ***, and ``` can be typed through pairing
            after_proc = proc {
              @text.insert('insert', closer)
              @text.mark_set('insert', 'insert - 1 char')
            }
            Tk.after(0, &after_proc)
          else
            next_char = @text.get('insert', 'insert + 1 char')
            if next_char == closer && consume_auto_close_mark
              @text.mark_set('insert', 'insert + 1 char')
              next 'break'
            else
              after_proc = proc {
                @text.insert('insert', closer)
                @text.mark_set('insert', 'insert - 1 char')
                register_auto_close_mark
              }
              Tk.after(0, &after_proc)
            end
          end
        elsif PAIR_CLOSER_CHARS.include?(char)
          next_char = @text.get('insert', 'insert + 1 char')
          if next_char == char && consume_auto_close_mark
            @text.mark_set('insert', 'insert + 1 char')
            next 'break'
          end
        end
      end

      next if ev.keysym.nil? || ev.keysym =~ /Shift|Control|Alt|Left|Right|Up|Down|Home|End|Prior|Next/

      @app.last_keypress_time = Time.now
      @app.mark_modified
    }
    @callback_refs << key_press
    @text.bind('KeyPress', key_press)

    key_release = proc { |ev|
      Tk.after_cancel(@debounce_timer) if @debounce_timer
      debounce_proc = proc { parse_and_update }
      @debounce_timer = Tk.after(300, &debounce_proc)
    }
    @callback_refs << key_release
    @text.bind('KeyRelease', key_release)

    ctrl_v = proc {
      paste_proc = proc { parse_after_paste }
      Tk.after(100, &paste_proc)
    }
    @callback_refs << ctrl_v
    @text.bind('Control-v', ctrl_v)
  end

  def register_auto_close_mark
    name = "autoclose_#{@auto_close_seq += 1}"
    @text.mark_set(name, 'insert')
    @text.mark_gravity(name, 'left')
    @auto_close_marks << name
    
    while @auto_close_marks.size > 10
      old = @auto_close_marks.shift
      @text.mark_unset(old) if @text.mark_names.include?(old)
    end
  end

  def consume_auto_close_mark
    return false if @auto_close_marks.empty?
    cursor = @text.index('insert')
    match = @auto_close_marks.find { |m| @text.mark_names.include?(m) && @text.index(m) == cursor }
    return false unless match
    @auto_close_marks.delete(match)
    @text.mark_unset(match)
    true
  end

  def reset_auto_close_tracking
    @auto_close_marks.each { |m| @text.mark_unset(m) if @text.mark_names.include?(m) }
    @auto_close_marks.clear
  end

  def insert_bold
    @text.edit_separator
    if @text.tag_ranges('sel').any?
      @text.mark_set('temp_sel_end', 'sel.last')
      @text.insert('sel.last', '**')
      @text.insert('sel.first', '**')
      @text.tag_remove('sel', '1.0', 'end')
      @text.mark_set('insert', 'temp_sel_end + 2 chars')
      @text.mark_unset('temp_sel_end')
    else
      @text.insert('insert', '****')
      @text.mark_set('insert', 'insert - 2 chars')
    end
    @app.mark_modified
    @text.edit_separator
    'break'
  end

  def insert_italic
    @text.edit_separator
    if @text.tag_ranges('sel').any?
      @text.mark_set('temp_sel_end', 'sel.last')
      @text.insert('sel.last', '*')
      @text.insert('sel.first', '*')
      @text.tag_remove('sel', '1.0', 'end')
      @text.mark_set('insert', 'temp_sel_end + 1 char')
      @text.mark_unset('temp_sel_end')
    else
      @text.insert('insert', '**')
      @text.mark_set('insert', 'insert - 1 char')
    end
    @app.mark_modified
    @text.edit_separator
    'break'
  end

  def handle_return
    current_line = @text.index('insert').split('.')[0].to_i
    line_text = @text.get("#{current_line}.0", "#{current_line}.end")
    cursor_col = @text.index('insert').split('.')[1].to_i

    # "--- HR shortcut: ***|*** + Enter → *** (separator) ---"
    before = line_text[0, cursor_col]
    after  = line_text[cursor_col..-1] || ''
    if before.match(/\A\*{3,}\z/) && after.match(/\A\*+\z/)
      @text.edit_separator
      @text.delete('insert', "#{current_line}.end")   # drop the mirrored ***
      @app.mark_modified                              # Return preempts the general KeyPress handler
      @app.last_keypress_time = Time.now
      hr_render = proc {
        @highlighter.parse_line(current_line, true)   # by now the newline exists → render the bar
      }
      Tk.after(0, &hr_render)
      return   # nil → Tk's class binding still inserts the newline
    end
    if line_text.match(/^(\s*)([-*+])\s+/)
      indent = $1
      bullet = $2

      if line_text.strip == bullet
        @text.edit_separator
        @text.delete("#{current_line}.0", "#{current_line}.end")
        @text.edit_separator
        return 'break'
      end

      return_proc = proc {
        @text.insert('insert', "#{indent}#{bullet} ")
        @text.edit_separator
      }
      Tk.after(0, &return_proc)
      return
    end

    if line_text.match(/^(\s*)(\d+)\.\s+/)
      indent = $1
      num = $2.to_i

      if line_text.strip == "#{num}."
        @text.edit_separator
        @text.delete("#{current_line}.0", "#{current_line}.end")
        @text.edit_separator
        return 'break'
      end

      return_proc = proc {
        @text.insert('insert', "#{indent}#{num + 1}. ")
        @text.edit_separator
      }
      Tk.after(0, &return_proc)
      return
    end
  end

  def parse_after_paste
    @highlighter.parse_entire_document
    @app.update_header_list
    @app.update_status_left
  end

  def parse_and_update
    @highlighter.parse_current_line
    @highlighter.rebuild_headers_cache
    @app.update_current_header
    @app.update_status_left
  end

  def move_line_up
    current_line, current_col = @text.index('insert').split('.').map(&:to_i)
    return if current_line <= 1

    has_selection = @text.tag_ranges('sel').any?
    if has_selection
      sel_start = @text.index('sel.first')
      sel_end = @text.index('sel.last')
      start_line = sel_start.split('.')[0].to_i
      end_line = sel_end.split('.')[0].to_i
      end_line -= 1 if sel_end.split('.')[1].to_i == 0 && end_line > start_line
    else
      start_line = end_line = current_line
    end

    block_text = @text.get("#{start_line}.0", "#{end_line}.end")
    prev_text = @text.get("#{start_line - 1}.0", "#{start_line - 1}.end")

    @text.edit_separator
    @text.replace("#{start_line - 1}.0", "#{end_line}.end", "#{block_text}\n#{prev_text}")

    if has_selection
      @text.tag_add('sel', "#{start_line - 1}.0", "#{start_line - 1}.0 + #{block_text.length} chars")
    end

    @text.mark_set('insert', "#{current_line - 1}.#{current_col}")
    @text.see('insert')
    @text.edit_separator
    @app.mark_modified

    (start_line - 1).upto(end_line).each { |l| @highlighter.parse_line(l) }
  end

  def move_line_down
    current_line, current_col = @text.index('insert').split('.').map(&:to_i)
    total_lines = @text.index('end').split('.')[0].to_i - 1
    return if current_line >= total_lines

    has_selection = @text.tag_ranges('sel').any?
    if has_selection
      sel_start = @text.index('sel.first')
      sel_end = @text.index('sel.last')
      start_line = sel_start.split('.')[0].to_i
      end_line = sel_end.split('.')[0].to_i
      end_line -= 1 if sel_end.split('.')[1].to_i == 0 && end_line > start_line
    else
      start_line = end_line = current_line
    end

    return if end_line >= total_lines

    block_text = @text.get("#{start_line}.0", "#{end_line}.end")
    next_text = @text.get("#{end_line + 1}.0", "#{end_line + 1}.end")

    @text.edit_separator
    @text.replace("#{start_line}.0", "#{end_line + 1}.end", "#{next_text}\n#{block_text}")

    if has_selection
      @text.tag_add('sel', "#{start_line + 1}.0", "#{start_line + 1}.0 + #{block_text.length} chars")
    end

    @text.mark_set('insert', "#{current_line + 1}.#{current_col}")
    @text.see('insert')
    @text.edit_separator
    @app.mark_modified

    start_line.upto(end_line + 1).each { |l| @highlighter.parse_line(l) }
  end

  def duplicate_line
    current_line = @text.index('insert').split('.')[0].to_i
    line_text = @text.get("#{current_line}.0", "#{current_line}.end")

    @text.edit_separator
    @text.insert("#{current_line}.end", "\n#{line_text}")
    @text.mark_set('insert', "#{current_line + 1}.0")
    @text.see('insert')
    @text.edit_separator
    @app.mark_modified

    @highlighter.parse_line(current_line + 1)
  end
end
