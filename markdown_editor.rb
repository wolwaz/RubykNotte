# frozen_string_literal: true

class MarkdownEditor
  attr_accessor :is_modified, :tab_frame, :status_left, :root, :current_theme, :last_keypress_time

  def initialize
    @root = TkRoot.new { title "Untitled.md — RubykNotte" }
    Tk::Tile::Style.theme_use('clam')
    @callback_refs = []

    disable_tk_emacs_bindings

    @root.minsize(800, 600)
    @root.geometry('900x700')
    @root.pack_propagate(false)

    @is_modified = false
    @current_filename = 'Untitled.md'
    @current_filepath = nil

    @settings = UserSettings.new
    @base_font_size = @settings[:font_size]
    @line_spacing = @settings[:line_spacing]
    @text_padding_x = @settings[:text_padding_x]
    @text_padding_y = @settings[:text_padding_y]
    @current_theme = @settings[:theme]
    @last_keypress_time = Time.now
    @backup_due_time = nil

    @backup_dir = File.join(Dir.home, '.markdown_editor_backups')
    @backup_file = File.join(@backup_dir, 'recovery.md')
    @recovery_meta = File.join(@backup_dir, 'recovery.json')
    @recovery_lock = File.join(@backup_dir, 'recovery.pid')
    @recovery_writer = false
    Dir.mkdir(@backup_dir) unless Dir.exist?(@backup_dir)

    claim_recovery_lock

    quit_app_proc = proc { quit_app }
    @callback_refs << quit_app_proc
    @root.protocol('WM_DELETE_WINDOW', quit_app_proc)

    @find_dialog = nil
    @goto_dialog = nil
    @header_popup = nil
    @header_popup_scroll = nil
    
    @popup_close_proc = proc { |ev|
      return unless @header_popup && @header_popup.exist?
      rx = @header_popup.winfo_rootx
      ry = @header_popup.winfo_rooty
      rw = @header_popup.winfo_width
      rh = @header_popup.winfo_height
      x = ev.x_root
      y = ev.y_root
      
      if x < rx || x > rx + rw || y < ry || y > ry + rh
        close_header_popup
      end
    }
    @callback_refs << @popup_close_proc
    @root.bind('ButtonPress-1', @popup_close_proc)

    setup_ui
    apply_theme
    apply_font_settings
    update_window_title

    update_current_header

    offer_startup_recovery
    schedule_next_backup_check(10000)
  end

  def schedule_next_backup_check(ms)
    Tk.after_cancel(@backup_check_timer) if @backup_check_timer
    @backup_check_proc = proc { check_backup }
    @backup_check_timer = Tk.after(ms, &@backup_check_proc)
  end

  def check_backup
    unless @recovery_writer
      schedule_next_backup_check(10000)
      return
    end

    if @is_modified
      time_since_type = Time.now - (@last_keypress_time || Time.now)
      
      if time_since_type > 2
        perform_background_backup
        @backup_due_time = nil
        schedule_next_backup_check(10000)
      else
        @backup_due_time ||= Time.now
        if Time.now - @backup_due_time >= 5
          perform_background_backup
          @backup_due_time = nil
          schedule_next_backup_check(10000)
        else
          schedule_next_backup_check(1000)
        end
      end
    else
      @backup_due_time = nil
      schedule_next_backup_check(10000)
    end
  end

  def perform_background_backup
    return unless @is_modified
    begin
      content = @editor.text.get('1.0', 'end - 1 char')
      write_backup_atomic(content)
    rescue => e
      puts "Background backup failed: #{e.message}"
    end
  end

  def write_backup_atomic(content)
    return unless @recovery_writer

    Dir.mkdir(@backup_dir) unless Dir.exist?(@backup_dir)
    tmp_file = "#{@backup_file}.tmp"
    File.write(tmp_file, content, encoding: 'UTF-8')
    FileUtils.mv(tmp_file, @backup_file, force: true)
    write_recovery_meta
  end

  def write_recovery_meta
    payload = {
      'path' => @current_filepath,
      'filename' => @current_filename,
      'saved_at' => Time.now.strftime('%Y-%m-%dT%H:%M:%S')
    }
    tmp_file = "#{@recovery_meta}.tmp"
    File.write(tmp_file, JSON.generate(payload), encoding: 'UTF-8')
    FileUtils.mv(tmp_file, @recovery_meta, force: true)
  end

  def claim_recovery_lock
    @recovery_writer = false
    if File.exist?(@recovery_lock)
      pid = Integer(File.read(@recovery_lock).strip) rescue 0
      return if pid > 0 && pid != Process.pid && process_alive?(pid)
    end

    File.write(@recovery_lock, "#{Process.pid}\n")
    @recovery_writer = true
  end

  def process_alive?(pid)
    Process.kill(0, pid)
    true
  rescue Errno::ESRCH
    false
  rescue Errno::EPERM
    true
  end

  def release_recovery_lock
    return unless @recovery_writer && @recovery_lock && File.exist?(@recovery_lock)

    current = File.read(@recovery_lock).strip
    File.delete(@recovery_lock) if current == Process.pid.to_s
  rescue SystemCallError
    nil
  end

  def recovery_has_text?(path)
    File.file?(path) && File.size(path) > 0
  rescue SystemCallError
    false
  end

  def recovery_meta_for(text_path)
    return @recovery_meta if text_path == @backup_file
    return "#{@recovery_meta}.bak" if text_path == "#{@backup_file}.bak"

    "#{text_path}.json"
  end

  def read_recovery_meta(text_path)
    meta_path = recovery_meta_for(text_path)
    return {} unless meta_path && File.file?(meta_path)

    raw = JSON.parse(File.read(meta_path, encoding: 'UTF-8'))
    raw.is_a?(Hash) ? raw : {}
  rescue JSON::ParserError, SystemCallError, EncodingError
    {}
  end

  def first_recovery_line(path)
    line = ''
    File.open(path, 'r:UTF-8') do |file|
      file.each_line do |raw|
        text = raw.strip
        next if text.empty?

        line = text
        break
      end
    end
    return '(empty)' if line.empty?

    line.length > 80 ? "#{line[0, 77]}..." : line
  rescue EncodingError, SystemCallError
    '(unreadable)'
  end

  def format_bytes(size)
    return "#{size} B" if size < 1024

    format('%.1f KB', size / 1024.0)
  end

  def recovery_summary(path, label)
    stat = File.stat(path)
    meta = read_recovery_meta(path)
    name = meta['filename'].to_s
    name = 'Untitled' if name.empty?
    "#{label}: #{name} — #{stat.mtime.strftime('%Y-%m-%d %H:%M')} — #{format_bytes(stat.size)}\n#{first_recovery_line(path)}"
  end

  def recovery_choices
    choices = []
    if recovery_has_text?(@backup_file)
      choices << {
        path: @backup_file,
        label: 'Open latest',
        summary: recovery_summary(@backup_file, 'Latest')
      }
    end
    previous = "#{@backup_file}.bak"
    if recovery_has_text?(previous)
      choices << {
        path: previous,
        label: 'Open previous',
        summary: recovery_summary(previous, 'Previous')
      }
    end
    choices
  end

  def offer_startup_recovery
    unless @recovery_writer
      Tk.messageBox(
        type: 'ok', icon: 'info', title: 'Recovery',
        message: 'Another RubykNotte window is already running. This window will not write a crash recovery.'
      )
      return
    end
    return unless recovery_has_text?(@backup_file)

    answer = Tk.messageBox(
      type: 'yesno', icon: 'question', title: 'Restore recovery?',
      message: "#{recovery_summary(@backup_file, 'Latest')}\n\nRestore this unsaved text?\nYes opens it. No starts blank and keeps this copy as the previous recovery."
    )
    apply_startup_recovery_choice(answer)
  end

  def apply_startup_recovery_choice(answer)
    if answer == 'yes'
      load_recovery_file(@backup_file)
    else
      rotate_backups
    end
  end

  def clear_current_recovery
    return unless @recovery_writer
    return unless File.exist?(@backup_file) || (@recovery_meta && File.exist?(@recovery_meta))

    meta = read_recovery_meta(@backup_file)
    source = meta['path']
    source = nil unless source.is_a?(String) && !source.strip.empty?
    return if source && source != @current_filepath

    File.delete(@backup_file) if File.exist?(@backup_file)
    File.delete(@recovery_meta) if @recovery_meta && File.exist?(@recovery_meta)
  rescue SystemCallError
    nil
  end

  def disable_tk_emacs_bindings
    @emacs_kill_proc = proc { 'break' }
    @callback_refs << @emacs_kill_proc
    # Ctrl-H stays: it is Tk's backspace (delete the character on the left).
    # Ctrl-D is stopped here because Ctrl+Shift+D often arrives as Control-d
    # and was deleting a character instead of duplicating the line.
    # Ctrl-Up/Down are stopped so paragraph motion cannot run instead of move-line.
    [
      'Control-b', 'Control-i', 'Control-k', 'Control-f', 'Control-g',
      'Control-s', 'Control-o', 'Control-n', 'Control-q', 'Control-d',
      'Control-Up', 'Control-Down', 'Control-Key-Up', 'Control-Key-Down'
    ].each do |key|
      Tk.bind('Text', key, @emacs_kill_proc)
    end
  end

  def mark_modified
    if !@is_modified
      @is_modified = true
      update_window_title
    end
  end

  def update_window_title
    star = @is_modified ? '* ' : ''
    @root.title = "#{star}#{@current_filename} — RubykNotte"
  end

  def setup_ui
    me = self

    @menubar = Tk::Tile::Frame.new(@root)
    @menubar.style = 'Menubar.TFrame'
    @menubar.pack(fill: 'x')

    @file_menu = TkMenu.new(@root, tearoff: 0, font: Theme::FONTS[:ui])

    new_file_proc = proc { new_file }
    @callback_refs << new_file_proc
    @file_menu.add('command', label: 'New', accel: 'Ctrl+N', command: new_file_proc)

    open_file_proc = proc { open_file }
    @callback_refs << open_file_proc
    @file_menu.add('command', label: 'Open...', accel: 'Ctrl+O', command: open_file_proc)

    save_file_proc = proc { save_file }
    @callback_refs << save_file_proc
    @file_menu.add('command', label: 'Save', accel: 'Ctrl+S', command: save_file_proc)

    save_as_file_proc = proc { save_as_file }
    @callback_refs << save_as_file_proc
    @file_menu.add('command', label: 'Save As...', accel: 'Ctrl+Shift+S', command: save_as_file_proc)
    
    @file_menu.add('separator')

    open_recovery_file_proc = proc { open_recovery_file }
    @callback_refs << open_recovery_file_proc
    @file_menu.add('command', label: 'Open Recovery Backup...', command: open_recovery_file_proc)
    
    @file_menu.add('separator')

    quit_app_proc_menu = proc { quit_app }
    @callback_refs << quit_app_proc_menu
    @file_menu.add('command', label: 'Quit', accel: 'Ctrl+Q', command: quit_app_proc_menu)

    file_btn_cmd = proc {
      x = @file_btn.winfo_rootx
      y = @file_btn.winfo_rooty + @file_btn.winfo_height
      @file_menu.popup(x, y)
    }
    @callback_refs << file_btn_cmd
    @file_btn = Tk::Tile::Button.new(@menubar) {
      style 'Menubar.TButton'
      text "File"
      command file_btn_cmd
    }
    @file_btn.pack(side: 'left', padx: Theme::SPACING[:xs], pady: 2)

    @edit_menu = TkMenu.new(@root, tearoff: 0, font: Theme::FONTS[:ui])

    open_find_dialog_proc = proc { open_find_dialog }
    @callback_refs << open_find_dialog_proc
    @edit_menu.add('command', label: 'Find / Replace...', accel: 'Ctrl+F', command: open_find_dialog_proc)

    edit_btn_cmd = proc {
      x = @edit_btn.winfo_rootx
      y = @edit_btn.winfo_rooty + @edit_btn.winfo_height
      @edit_menu.popup(x, y)
    }
    @callback_refs << edit_btn_cmd
    @edit_btn = Tk::Tile::Button.new(@menubar) {
      style 'Menubar.TButton'
      text "Edit"
      command edit_btn_cmd
    }
    @edit_btn.pack(side: 'left', padx: Theme::SPACING[:xs], pady: 2)

    @view_menu = TkMenu.new(@root, tearoff: 0, font: Theme::FONTS[:ui])

    zoom_in_proc = proc { zoom_in }
    @callback_refs << zoom_in_proc
    @view_menu.add('command', label: 'Zoom In', accel: 'Ctrl++', command: zoom_in_proc)

    zoom_out_proc = proc { zoom_out }
    @callback_refs << zoom_out_proc
    @view_menu.add('command', label: 'Zoom Out', accel: 'Ctrl+-', command: zoom_out_proc)

    reset_zoom_proc = proc { reset_zoom }
    @callback_refs << reset_zoom_proc
    @view_menu.add('command', label: 'Reset Zoom', accel: 'Ctrl+0', command: reset_zoom_proc)
    
    @view_menu.add('separator')

    inc_spacing_proc = proc { change_spacing(2) }
    @callback_refs << inc_spacing_proc
    @view_menu.add('command', label: 'Increase Line Spacing', command: inc_spacing_proc)

    dec_spacing_proc = proc { change_spacing(-2) }
    @callback_refs << dec_spacing_proc
    @view_menu.add('command', label: 'Decrease Line Spacing', command: dec_spacing_proc)

    @view_menu.add('separator')

    inc_padding_proc = proc { change_text_padding(2) }
    @callback_refs << inc_padding_proc
    @view_menu.add('command', label: 'Increase Text Padding', command: inc_padding_proc)

    dec_padding_proc = proc { change_text_padding(-2) }
    @callback_refs << dec_padding_proc
    @view_menu.add('command', label: 'Decrease Text Padding', command: dec_padding_proc)
    
    @view_menu.add('separator')

    goto_line_dialog_proc = proc { goto_line_dialog }
    @callback_refs << goto_line_dialog_proc
    @view_menu.add('command', label: 'Go to Line...', accel: 'Ctrl+G', command: goto_line_dialog_proc)

    view_btn_cmd = proc {
      x = @view_btn.winfo_rootx
      y = @view_btn.winfo_rooty + @view_btn.winfo_height
      @view_menu.popup(x, y)
    }
    @callback_refs << view_btn_cmd
    @view_btn = Tk::Tile::Button.new(@menubar) {
      style 'Menubar.TButton'
      text "View"
      command view_btn_cmd
    }
    @view_btn.pack(side: 'left', padx: Theme::SPACING[:xs], pady: 2)

    @theme_menu = TkMenu.new(@root, tearoff: 0, font: Theme::FONTS[:ui])

    sepia_theme_proc = proc { select_theme(:sepia) }
    @callback_refs << sepia_theme_proc
    @theme_menu.add('command', label: 'Sepia', command: sepia_theme_proc)

    dark_theme_proc = proc { select_theme(:dark) }
    @callback_refs << dark_theme_proc
    @theme_menu.add('command', label: 'Dark', command: dark_theme_proc)

    light_theme_proc = proc { select_theme(:light) }
    @callback_refs << light_theme_proc
    @theme_menu.add('command', label: 'Light', command: light_theme_proc)

    theme_btn_cmd = proc {
      x = @theme_btn.winfo_rootx
      y = @theme_btn.winfo_rooty + @theme_btn.winfo_height
      @theme_menu.popup(x, y)
    }
    @callback_refs << theme_btn_cmd
    @theme_btn = Tk::Tile::Button.new(@menubar) {
      style 'Menubar.TButton'
      text "Theme"
      command theme_btn_cmd
    }
    @theme_btn.pack(side: 'left', padx: Theme::SPACING[:xs], pady: 2)

    header_btn_cmd = proc { me.show_header_popup }
    @callback_refs << header_btn_cmd
    @header_btn = Tk::Tile::Button.new(@menubar) {
      style 'Menubar.TButton'
      text "Headings"
      command header_btn_cmd
    }
    @header_btn.pack(side: 'right', padx: Theme::SPACING[:sm], pady: 2)

    # Thin separator between menu bar and toolbar
    @bar_separator = Tk::Tile::Separator.new(@root) { orient 'horizontal' }
    @bar_separator.pack(fill: 'x')

    @toolbar = Tk::Tile::Frame.new(@root)
    @toolbar.style = 'Toolbar.TFrame'
    @toolbar.pack(fill: 'x')

    # Toolbar groups: emphasis | headings | undo/redo | read-only
    bold_btn_cmd = proc { me.insert_bold }
    @callback_refs << bold_btn_cmd
    @bold_btn = Tk::Tile::Button.new(@toolbar) { text "B"; style 'Toolbar.TButton'; command bold_btn_cmd }
    @bold_btn.pack(side: 'left', padx: 2, pady: 2)
    @bold_btn.configure(font: [Theme::FONTS[:ui][0], Theme::FONTS[:ui][1], 'bold'])

    italic_btn_cmd = proc { me.insert_italic }
    @callback_refs << italic_btn_cmd
    @italic_btn = Tk::Tile::Button.new(@toolbar) { text "I"; style 'Toolbar.TButton'; command italic_btn_cmd }
    @italic_btn.pack(side: 'left', padx: 2, pady: 2)
    @italic_btn.configure(font: [Theme::FONTS[:ui][0], Theme::FONTS[:ui][1], 'italic'])

    # separator between emphasis and headings
    Tk::Tile::Separator.new(@toolbar) { orient 'vertical' }.pack(side: 'left', fill: 'y', padx: 6, pady: 2)

    h1_btn_cmd = proc { me.insert_h1 }
    @callback_refs << h1_btn_cmd
    @h1_btn = Tk::Tile::Button.new(@toolbar) { text "H1"; style 'Toolbar.TButton'; command h1_btn_cmd }
    @h1_btn.pack(side: 'left', padx: 1, pady: 2)

    h2_btn_cmd = proc { me.insert_h2 }
    @callback_refs << h2_btn_cmd
    @h2_btn = Tk::Tile::Button.new(@toolbar) { text "H2"; style 'Toolbar.TButton'; command h2_btn_cmd }
    @h2_btn.pack(side: 'left', padx: 1, pady: 2)

    h3_btn_cmd = proc { me.insert_h3 }
    @callback_refs << h3_btn_cmd
    @h3_btn = Tk::Tile::Button.new(@toolbar) { text "H3"; style 'Toolbar.TButton'; command h3_btn_cmd }
    @h3_btn.pack(side: 'left', padx: 1, pady: 2)

    Tk::Tile::Separator.new(@toolbar) { orient 'vertical' }.pack(side: 'left', fill: 'y', padx: 6, pady: 2)

    h4_btn_cmd = proc { me.insert_h4 }
    @callback_refs << h4_btn_cmd
    @h4_btn = Tk::Tile::Button.new(@toolbar) { text "H4"; style 'Toolbar.TButton'; command h4_btn_cmd }
    @h4_btn.pack(side: 'left', padx: 1, pady: 2)

    h5_btn_cmd = proc { me.insert_h5 }
    @callback_refs << h5_btn_cmd
    @h5_btn = Tk::Tile::Button.new(@toolbar) { text "H5"; style 'Toolbar.TButton'; command h5_btn_cmd }
    @h5_btn.pack(side: 'left', padx: 1, pady: 2)

    h6_btn_cmd = proc { me.insert_h6 }
    @callback_refs << h6_btn_cmd
    @h6_btn = Tk::Tile::Button.new(@toolbar) { text "H6"; style 'Toolbar.TButton'; command h6_btn_cmd }
    @h6_btn.pack(side: 'left', padx: 1, pady: 2)

    Tk::Tile::Separator.new(@toolbar) { orient 'vertical' }.pack(side: 'left', fill: 'y', padx: 6, pady: 2)

    undo_btn_cmd = proc { @editor.text.edit_undo rescue nil }
    @callback_refs << undo_btn_cmd
    @undo_btn = Tk::Tile::Button.new(@toolbar) { text "Undo"; style 'Toolbar.TButton'; command undo_btn_cmd }
    @undo_btn.pack(side: 'left', padx: 2, pady: 2)

    redo_btn_cmd = proc { @editor.text.edit_redo rescue nil }
    @callback_refs << redo_btn_cmd
    @redo_btn = Tk::Tile::Button.new(@toolbar) { text "Redo"; style 'Toolbar.TButton'; command redo_btn_cmd }
    @redo_btn.pack(side: 'left', padx: 2, pady: 2)

    readonly_btn_cmd = proc { me.toggle_readonly }
    @callback_refs << readonly_btn_cmd
    @readonly_btn = Tk::Tile::Button.new(@toolbar) { 
      text "Read-Only"; 
      style 'Toolbar.TButton'; 
      command readonly_btn_cmd 
    }
    @readonly_btn.pack(side: 'right', padx: Theme::SPACING[:sm], pady: 2)

    # Single-document layout. Notebook kept out of the visible chrome so a
    # future multi-tab can reintroduce it without a fake single tab strip.
    @tab_frame = Tk::Tile::Frame.new(@root) { style 'Tab.TFrame' }
    @tab_frame.pack(fill: 'both', expand: true)

    @status_bar = Tk::Tile::Frame.new(@tab_frame) { style 'Status.TFrame' }
    @status_bar.pack(fill: 'x', side: 'bottom')

    @status_left = Tk::Tile::Label.new(@status_bar) { text "Words: 0"; style 'Status.TLabel' }
    @status_heading = Tk::Tile::Label.new(@status_bar) { text ""; style 'Status.TLabel' }
    @status_center = Tk::Tile::Label.new(@status_bar) { text @current_filename; style 'Status.TLabel'; anchor 'center' }
    @status_right = Tk::Tile::Label.new(@status_bar) { text "Edit Mode"; style 'Status.TLabel' }

    @status_left.pack(side: 'left', padx: 12, pady: 4)
    @status_heading.pack(side: 'left', padx: 8, pady: 4)
    @status_center.pack(side: 'left', fill: 'x', expand: true, padx: 8, pady: 4)
    @status_right.pack(side: 'right', padx: 12, pady: 4)

    @editor = EditorPane.new(@tab_frame, self)
  end

  def update_status_left
    text_content = @editor.text.get('1.0', 'end - 1 char')
    words = text_content.split.size
    chars = text_content.length
    minutes = (words / 200.0).ceil
    time_str = minutes < 1 ? "< 1 min" : "#{minutes} min"
    @status_left.text = "Words: #{words} | Chars: #{chars} | Time: #{time_str}"
  end

  def update_header_list
    @editor.highlighter.rebuild_headers_cache
    update_current_header
  end

  def show_header_popup
    close_header_popup

    headers = @editor.highlighter.get_headers
    c = Theme::THEMES[@current_theme]

    @header_popup = TkToplevel.new(@root) do
      overrideredirect true
      borderwidth 1
      relief 'solid'
      background c[:border]
    end

    @popup_list_frame = TkFrame.new(@header_popup) { background c[:editor_bg] }.pack(fill: 'both', expand: true)
    @header_popup_scroll = Tk::Tile::Scrollbar.new(@popup_list_frame).pack(side: 'right', fill: 'y')
    scroll = @header_popup_scroll

    visible_rows = [headers.size, 15].min
    visible_rows = 1 if visible_rows == 0

    header_scroll_set_proc = proc { |first, last| scroll.set(first, last) }
    @callback_refs << header_scroll_set_proc
    
    @popup_list = TkListbox.new(@popup_list_frame, {
      font: Theme::FONTS[:ui],
      height: visible_rows,
      width: 35,
      background: c[:editor_bg],
      foreground: c[:text_fg],
      selectbackground: c[:selection],
      selectforeground: c[:text_fg],
      borderwidth: 0,
      highlightthickness: 0,
      activestyle: 'none',
      yscrollcommand: header_scroll_set_proc
    })
    @popup_list.pack(side: 'left', fill: 'both', expand: true)
    
    list_yview_proc = proc { |*args| @popup_list.yview(*args) }
    @callback_refs << list_yview_proc
    scroll.command list_yview_proc

    if headers.empty?
      @popup_list.insert('end', 'No Headers Found')
      @popup_list.state = 'disabled'
    else
      current_header_line = @editor.highlighter.get_current_header_line
      headers.each_with_index do |h, idx|
        @popup_list.insert('end', h[:text])
        if h[:line] == current_header_line
          @popup_list.selection_set(idx)
          @popup_list.see(idx)
        end
      end
    end

    header_jump_proc = proc {
      sel_indices = @popup_list.curselection
      if sel_indices && !sel_indices.empty? && !headers.empty?
        sel_idx = sel_indices[0].to_i
        line_num = headers[sel_idx][:line]
        @editor.text.mark_set('insert', "#{line_num}.0")
        @editor.text.see("#{line_num}.0")
        @editor.text.focus
      end
      close_header_popup
    }
    @callback_refs << header_jump_proc

    @popup_list.bind('Return', header_jump_proc)
    @popup_list.bind('Double-Button-1', header_jump_proc)
    
    header_escape_proc1 = proc { close_header_popup }
    @callback_refs << header_escape_proc1
    @popup_list.bind('Escape', header_escape_proc1)
    
    header_escape_proc2 = proc { close_header_popup }
    @callback_refs << header_escape_proc2
    @header_popup.bind('Escape', header_escape_proc2)

    Tk.update_idletasks
    
    popup_w = @popup_list.winfo_reqwidth + 20
    popup_h = @popup_list.winfo_reqheight + 4

    screen_w = @root.winfo_screenwidth
    screen_h = @root.winfo_screenheight

    x = @header_btn.winfo_rootx
    y = @header_btn.winfo_rooty + @header_btn.winfo_height

    if x + popup_w > screen_w
      x = screen_w - popup_w - 10
    end
    
    if y + popup_h > screen_h
      y = screen_h - popup_h - 10
    end

    x = 10 if x < 10
    y = 10 if y < 10

    @header_popup.geometry("+#{x}+#{y}")

    @header_popup.deiconify
    @header_popup.raise
    @popup_list.focus
  end

  def close_header_popup
    return unless @header_popup && @header_popup.exist?

    if @header_popup_scroll
      begin
        @header_popup_scroll.event_generate('ButtonRelease-1')
      rescue
      end
    end

    @header_popup.destroy
    @header_popup = nil
    @header_popup_scroll = nil
    @popup_list = nil
    @popup_list_frame = nil
  end

  def open_find_dialog
    begin
      if @find_dialog && @find_dialog.exist?
        @find_dialog.focus
        return
      end
    rescue TkCallbackBreak, RuntimeError
      @find_dialog = nil
    end
    @find_dialog = FindReplaceDialog.new(@root, @editor)
  end

  def insert_bold; @editor.insert_bold; end
  def insert_italic; @editor.insert_italic; end

  def insert_h1
    @editor.text.edit_separator
    @editor.text.insert('insert linestart', "# ")
    line = @editor.text.index('insert').split('.')[0].to_i
    @editor.highlighter.parse_line(line)
    @editor.highlighter.rebuild_headers_cache
    @editor.text.edit_separator
    mark_modified
    update_current_header
    update_status_left
  end

  def insert_h2
    @editor.text.edit_separator
    @editor.text.insert('insert linestart', "## ")
    line = @editor.text.index('insert').split('.')[0].to_i
    @editor.highlighter.parse_line(line)
    @editor.highlighter.rebuild_headers_cache
    @editor.text.edit_separator
    mark_modified
    update_current_header
    update_status_left
  end

  def insert_h3
    @editor.text.edit_separator
    @editor.text.insert('insert linestart', "### ")
    line = @editor.text.index('insert').split('.')[0].to_i
    @editor.highlighter.parse_line(line)
    @editor.highlighter.rebuild_headers_cache
    @editor.text.edit_separator
    mark_modified
    update_current_header
    update_status_left
  end

  def insert_h4
    @editor.text.edit_separator
    @editor.text.insert('insert linestart', "#### ")
    line = @editor.text.index('insert').split('.')[0].to_i
    @editor.highlighter.parse_line(line)
    @editor.highlighter.rebuild_headers_cache
    @editor.text.edit_separator
    mark_modified
    update_current_header
    update_status_left
  end

  def insert_h5
    @editor.text.edit_separator
    @editor.text.insert('insert linestart', "##### ")
    line = @editor.text.index('insert').split('.')[0].to_i
    @editor.highlighter.parse_line(line)
    @editor.highlighter.rebuild_headers_cache
    @editor.text.edit_separator
    mark_modified
    update_current_header
    update_status_left
  end

  def insert_h6
    @editor.text.edit_separator
    @editor.text.insert('insert linestart', "###### ")
    line = @editor.text.index('insert').split('.')[0].to_i
    @editor.highlighter.parse_line(line)
    @editor.highlighter.rebuild_headers_cache
    @editor.text.edit_separator
    mark_modified
    update_current_header
    update_status_left
  end

  def toggle_readonly
    if @editor.text.cget('state') == 'normal'
      @editor.text.state = 'disabled'
      @readonly_btn.state = 'pressed' if @readonly_btn
    else
      @editor.text.state = 'normal'
      @readonly_btn.state = '!pressed' if @readonly_btn
    end
    update_current_header
  end

  def rotate_backups
    return unless File.exist?(@backup_file)

    FileUtils.mv(@backup_file, "#{@backup_file}.bak", force: true)
    return unless @recovery_meta && File.exist?(@recovery_meta)

    FileUtils.mv(@recovery_meta, "#{@recovery_meta}.bak", force: true)
  end

  def confirm_discard_changes(action_label)
    return true unless @is_modified
    answer = Tk.messageBox(
      type: 'yesnocancel', icon: 'question', title: 'Unsaved Changes',
      message: "You have unsaved changes.\nSave before #{action_label}?"
    )
    case answer
    when 'yes'
      save_file
      return !@is_modified
    when 'no'
      return true
    else
      return false
    end
  end

  def new_file
    return unless confirm_discard_changes('creating a new document')
    @editor.text.state = 'normal'
    @editor.text.delete('1.0', 'end')
    @editor.reset_auto_close_tracking
    @editor.text.edit_reset
    @editor.text.tag_names.each do |tag|
      @editor.text.tag_remove(tag, '1.0', 'end')
    end
    @is_modified = false
    @current_filename = 'Untitled.md'
    @current_filepath = nil
    @status_center.text = @current_filename
    update_window_title
    @editor.highlighter.rebuild_headers_cache
    update_status_left
    update_current_header
  end

  def open_file
    return unless confirm_discard_changes('opening another file')

    filename = Tk.getOpenFile(filetypes: [["Markdown Files", ".md"], ["All Files", "*"]])
    return if filename.nil? || filename.empty?

    begin
      content = File.read(filename, encoding: 'UTF-8')
    rescue => e
      Tk.messageBox(type: 'ok', icon: 'error', title: "Error Opening File", message: e.message)
      return
    end

    @editor.text.state = 'normal'
    @editor.text.delete('1.0', 'end')
    @editor.text.value = content
    @editor.reset_auto_close_tracking
    @editor.text.edit_reset
    @current_filepath = filename
    @current_filename = File.basename(filename)
    @is_modified = false
    @status_center.text = @current_filename
    update_window_title
    update_status_left

    @editor.highlighter.parse_entire_document
    update_current_header
  end

  def open_recovery_file
    choices = recovery_choices
    if choices.empty?
      Tk.messageBox(type: 'ok', icon: 'info', title: 'No Recovery Data',
                    message: 'No crash recovery data was found.')
      return
    end

    chosen_file = choose_recovery_path(choices)
    return unless chosen_file
    return unless confirm_discard_changes('opening recovery backup')

    load_recovery_file(chosen_file)
  end

  def choose_recovery_path(choices)
    return nil if choices.empty?
    return choices.first[:path] if choices.length == 1

    chosen = nil
    dialog = TkToplevel.new(@root)
    dialog.title = 'Open Recovery'
    dialog.transient(@root) if @root
    c = Theme::THEMES[@current_theme] || Theme::THEMES[:sepia]
    dialog.background(c[:window_bg])

    intro = Tk::Tile::Label.new(dialog)
    intro.text = 'Choose which recovery to open.'
    intro.pack(anchor: 'w', padx: 12, pady: 8)

    choices.each do |choice|
      row = Tk::Tile::Frame.new(dialog)
      row.pack(fill: 'x', padx: 12, pady: 4)
      label = Tk::Tile::Label.new(row)
      label.text = choice[:summary]
      label.configure(wraplength: 420, justify: 'left')
      label.pack(anchor: 'w')
      command = proc { chosen = choice[:path]; dialog.destroy }
      @callback_refs << command
      button = Tk::Tile::Button.new(row)
      button.text = choice[:label]
      button.command = command
      button.pack(anchor: 'w', pady: 2)
    end

    cancel = proc { dialog.destroy }
    @callback_refs << cancel
    cancel_button = Tk::Tile::Button.new(dialog)
    cancel_button.text = 'Cancel'
    cancel_button.command = cancel
    cancel_button.pack(pady: 8)
    dialog.protocol('WM_DELETE_WINDOW', cancel)
    dialog.grab
    dialog.wait_window
    chosen
  end

  def load_recovery_file(path)
    content = File.read(path, encoding: 'UTF-8')
    meta = read_recovery_meta(path)

    @editor.text.state = 'normal'
    @editor.text.delete('1.0', 'end')
    @editor.text.value = content
    @editor.reset_auto_close_tracking
    @editor.text.edit_reset
    @editor.text.tag_names.each do |tag|
      @editor.text.tag_remove(tag, '1.0', 'end')
    end

    source = meta['path']
    if source.is_a?(String) && !source.strip.empty?
      @current_filepath = source
      @current_filename = File.basename(source)
    else
      @current_filepath = nil
      @current_filename = 'Untitled.md'
    end
    @is_modified = true
    @status_center.text = @current_filename
    update_window_title
    @editor.highlighter.parse_entire_document
    update_header_list
    update_status_left
    update_current_header
    true
  rescue SystemCallError, EncodingError => e
    Tk.messageBox(type: 'ok', icon: 'error', title: 'Error Reading Backup', message: e.message)
    false
  end

  def save_file
    if @current_filepath.nil?
      save_as_file
      return
    end

    begin
      File.write(@current_filepath, @editor.text.get('1.0', 'end - 1 char'), encoding: 'UTF-8')
    rescue => e
      Tk.messageBox(type: 'ok', icon: 'error', title: "Error Saving File", message: e.message)
      return
    end

    @is_modified = false
    @status_center.text = @current_filename
    update_window_title
    update_status_left
    clear_current_recovery
  end

  def save_as_file
    filename = Tk.getSaveFile(filetypes: [["Markdown Files", ".md"], ["All Files", "*"]])
    return if filename.nil? || filename.empty?

    if File.exist?(filename)
      answer = Tk.messageBox(type: 'yesno', icon: 'question', title: 'Overwrite File?',
                            message: "File '#{File.basename(filename)}' already exists. Overwrite?")
      return if answer != 'yes'
    end

    @current_filepath = filename
    @current_filename = File.basename(filename)
    save_file
  end

  def apply_theme
    c = Theme::THEMES[@current_theme] || Theme::THEMES[:sepia]
    @current_theme = :sepia unless Theme::THEMES.key?(@current_theme)
    ui_font = Theme::FONTS[:ui]

    @root.background(c[:window_bg])

    @editor.text.background(c[:editor_bg])
    @editor.text.foreground(c[:text_fg])
    @editor.text.configure(insertbackground: c[:text_fg], selectbackground: c[:selection], selectforeground: c[:text_fg], highlightbackground: c[:border], highlightcolor: c[:border])

    Tk::Tile::Style.configure('TFrame', background: c[:window_bg])
    Tk::Tile::Style.configure('Menubar.TFrame', background: c[:window_bg])
    Tk::Tile::Style.configure('Toolbar.TFrame', background: c[:toolbar_bg])
    Tk::Tile::Style.configure('Status.TFrame', background: c[:status_bg])
    Tk::Tile::Style.configure('Tab.TFrame', background: c[:window_bg])

    Tk::Tile::Style.configure('TButton', font: ui_font, background: c[:button_bg], foreground: c[:text_fg], borderwidth: 1, relief: 'solid', focusthickness: 0, padding: "#{Theme::SPACING[:xs]} #{Theme::SPACING[:xs]}")
    Tk::Tile::Style.map('TButton',
      background: [:active, c[:button_hover], :pressed, c[:button_pressed]],
      bordercolor: [:active, c[:border], :focus, c[:accent]],
      foreground: [:active, c[:text_fg]]
    )

    Tk::Tile::Style.configure('Toolbar.TButton', font: ui_font, background: c[:button_bg], foreground: c[:text_fg], borderwidth: 1, relief: 'solid', focusthickness: 0, padding: '1 2')
    Tk::Tile::Style.map('Toolbar.TButton',
      background: [:active, c[:button_hover], :pressed, c[:button_pressed]],
      bordercolor: [:active, c[:border], :focus, c[:accent]],
      foreground: [:active, c[:text_fg]]
    )

    Tk::Tile::Style.configure('Menubar.TButton', font: ui_font, background: c[:window_bg], foreground: c[:text_fg], borderwidth: 0, relief: 'flat', focusthickness: 0, padding: "#{Theme::SPACING[:sm]} #{Theme::SPACING[:xs]}")
    Tk::Tile::Style.map('Menubar.TButton',
      background: [:active, c[:menu_hover], :pressed, c[:button_pressed]],
      borderwidth: [:active, 1, :pressed, 1],
      relief: [:active, 'solid', :pressed, 'solid'],
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
    @editor.text.configure(
      font: [f[0], @base_font_size],
      spacing1: @line_spacing, spacing2: @line_spacing, spacing3: @line_spacing,
      padx: @text_padding_x, pady: @text_padding_y
    )
    @editor.highlighter.apply_font_settings(@base_font_size)
  end

  def update_current_header
    header_text = @editor.highlighter.get_current_header_text
    mode_text = @editor.text.cget('state') == 'normal' ? "Edit" : "Read-Only"
    @status_right.text = mode_text

    if header_text
      display_text = header_text.length > 40 ? header_text[0..37] + "..." : header_text
      @status_heading.text = display_text
    else
      @status_heading.text = ""
    end
    # Headings button always says what it does
    @header_btn.text = "Headings" if @header_btn
  end

  def select_theme(name)
    @current_theme = name
    apply_theme
    persist_settings
  end

  def persist_settings
    return unless @settings

    @settings.replace(
      theme: @current_theme,
      font_size: @base_font_size,
      line_spacing: @line_spacing,
      text_padding_x: @text_padding_x,
      text_padding_y: @text_padding_y
    )
    @settings.save
  rescue StandardError
    false
  end

  def zoom_in
    @base_font_size = [24, @base_font_size + 1].min
    apply_font_settings
    persist_settings
  end

  def zoom_out
    @base_font_size = [8, @base_font_size - 1].max
    apply_font_settings
    persist_settings
  end

  def reset_zoom
    @base_font_size = 12
    apply_font_settings
    persist_settings
  end

  def goto_line_dialog
    begin
      if @goto_dialog && @goto_dialog.exist?
        @goto_dialog.focus
        return
      end
    rescue TkCallbackBreak, RuntimeError
      @goto_dialog = nil
    end

    @goto_dialog = TkToplevel.new(@root) { title "Go to Line" }
    @goto_dialog.transient(@root)
    # content sizes itself
    @goto_dialog.grab_set
    c = Theme::THEMES[@current_theme] || Theme::THEMES[:sepia]
    @goto_dialog.background(c[:window_bg])

    @goto_label = Tk::Tile::Label.new(@goto_dialog) { text "Enter line number:" }
    @goto_label.pack(pady: 10)
    @goto_entry = Tk::Tile::Entry.new(@goto_dialog) { width 20 }
    @goto_entry.pack(pady: 5)
    @goto_entry.focus

    goto_jump_proc = proc {
      begin
        line_num = Integer(@goto_entry.value)
        total_lines = @editor.text.index('end').split('.')[0].to_i - 1

        if line_num < 1
          Tk.messageBox(type: 'ok', icon: 'error', title: 'Invalid Line', message: 'Line number must be at least 1')
          @goto_entry.focus
          next
        end

        if line_num > total_lines
          Tk.messageBox(type: 'ok', icon: 'error', title: 'Invalid Line', message: "Line number must be at most #{total_lines}")
          @goto_entry.focus
          next
        end

        @editor.text.mark_set('insert', "#{line_num}.0")
        @editor.text.see("#{line_num}.0")
        @editor.text.focus
        @goto_dialog.destroy
      rescue ArgumentError
        Tk.messageBox(type: 'ok', icon: 'error', title: 'Invalid Input', message: 'Please enter a valid number')
        @goto_entry.focus
      end
    }
    @callback_refs << goto_jump_proc

    @goto_entry.bind('Return', goto_jump_proc)
    @goto_btn = Tk::Tile::Button.new(@goto_dialog) { text "Go"; command goto_jump_proc }
    @goto_btn.pack(pady: 5)

    goto_escape_proc = proc { @goto_dialog.destroy }
    @callback_refs << goto_escape_proc
    @goto_dialog.bind('Escape', goto_escape_proc)
    @goto_dialog.protocol('WM_DELETE_WINDOW', goto_escape_proc)
  end

  def change_spacing(amount)
    @line_spacing = [[0, @line_spacing + amount].max, 40].min
    apply_font_settings
    persist_settings
  end

  def change_text_padding(amount)
    @text_padding_x = [[2, @text_padding_x + amount].max, 100].min
    @text_padding_y = [[2, @text_padding_y + amount].max, 100].min
    apply_font_settings
    persist_settings
  end

  def quit_app
    if @is_modified
      answer = Tk.messageBox(type: 'yesnocancel', icon: 'question', title: 'Unsaved Changes', message: 'You have unsaved changes. Do you want to save before quitting?')
      if answer == 'yes'
        save_file
        if @is_modified
          return
        end
      elsif answer == 'cancel'
        return
      end
    end

    Tk.after_cancel(@backup_check_timer) if @backup_check_timer
    @editor.cancel_timers if @editor
    persist_settings
    release_recovery_lock

    @root.destroy
  end

  def emergency_save!
    return unless @editor && @editor.text
    return unless @is_modified
    content = @editor.text.get('1.0', 'end - 1 char')
    write_backup_atomic(content)
  end

  def run
    Tk.mainloop
  end
end
