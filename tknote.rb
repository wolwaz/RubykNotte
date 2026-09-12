require 'tk'
require 'tkextlib/tile'
require 'fileutils'
require 'json'

# ==========================================
# 0. SETTINGS
# ==========================================
module RubykNotte
  class Settings
    DEFAULTS = {
      theme: :sepia,
      font_size: 12,
      line_spacing: 4,
      text_padding_x: 25,
      text_padding_y: 20
    }.freeze

    def initialize(path = nil)
      @path = path || File.join(Dir.home, '.config', 'rubyknotte', 'settings.json')
      @values = DEFAULTS.dup
      load
    end

    def get(key)
      key = key.to_sym
      @values.fetch(key, DEFAULTS[key])
    end

    def set(key, value)
      key = key.to_sym
      return false unless DEFAULTS.key?(key)
      @values[key] = normalize(key, value)
      true
    end

    def save
      FileUtils.mkdir_p(File.dirname(@path))
      tmp = "#{@path}.tmp"
      File.write(tmp, JSON.pretty_generate(@values.transform_keys(&:to_s)), encoding: 'UTF-8')
      FileUtils.mv(tmp, @path, force: true)
      true
    rescue SystemCallError, JSON::GeneratorError
      false
    ensure
      File.delete(tmp) if defined?(tmp) && File.exist?(tmp)
    end

    private

    def load
      return unless File.file?(@path)
      raw = JSON.parse(File.read(@path, encoding: 'UTF-8'))
      raw.each { |key, value| set(key, value) } if raw.is_a?(Hash)
    rescue JSON::ParserError, SystemCallError
      @values = DEFAULTS.dup
    end

    def normalize(key, value)
      case key
      when :theme then value.to_s.to_sym
      when :font_size then [[value.to_i, 8].max, 72].min
      when :line_spacing then [[value.to_i, 0].max, 40].min
      when :text_padding_x, :text_padding_y then [[value.to_i, 0].max, 100].min
      else value
      end
    end
  end
end

# ==========================================
# 1. CENTRALIZED DESIGN SYSTEM
# ==========================================
module Theme
  SPACING = {
    xs: 2, sm: 6, md: 8, lg: 12, xl: 16,
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
      menu_hover: '#D9CBB0', md_symbol: '#A08C70',
      code_bg: '#E0D5BD', code_fg: '#8B4513',
      blockquote_fg: '#705E4B', hr_color: '#A08C70',
      strike_fg: '#9A8870'
    },
    dark: {
      window_bg: '#2B2420', toolbar_bg: '#241F1C', status_bg: '#241F1C',
      editor_bg: '#2F2925', text_fg: '#E2D5C2', muted_fg: '#AFA18E',
      border: '#4A4038', button_bg: '#39312C', button_hover: '#474039',
      button_pressed: '#51473E', accent: '#5AAFE3', selection: '#3E6E8C',
      menu_hover: '#474039', md_symbol: '#81705C',
      code_bg: '#3A332E', code_fg: '#E8A07A',
      blockquote_fg: '#AFA18E', hr_color: '#81705C',
      strike_fg: '#807060'
    }
  }
end

# ==========================================
# 2. MARKDOWN HIGHLIGHTER
# ==========================================
class MarkdownHighlighter
  attr_reader :headers_cache

  def initialize(text_widget)
    @text = text_widget
    @headers_cache = []
    setup_tags
  end

  def setup_tags
    f = Theme::FONTS[:editor]
    @text.tag_configure('md_symbol', foreground: '#888888')
    @text.tag_configure('bold', font: [f[0], f[1], 'bold'])
    @text.tag_configure('italic', font: [f[0], f[1], 'italic'])
    @text.tag_configure('bold_italic', font: [f[0], f[1], 'bold italic'])
    @text.tag_configure('h1', font: [f[0], f[1] + 6, 'bold'], foreground: '#333333')
    @text.tag_configure('h2', font: [f[0], f[1] + 4, 'bold'], foreground: '#444444')
    @text.tag_configure('h3', font: [f[0], f[1] + 2, 'bold'], foreground: '#555555')
    @text.tag_configure('h4', font: [f[0], f[1] + 1, 'bold'], foreground: '#666666')
    @text.tag_configure('h5', font: [f[0], f[1] + 1, 'bold'], foreground: '#666666')
    @text.tag_configure('h6', font: [f[0], f[1] + 1, 'bold'], foreground: '#666666')
    @text.tag_configure('hr', foreground: '#A08C70', justify: 'center', spacing1: 8, spacing3: 8, font: [f[0], f[1] + 2, 'bold'])
    @text.tag_configure('blockquote', lmargin1: 30, lmargin2: 30, foreground: '#705E4B', spacing1: 2, spacing3: 2)
    @text.tag_configure('code', background: '#E0D5BD', foreground: '#8B4513', font: ['Courier', f[1]])
    @text.tag_configure('strikethrough', font: [f[0], f[1], 'overstrike'], foreground: '#9A8870')
    @text.tag_raise('bold'); @text.tag_raise('italic'); @text.tag_raise('bold_italic')
    @text.tag_raise('strikethrough'); @text.tag_raise('code'); @text.tag_raise('md_symbol')
  end

  def apply_theme(colors)
    @text.tag_configure('md_symbol', foreground: colors[:md_symbol])
    (1..6).each { |i| @text.tag_configure("h#{i}", foreground: colors[:text_fg]) }
    @text.tag_configure('hr', foreground: colors[:hr_color])
    @text.tag_configure('blockquote', foreground: colors[:blockquote_fg])
    @text.tag_configure('code', background: colors[:code_bg], foreground: colors[:code_fg])
    @text.tag_configure('strikethrough', foreground: colors[:strike_fg])
  end

  def apply_font_settings(base_font_size)
    f = Theme::FONTS[:editor]
    @text.tag_configure('bold', font: [f[0], base_font_size, 'bold'])
    @text.tag_configure('italic', font: [f[0], base_font_size, 'italic'])
    @text.tag_configure('bold_italic', font: [f[0], base_font_size, 'bold italic'])
    @text.tag_configure('h1', font: [f[0], base_font_size + 6, 'bold'])
    @text.tag_configure('h2', font: [f[0], base_font_size + 4, 'bold'])
    @text.tag_configure('h3', font: [f[0], base_font_size + 2, 'bold'])
    @text.tag_configure('h4', font: [f[0], base_font_size + 1, 'bold'])
    @text.tag_configure('h5', font: [f[0], base_font_size + 1, 'bold'])
    @text.tag_configure('h6', font: [f[0], base_font_size + 1, 'bold'])
    @text.tag_configure('code', font: ['Courier', base_font_size])
    @text.tag_configure('strikethrough', font: [f[0], base_font_size, 'overstrike'])
    @text.tag_configure('hr', font: [f[0], base_font_size + 2, 'bold'])
  end

  def parse_line(line_num, force_render = false)
    start_idx = "#{line_num}.0"; end_idx = "#{line_num}.end"; line_text = @text.get(start_idx, end_idx)
    ['h1','h2','h3','h4','h5','h6','bold','italic','bold_italic','md_symbol','hr','blockquote','code','strikethrough'].each { |tag| @text.tag_remove(tag, start_idx, end_idx) }
    if m = line_text.match(/^(\#{1,6})\s+(.*)/)
      hash_count = m[1].length; @text.tag_add("h#{hash_count}", start_idx, end_idx); @text.tag_add('md_symbol', "#{line_num}.0", "#{line_num}.#{hash_count}")
    end
    if line_text.match(/^\s*(-{3,}|\*{3,}|_{3,})\s*$/)
      cursor_line = @text.index('insert').split('.')[0].to_i
      if force_render || line_num != cursor_line
        @text.tag_add('hr', start_idx, end_idx); return
      else
        @text.tag_add('md_symbol', start_idx, end_idx)
      end
    end
    if m = line_text.match(/^(\>\s?)(.*)/)
      @text.tag_add('blockquote', start_idx, end_idx); @text.tag_add('md_symbol', "#{line_num}.0", "#{line_num}.#{m[1].length}")
    end
    line_text.scan(/(?<!\*)\*\*(?!\*)(.+?)(?<!\*)\*\*(?!\*)/) do
      m=Regexp.last_match; cs=m.begin(1); ce=m.end(1); ss=m.begin(0); @text.tag_add('bold', "#{line_num}.#{cs}", "#{line_num}.#{ce}"); @text.tag_add('md_symbol', "#{line_num}.#{ss}", "#{line_num}.#{ss+2}"); @text.tag_add('md_symbol', "#{line_num}.#{ce}", "#{line_num}.#{ce+2}")
    end
    line_text.scan(/(?<!\*)\*(?!\*)([^*]+?)\*(?!\*)/) do
      m=Regexp.last_match; cs=m.begin(1); ce=m.end(1); ss=m.begin(0); @text.tag_add('italic', "#{line_num}.#{cs}", "#{line_num}.#{ce}"); @text.tag_add('md_symbol', "#{line_num}.#{ss}", "#{line_num}.#{ss+1}"); @text.tag_add('md_symbol', "#{line_num}.#{ce}", "#{line_num}.#{ce+1}")
    end
    line_text.scan(/\*\*\*(.+?)\*\*\*/) do
      m=Regexp.last_match; cs=m.begin(1); ce=m.end(1); ss=m.begin(0); @text.tag_add('bold_italic', "#{line_num}.#{cs}", "#{line_num}.#{ce}"); @text.tag_add('md_symbol', "#{line_num}.#{ss}", "#{line_num}.#{ss+3}"); @text.tag_add('md_symbol', "#{line_num}.#{ce}", "#{line_num}.#{ce+3}")
    end
    line_text.scan(/`([^`]+)`/) do
      m=Regexp.last_match; cs=m.begin(1); ce=m.end(1); ss=m.begin(0); @text.tag_add('code', "#{line_num}.#{cs}", "#{line_num}.#{ce}"); @text.tag_add('md_symbol', "#{line_num}.#{ss}", "#{line_num}.#{ss+1}"); @text.tag_add('md_symbol', "#{line_num}.#{ce}", "#{line_num}.#{ce+1}")
    end
    line_text.scan(/~~(.+?)~~/) do
      m=Regexp.last_match; cs=m.begin(1); ce=m.end(1); ss=m.begin(0); @text.tag_add('strikethrough', "#{line_num}.#{cs}", "#{line_num}.#{ce}"); @text.tag_add('md_symbol', "#{line_num}.#{ss}", "#{line_num}.#{ss+2}"); @text.tag_add('md_symbol', "#{line_num}.#{ce}", "#{line_num}.#{ce+2}")
    end
  end

  def parse_current_line
    line_num = @text.index('insert').split('.')[0].to_i
    parse_line(line_num); parse_line(line_num - 1) if line_num > 1
  end

  def parse_entire_document
    total_lines = @text.index('end').split('.')[0].to_i - 1
    (1..total_lines).each { |line_num| parse_line(line_num, true) }
    rebuild_headers_cache
  end

  def rebuild_headers_cache
    @headers_cache = []; total_lines = @text.index('end').split('.')[0].to_i - 1
    (1..total_lines).each do |line_num|
      line_text = @text.get("#{line_num}.0", "#{line_num}.end")
      if m=line_text.match(/^(\#{1,6})\s+(.*)/)
        hash_count=m[1].length; content=m[2]||''; indent='    '*(hash_count-1); @headers_cache << {line: line_num, text: "#{indent}#{content.strip}"}
      end
    end
  end

  def get_headers; @headers_cache; end
  def get_current_header_line
    current_line=@text.index('insert').split('.')[0].to_i; current_header_line=nil
    @headers_cache.each { |h| if h[:line] <= current_line; current_header_line=h[:line]; else break; end }
    current_header_line
  end
  def get_current_header_text
    line=get_current_header_line; return nil unless line; @headers_cache.find { |h| h[:line]==line }&.dig(:text)
  end
end

# ==========================================
# 3. FIND & REPLACE DIALOG
# ==========================================
class FindReplaceDialog
  def initialize(root, editor)
    @editor=editor; @text=editor.text; @root=root; @callback_refs=[]
    @dialog=TkToplevel.new(@root) { title 'Find & Replace' }; @dialog.transient(@root); @dialog.geometry('450x200')
    @match_case=TkVariable.new(false); @use_regex=TkVariable.new(false); build_ui
    dialog_close_proc=proc { @dialog.destroy }; @callback_refs << dialog_close_proc; @dialog.protocol('WM_DELETE_WINDOW', dialog_close_proc); @dialog.grab_set; @dialog.focus; @find_entry.focus
  end
  def exist?; @dialog && @dialog.exist?; end
  def focus; @dialog.focus; end
  def build_ui
    me=self
    @find_label=Tk::Tile::Label.new(@dialog) { text 'Find:' }; @find_label.grid(row:0,column:0,padx:10,pady:10,sticky:'w')
    @find_entry=Tk::Tile::Entry.new(@dialog) { width:35 }; @find_entry.grid(row:0,column:1,padx:10,pady:10,columnspan:2,sticky:'ew')
    @replace_label=Tk::Tile::Label.new(@dialog) { text 'Replace:' }; @replace_label.grid(row:1,column:0,padx:10,pady:5,sticky:'w')
    @replace_entry=Tk::Tile::Entry.new(@dialog) { width:35 }; @replace_entry.grid(row:1,column:1,padx:10,pady:5,columnspan:2,sticky:'ew')
    @match_case_cb=Tk::Tile::CheckButton.new(@dialog) { text 'Match Case'; variable @match_case }; @match_case_cb.grid(row:2,column:1,padx:5,pady:5,sticky:'w')
    @use_regex_cb=Tk::Tile::CheckButton.new(@dialog) { text 'Regex'; variable @use_regex }; @use_regex_cb.grid(row:2,column:2,padx:5,pady:5,sticky:'w')
    @btn_frame=Tk::Tile::Frame.new(@dialog); @btn_frame.grid(row:3,column:0,columnspan:3,pady:15)
    find_backward_proc=proc { me.find(:backward) }; @callback_refs << find_backward_proc; @find_prev_btn=Tk::Tile::Button.new(@btn_frame) { text:'Find Prev'; command:find_backward_proc }; @find_prev_btn.pack(side:'left',padx:5)
    find_forward_proc=proc { me.find(:forward) }; @callback_refs << find_forward_proc; @find_next_btn=Tk::Tile::Button.new(@btn_frame) { text:'Find Next'; command:find_forward_proc }; @find_next_btn.pack(side:'left',padx:5)
    replace_current_proc=proc { me.replace_current }; @callback_refs << replace_current_proc; @replace_btn=Tk::Tile::Button.new(@btn_frame) { text:'Replace'; command:replace_current_proc }; @replace_btn.pack(side:'left',padx:5)
    replace_all_proc=proc { me.replace_all }; @callback_refs << replace_all_proc; @replace_all_btn=Tk::Tile::Button.new(@btn_frame) { text:'Replace All'; command:replace_all_proc }; @replace_all_btn.pack(side:'left',padx:5)
    @dialog.grid_columnconfigure(1,weight:1)
    find_entry_return_proc=proc { me.find(:forward) }; @callback_refs << find_entry_return_proc; @find_entry.bind('Return',find_entry_return_proc)
    dialog_escape_proc=proc { @dialog.destroy }; @callback_refs << dialog_escape_proc; @dialog.bind('Escape',dialog_escape_proc)
  end
  def document_text; @text.get('1.0','end - 1 char'); end
  def cursor_char_offset; n=@text.count('1.0','insert','chars'); n=n.first if n.is_a?(Array); (n||0).to_i; end
  def char_offset_to_index(char_offset); @text.index("1.0 + #{char_offset} chars"); end
  def build_pattern(pattern_text); flags=@match_case.value=='1' ? 0 : Regexp::IGNORECASE; @use_regex.value=='1' ? Regexp.new(pattern_text,flags) : Regexp.new(Regexp.escape(pattern_text),flags); end
  def find(direction)
    pattern_text=@find_entry.value; return if pattern_text.empty?
    begin regex=build_pattern(pattern_text); rescue RegexpError=>e; Tk.messageBox(type:'ok',icon:'error',title:'Invalid Pattern',message:e.message); return; end
    text=document_text; char_offset=cursor_char_offset; m=nil
    if direction==:forward; m=regex.match(text,char_offset+1); m ||= regex.match(text,0)
    else; last_before=nil; last_overall=nil; text.scan(regex) { cur=Regexp.last_match; last_overall=cur; last_before=cur if cur.begin(0)<char_offset }; m=last_before||last_overall; end
    if m; match_start=char_offset_to_index(m.begin(0)); match_end=char_offset_to_index(m.end(0)); @text.tag_remove('sel','1.0','end'); @text.tag_add('sel',match_start,match_end); @text.mark_set('insert',match_start); @text.see(match_start)
    else; Tk.messageBox(type:'ok',icon:'info',title:'Not Found',message:"Cannot find: \"#{pattern_text}\""); end
  end
  def replace_current
    if @text.tag_ranges('sel').any?; match_start=@text.index('sel.first'); match_end=@text.index('sel.last'); @text.edit_separator; @text.replace(match_start,match_end,@replace_entry.value); @text.edit_separator; @editor.highlighter.parse_entire_document; @editor.app.update_header_list; @text.mark_set('insert',match_start); find(:forward); else find(:forward); end
  end
  def replace_all
    pattern_text=@find_entry.value; replace_text=@replace_entry.value; return if pattern_text.empty?
    begin regex=build_pattern(pattern_text); rescue RegexpError=>e; Tk.messageBox(type:'ok',icon:'error',title:'Invalid Pattern',message:e.message); return; end
    text=document_text; replace_count=text.scan(regex).size; cursor_line=@text.index('insert').split('.')[0].to_i; first,_last=@text.yview; new_text=text.gsub(regex) { replace_text }
    @text.edit_separator; @text.replace('1.0','end - 1 char',new_text); @text.edit_separator
    total_lines=@text.index('end').split('.')[0].to_i-1; cursor_line=[cursor_line,total_lines].min; @text.mark_set('insert',"#{cursor_line}.0"); @text.yview_moveto(first)
    @editor.highlighter.parse_entire_document; @editor.app.update_header_list; Tk.messageBox(type:'ok',icon:'info',title:'Replace All',message:"Replaced #{replace_count} occurrences.")
  end
end

# ==========================================
# 4. EDITOR PANE
# ==========================================
class EditorPane
  attr_reader :text,:highlighter,:app,:debounce_timer
  PAIR_OPEN_TO_CLOSE={'*'=>'*','`'=>'`','['=>']','('=>')'}.freeze; SYMMETRIC_PAIR_CHARS=['*','`'].freeze; PAIR_CLOSER_CHARS=[']',')'].freeze
  def initialize(parent_frame,app)
    @app=app; @debounce_timer=nil; @auto_close_marks=[]; @auto_close_seq=0; @callback_refs=[]
    @text_frame=Tk::Tile::Frame.new(parent_frame); @text_frame.pack(fill:'both',expand:true,padx:15,pady:15); @scroll=Tk::Tile::Scrollbar.new(@text_frame)
    yscroll_proc=proc { |first,last| @scroll.set(first,last) }; @callback_refs << yscroll_proc
    @text=TkText.new(@text_frame) { width:80; height:24; wrap:'word'; font:Theme::FONTS[:editor]; borderwidth:0; highlightthickness:1; padx:Theme::SPACING[:editor_x]; pady:Theme::SPACING[:editor_y]; undo:true; autoseparators:false; yscrollcommand:yscroll_proc }
    @scroll.pack(side:'right',fill:'y'); @text.pack(side:'left',fill:'both',expand:true); yview_proc=proc { |*args| @text.yview(*args) }; @callback_refs << yview_proc; @scroll.command(yview_proc)
    @highlighter=MarkdownHighlighter.new(@text); setup_shortcuts
  end
  def cancel_timers; Tk.after_cancel(@debounce_timer) if @debounce_timer; end
  def setup_shortcuts
    ctrl_s=proc { @app.save_file; 'break' }; @callback_refs<<ctrl_s; @text.bind('Control-s',ctrl_s); ctrl_shift_s=proc { @app.save_as_file; 'break' }; @callback_refs<<ctrl_shift_s; @text.bind('Control-Shift-S',ctrl_shift_s); ctrl_o=proc { @app.open_file; 'break' }; @callback_refs<<ctrl_o; @text.bind('Control-o',ctrl_o); ctrl_n=proc { @app.new_file; 'break' }; @callback_refs<<ctrl_n; @text.bind('Control-n',ctrl_n); ctrl_q=proc { @app.quit_app; 'break' }; @callback_refs<<ctrl_q; @text.bind('Control-q',ctrl_q)
    ctrl_b=proc { insert_bold; 'break' }; @callback_refs<<ctrl_b; @text.bind('Control-b',ctrl_b); ctrl_i=proc { insert_italic; 'break' }; @callback_refs<<ctrl_i; @text.bind('Control-i',ctrl_i); ctrl_z=proc { @text.edit_undo rescue nil; 'break' }; @callback_refs<<ctrl_z; @text.bind('Control-z',ctrl_z); ctrl_y=proc { @text.edit_redo rescue nil; 'break' }; @callback_refs<<ctrl_y; @text.bind('Control-y',ctrl_y); ctrl_shift_z=proc { @text.edit_redo rescue nil; 'break' }; @callback_refs<<ctrl_shift_z; @text.bind('Control-Z',ctrl_shift_z)
    ctrl_a=proc { @text.tag_add('sel','1.0','end - 1 char'); 'break' }; @callback_refs<<ctrl_a; @text.bind('Control-a',ctrl_a); ctrl_plus=proc { @app.zoom_in; 'break' }; @callback_refs<<ctrl_plus; @text.bind('Control-plus',ctrl_plus); ctrl_equal=proc { @app.zoom_in; 'break' }; @callback_refs<<ctrl_equal; @text.bind('Control-equal',ctrl_equal); ctrl_minus=proc { @app.zoom_out; 'break' }; @callback_refs<<ctrl_minus; @text.bind('Control-minus',ctrl_minus); ctrl_0=proc { @app.reset_zoom; 'break' }; @callback_refs<<ctrl_0; @text.bind('Control-0',ctrl_0)
    ctrl_up=proc { move_line_up; 'break' }; @callback_refs<<ctrl_up; @text.bind('Control-Up',ctrl_up); ctrl_down=proc { move_line_down; 'break' }; @callback_refs<<ctrl_down; @text.bind('Control-Down',ctrl_down); ctrl_shift_d=proc { duplicate_line; 'break' }; @callback_refs<<ctrl_shift_d; @text.bind('Control-Shift-D',ctrl_shift_d); ctrl_g=proc { @app.goto_line_dialog; 'break' }; @callback_refs<<ctrl_g; @text.bind('Control-g',ctrl_g); ctrl_f=proc { @app.open_find_dialog; 'break' }; @callback_refs<<ctrl_f; @text.bind('Control-f',ctrl_f)
    btn_release_1=proc { @text.edit_separator; @app.update_current_header }; @callback_refs<<btn_release_1; @text.bind('ButtonRelease-1',btn_release_1); key_release_up=proc { @app.update_current_header }; @callback_refs<<key_release_up; @text.bind('KeyRelease-Up',key_release_up); key_release_down=proc { @app.update_current_header }; @callback_refs<<key_release_down; @text.bind('KeyRelease-Down',key_release_down); key_release_prior=proc { @app.update_current_header }; @callback_refs<<key_release_prior; @text.bind('KeyRelease-Prior',key_release_prior); key_release_next=proc { @app.update_current_header }; @callback_refs<<key_release_next; @text.bind('KeyRelease-Next',key_release_next)
    return_key=proc { handle_return }; @callback_refs<<return_key; @text.bind('Return',return_key)
    right_key=proc { next_two=@text.get('insert','insert + 2 chars'); next_one=next_two[0]||''; prev_char=@text.get('insert - 1 char','insert'); if next_two=='**'||next_two=='``'; @text.mark_set('insert','insert + 2 chars'); 'break'; elsif ['*','`'].include?(next_one); @text.mark_set('insert','insert + 1 char'); 'break'; elsif next_one==']'&&prev_char=='['; @text.mark_set('insert','insert + 1 char'); 'break'; elsif next_one==')'&&prev_char=='('; @text.mark_set('insert','insert + 1 char'); 'break'; else nil; end }; @callback_refs<<right_key; @text.bind('Right',right_key)
    left_key=proc { prev_two=@text.get('insert - 2 chars','insert'); prev_one=prev_two[-1]||''; next_char=@text.get('insert','insert + 1 char'); if prev_two=='**'||prev_two=='``'; @text.mark_set('insert','insert - 2 chars'); 'break'; elsif ['*','`'].include?(prev_one); @text.mark_set('insert','insert - 1 char'); 'break'; elsif prev_one=='['&&next_char==']'; @text.mark_set('insert','insert - 1 char'); 'break'; elsif prev_one=='('&&next_char==')'; @text.mark_set('insert','insert - 1 char'); 'break'; else nil; end }; @callback_refs<<left_key; @text.bind('Left',left_key)
    key_press=proc { |ev| unless ev.keysym.nil?||ev.keysym =~ /Shift|Control|Alt|Left|Right|Up|Down|Home|End|Prior|Next/; @text.edit_separator; end; char=ev.char; if @text.tag_ranges('sel').empty?; if PAIR_OPEN_TO_CLOSE.key?(char); closer=PAIR_OPEN_TO_CLOSE[char]; if SYMMETRIC_PAIR_CHARS.include?(char); after_proc=proc { @text.insert('insert',closer); @text.mark_set('insert','insert - 1 char') }; Tk.after(0,&after_proc); else; next_char=@text.get('insert','insert + 1 char'); if next_char==closer&&consume_auto_close_mark; @text.mark_set('insert','insert + 1 char'); next 'break'; else; after_proc=proc { @text.insert('insert',closer); @text.mark_set('insert','insert - 1 char'); register_auto_close_mark }; Tk.after(0,&after_proc); end; end; elsif PAIR_CLOSER_CHARS.include?(char); next_char=@text.get('insert','insert + 1 char'); if next_char==char&&consume_auto_close_mark; @text.mark_set('insert','insert + 1 char'); next 'break'; end; end; end; next if ev.keysym.nil?||ev.keysym =~ /Shift|Control|Alt|Left|Right|Up|Down|Home|End|Prior|Next/; @app.last_keypress_time=Time.now; @app.mark_modified }; @callback_refs<<key_press; @text.bind('KeyPress',key_press)
    key_release=proc { |_ev| Tk.after_cancel(@debounce_timer) if @debounce_timer; debounce_proc=proc { parse_and_update }; @debounce_timer=Tk.after(300,&debounce_proc) }; @callback_refs<<key_release; @text.bind('KeyRelease',key_release)
    ctrl_v=proc { paste_proc=proc { parse_after_paste }; Tk.after(100,&paste_proc) }; @callback_refs<<ctrl_v; @text.bind('Control-v',ctrl_v)
  end
  def register_auto_close_mark; name="autoclose_#{@auto_close_seq+=1}"; @text.mark_set(name,'insert'); @text.mark_gravity(name,'left'); @auto_close_marks<<name; while @auto_close_marks.size>10; old=@auto_close_marks.shift; @text.mark_unset(old) if @text.mark_names.include?(old); end; end
  def consume_auto_close_mark; return false if @auto_close_marks.empty?; cursor=@text.index('insert'); match=@auto_close_marks.find { |m| @text.mark_names.include?(m)&&@text.index(m)==cursor }; return false unless match; @auto_close_marks.delete(match); @text.mark_unset(match); true; end
  def reset_auto_close_tracking; @auto_close_marks.each { |m| @text.mark_unset(m) if @text.mark_names.include?(m) }; @auto_close_marks.clear; end
  def insert_bold; @text.edit_separator; if @text.tag_ranges('sel').any?; @text.mark_set('temp_sel_end','sel.last'); @text.insert('sel.last','**'); @text.insert('sel.first','**'); @text.tag_remove('sel','1.0','end'); @text.mark_set('insert','temp_sel_end + 2 chars'); @text.mark_unset('temp_sel_end'); else; @text.insert('insert','****'); @text.mark_set('insert','insert - 2 chars'); end; @app.mark_modified; @text.edit_separator; 'break'; end
  def insert_italic; @text.edit_separator; if @text.tag_ranges('sel').any?; @text.mark_set('temp_sel_end','sel.last'); @text.insert('sel.last','*'); @text.insert('sel.first','*'); @text.tag_remove('sel','1.0','end'); @text.mark_set('insert','temp_sel_end + 1 char'); @text.mark_unset('temp_sel_end'); else; @text.insert('insert','**'); @text.mark_set('insert','insert - 1 char'); end; @app.mark_modified; @text.edit_separator; 'break'; end
  def handle_return
    current_line=@text.index('insert').split('.')[0].to_i; line_text=@text.get("#{current_line}.0","#{current_line}.end"); cursor_col=@text.index('insert').split('.')[1].to_i; before=line_text[0,cursor_col]; after=line_text[cursor_col..-1]||''
    if before.match(/\A\*{3,}\z/)&&after.match(/\A\*+\z/); @text.edit_separator; @text.delete('insert',"#{current_line}.end"); @app.mark_modified; @app.last_keypress_time=Time.now; hr_render=proc { @highlighter.parse_line(current_line,true) }; Tk.after(0,&hr_render); return; end
    if line_text.match(/^(\s*)([-*+])\s+/); indent=$1; bullet=$2; if line_text.strip==bullet; @text.edit_separator; @text.delete("#{current_line}.0","#{current_line}.end"); @text.edit_separator; return 'break'; end; return_proc=proc { @text.insert('insert',"#{indent}#{bullet} "); @text.edit_separator }; Tk.after(0,&return_proc); return; end
    if line_text.match(/^(\s*)(\d+)\.\s+/); indent=$1; num=$2.to_i; if line_text.strip=="#{num}."; @text.edit_separator; @text.delete("#{current_line}.0","#{current_line}.end"); @text.edit_separator; return 'break'; end; return_proc=proc { @text.insert('insert',"#{indent}#{num+1}. "); @text.edit_separator }; Tk.after(0,&return_proc); return; end
  end
  def parse_after_paste; @highlighter.parse_entire_document; @app.update_header_list; @app.update_status_left; end
  def parse_and_update; @highlighter.parse_current_line; @highlighter.rebuild_headers_cache; @app.update_current_header; @app.update_status_left; end
  def move_line_up
    current_line,current_col=@text.index('insert').split('.').map(&:to_i); return if current_line<=1; has_selection=@text.tag_ranges('sel').any?; if has_selection; sel_start=@text.index('sel.first'); sel_end=@text.index('sel.last'); start_line=sel_start.split('.')[0].to_i; end_line=sel_end.split('.')[0].to_i; end_line-=1 if sel_end.split('.')[1].to_i==0&&end_line>start_line; else start_line=end_line=current_line; end; block_text=@text.get("#{start_line}.0","#{end_line}.end"); prev_text=@text.get("#{start_line-1}.0","#{start_line-1}.end"); @text.edit_separator; @text.replace("#{start_line-1}.0","#{end_line}.end","#{block_text}\n#{prev_text}"); if has_selection; @text.tag_add('sel',"#{start_line-1}.0","#{start_line-1}.0 + #{block_text.length} chars"); end; @text.mark_set('insert',"#{current_line-1}.#{current_col}"); @text.see('insert'); @text.edit_separator; (start_line-1).upto(end_line).each { |l| @highlighter.parse_line(l) }; end
  def move_line_down
    current_line,current_col=@text.index('insert').split('.').map(&:to_i); total_lines=@text.index('end').split('.')[0].to_i-1; return if current_line>=total_lines; has_selection=@text.tag_ranges('sel').any?; if has_selection; sel_start=@text.index('sel.first'); sel_end=@text.index('sel.last'); start_line=sel_start.split('.')[0].to_i; end_line=sel_end.split('.')[0].to_i; end_line-=1 if sel_end.split('.')[1].to_i==0&&end_line>start_line; else start_line=end_line=current_line; end; return if end_line>=total_lines; block_text=@text.get("#{start_line}.0","#{end_line}.end"); next_text=@text.get("#{end_line+1}.0","#{end_line+1}.end"); @text.edit_separator; @text.replace("#{start_line}.0","#{end_line+1}.end","#{next_text}\n#{block_text}"); if has_selection; @text.tag_add('sel',"#{start_line+1}.0","#{start_line+1}.0 + #{block_text.length} chars"); end; @text.mark_set('insert',"#{current_line+1}.#{current_col}"); @text.see('insert'); @text.edit_separator; start_line.upto(end_line+1).each { |l| @highlighter.parse_line(l) }; end
  def duplicate_line; current_line=@text.index('insert').split('.')[0].to_i; line_text=@text.get("#{current_line}.0","#{current_line}.end"); @text.edit_separator; @text.insert("#{current_line}.end","\n#{line_text}"); @text.mark_set('insert',"#{current_line+1}.0"); @text.see('insert'); @text.edit_separator; @highlighter.parse_line(current_line+1); end
end

# ==========================================
# 5. MAIN APPLICATION
# ==========================================
class MarkdownEditor
  attr_accessor :is_modified,:notebook,:tab_frame,:status_left,:root,:current_theme,:last_keypress_time
  def initialize
    @root=TkRoot.new { title 'RubykNotte v0.4.0' }; Tk::Tile::Style.theme_use('clam'); @callback_refs=[]; disable_tk_emacs_bindings; @root.minsize(800,600); @root.geometry('900x700'); @root.pack_propagate(false)
    @is_modified=false; @current_filename='Untitled.md'; @current_filepath=nil
    @settings=RubykNotte::Settings.new
    @current_theme=@settings.get(:theme); @base_font_size=@settings.get(:font_size); @line_spacing=@settings.get(:line_spacing); @text_padding_x=@settings.get(:text_padding_x); @text_padding_y=@settings.get(:text_padding_y)
    @last_keypress_time=Time.now; @backup_due_time=nil; @backup_dir=File.join(Dir.home,'.markdown_editor_backups'); @backup_file=File.join(@backup_dir,'recovery.md'); Dir.mkdir(@backup_dir) unless Dir.exist?(@backup_dir); rotate_backups
    quit_app_proc=proc { quit_app }; @callback_refs<<quit_app_proc; @root.protocol('WM_DELETE_WINDOW',quit_app_proc); @find_dialog=nil; @goto_dialog=nil; @header_popup=nil; @header_popup_scroll=nil
    @popup_close_proc=proc { |ev| return unless @header_popup&&@header_popup.exist?; rx=@header_popup.winfo_rootx; ry=@header_popup.winfo_rooty; rw=@header_popup.winfo_width; rh=@header_popup.winfo_height; x=ev.x_root; y=ev.y_root; close_header_popup if x<rx||x>rx+rw||y<ry||y>ry+rh }; @callback_refs<<@popup_close_proc; @root.bind('ButtonPress-1',@popup_close_proc)
    setup_ui; apply_theme; apply_font_settings; update_current_header; schedule_next_backup_check(10000)
  end
  def save_settings; @settings.set(:theme,@current_theme); @settings.set(:font_size,@base_font_size); @settings.set(:line_spacing,@line_spacing); @settings.set(:text_padding_x,@text_padding_x); @settings.set(:text_padding_y,@text_padding_y); @settings.save; end
  def schedule_next_backup_check(ms); Tk.after_cancel(@backup_check_timer) if @backup_check_timer; @backup_check_proc=proc { check_backup }; @backup_check_timer=Tk.after(ms,&@backup_check_proc); end
  def check_backup; if @is_modified; time_since_type=Time.now-(@last_keypress_time||Time.now); if time_since_type>2; perform_background_backup; @backup_due_time=nil; schedule_next_backup_check(10000); else @backup_due_time||=Time.now; if Time.now-@backup_due_time>=5; perform_background_backup; @backup_due_time=nil; schedule_next_backup_check(10000); else schedule_next_backup_check(1000); end; end; else @backup_due_time=nil; schedule_next_backup_check(10000); end; end
  def perform_background_backup; return unless @is_modified; begin content=@editor.text.get('1.0','end - 1 char'); write_backup_atomic(content); rescue=>e; puts "Background backup failed: #{e.message}"; end; end
  def write_backup_atomic(content); tmp_file="#{@backup_file}.tmp"; File.write(tmp_file,content,encoding:'UTF-8'); FileUtils.mv(tmp_file,@backup_file,force:true); end
  def disable_tk_emacs_bindings; @emacs_kill_proc=proc { 'break' }; @callback_refs<<@emacs_kill_proc; ['Control-b','Control-i','Control-k','Control-f','Control-g','Control-s','Control-o','Control-n','Control-q'].each { |key| Tk.bind('Text',key,@emacs_kill_proc) }; end
  def mark_modified; if !@is_modified; @is_modified=true; current_text=@notebook.itemcget(@tab_frame,'text'); @notebook.itemconfigure(@tab_frame,text:"* #{current_text}") unless current_text.start_with?('*'); end; end

  def setup_ui
    me=self; @menubar=Tk::Tile::Frame.new(@root); @menubar.style='Toolbar.TFrame'; @menubar.pack(fill:'x'); @file_menu=TkMenu.new(@root,tearoff:0,font:Theme::FONTS[:ui])
    new_file_proc=proc { new_file }; @callback_refs<<new_file_proc; @file_menu.add('command',label:'New',accel:'Ctrl+N',command:new_file_proc); open_file_proc=proc { open_file }; @callback_refs<<open_file_proc; @file_menu.add('command',label:'Open...',accel:'Ctrl+O',command:open_file_proc); save_file_proc=proc { save_file }; @callback_refs<<save_file_proc; @file_menu.add('command',label:'Save',accel:'Ctrl+S',command:save_file_proc); save_as_file_proc=proc { save_as_file }; @callback_refs<<save_as_file_proc; @file_menu.add('command',label:'Save As...',accel:'Ctrl+Shift+S',command:save_as_file_proc); @file_menu.add('separator'); open_recovery_file_proc=proc { open_recovery_file }; @callback_refs<<open_recovery_file_proc; @file_menu.add('command',label:'Open Recovery Backup...',command:open_recovery_file_proc); @file_menu.add('separator'); quit_app_proc_menu=proc { quit_app }; @callback_refs<<quit_app_proc_menu; @file_menu.add('command',label:'Quit',accel:'Ctrl+Q',command:quit_app_proc_menu)
    file_btn_cmd=proc { x=@file_btn.winfo_rootx; y=@file_btn.winfo_rooty+@file_btn.winfo_height; @file_menu.popup(x,y) }; @callback_refs<<file_btn_cmd; @file_btn=Tk::Tile::Button.new(@menubar) { style:'Menubar.TButton'; text:'File'; command:file_btn_cmd }; @file_btn.pack(side:'left',padx:Theme::SPACING[:xs],pady:2)
    @edit_menu=TkMenu.new(@root,tearoff:0,font:Theme::FONTS[:ui]); open_find_dialog_proc=proc { open_find_dialog }; @callback_refs<<open_find_dialog_proc; @edit_menu.add('command',label:'Find / Replace...',accel:'Ctrl+F',command:open_find_dialog_proc); edit_btn_cmd=proc { x=@edit_btn.winfo_rootx; y=@edit_btn.winfo_rooty+@edit_btn.winfo_height; @edit_menu.popup(x,y) }; @callback_refs<<edit_btn_cmd; @edit_btn=Tk::Tile::Button.new(@menubar) { style:'Menubar.TButton'; text:'Edit'; command:edit_btn_cmd }; @edit_btn.pack(side:'left',padx:Theme::SPACING[:xs],pady:2)
    @view_menu=TkMenu.new(@root,tearoff:0,font:Theme::FONTS[:ui]); zoom_in_proc=proc { zoom_in }; @callback_refs<<zoom_in_proc; @view_menu.add('command',label:'Zoom In',accel:'Ctrl++',command:zoom_in_proc); zoom_out_proc=proc { zoom_out }; @callback_refs<<zoom_out_proc; @view_menu.add('command',label:'Zoom Out',accel:'Ctrl+-',command:zoom_out_proc); reset_zoom_proc=proc { reset_zoom }; @callback_refs<<reset_zoom_proc; @view_menu.add('command',label:'Reset Zoom',accel:'Ctrl+0',command:reset_zoom_proc); @view_menu.add('separator'); inc_spacing_proc=proc { change_spacing(2) }; @callback_refs<<inc_spacing_proc; @view_menu.add('command',label:'Increase Line Spacing',command:inc_spacing_proc); dec_spacing_proc=proc { change_spacing(-2) }; @callback_refs<<dec_spacing_proc; @view_menu.add('command',label:'Decrease Line Spacing',command:dec_spacing_proc); @view_menu.add('separator'); inc_padding_proc=proc { change_text_padding(2) }; @callback_refs<<inc_padding_proc; @view_menu.add('command',label:'Increase Text Padding',command:inc_padding_proc); dec_padding_proc=proc { change_text_padding(-2) }; @callback_refs<<dec_padding_proc; @view_menu.add('command',label:'Decrease Text Padding',command:dec_padding_proc); @view_menu.add('separator'); goto_line_dialog_proc=proc { goto_line_dialog }; @callback_refs<<goto_line_dialog_proc; @view_menu.add('command',label:'Go to Line...',accel:'Ctrl+G',command:goto_line_dialog_proc); view_btn_cmd=proc { x=@view_btn.winfo_rootx; y=@view_btn.winfo_rooty+@view_btn.winfo_height; @view_menu.popup(x,y) }; @callback_refs<<view_btn_cmd; @view_btn=Tk::Tile::Button.new(@menubar) { style:'Menubar.TButton'; text:'View'; command:view_btn_cmd }; @view_btn.pack(side:'left',padx:Theme::SPACING[:xs],pady:2)
    @theme_menu=TkMenu.new(@root,tearoff:0,font:Theme::FONTS[:ui]); sepia_theme_proc=proc { @current_theme=:sepia; apply_theme }; @callback_refs<<sepia_theme_proc; @theme_menu.add('command',label:'Sepia',command:sepia_theme_proc); dark_theme_proc=proc { @current_theme=:dark; apply_theme }; @callback_refs<<dark_theme_proc; @theme_menu.add('command',label:'Dark',command:dark_theme_proc); theme_btn_cmd=proc { x=@theme_btn.winfo_rootx; y=@theme_btn.winfo_rooty+@theme_btn.winfo_height; @theme_menu.popup(x,y) }; @callback_refs<<theme_btn_cmd; @theme_btn=Tk::Tile::Button.new(@menubar) { style:'Menubar.TButton'; text:'Theme'; command:theme_btn_cmd }; @theme_btn.pack(side:'left',padx:Theme::SPACING[:xs],pady:2)
    header_btn_cmd=proc { me.show_header_popup }; @callback_refs<<header_btn_cmd; @header_btn=Tk::Tile::Button.new(@menubar) { style:'Menubar.TButton'; text:'Headings'; command:header_btn_cmd }; @header_btn.pack(side:'right',padx:Theme::SPACING[:sm],pady:2)
    @toolbar=Tk::Tile::Frame.new(@root); @toolbar.style='Toolbar.TFrame'; @toolbar.pack(fill:'x'); readonly_btn_cmd=proc { me.toggle_readonly }; @callback_refs<<readonly_btn_cmd; @readonly_btn=Tk::Tile::Button.new(@toolbar) { text:'Read-Only'; style:'Toolbar.TButton'; command:readonly_btn_cmd }; @readonly_btn.pack(side:'right',padx:Theme::SPACING[:sm],pady:2)
    bold_btn_cmd=proc { me.insert_bold }; @callback_refs<<bold_btn_cmd; @bold_btn=Tk::Tile::Button.new(@toolbar) { text:'B'; style:'Toolbar.TButton'; command:bold_btn_cmd }; @bold_btn.pack(side:'left',padx:1,pady:2); italic_btn_cmd=proc { me.insert_italic }; @callback_refs<<italic_btn_cmd; @italic_btn=Tk::Tile::Button.new(@toolbar) { text:'I'; style:'Toolbar.TButton'; command:italic_btn_cmd }; @italic_btn.pack(side:'left',padx:1,pady:2)
    (1..6).each do |i|; proc_cmd=proc { send("insert_h#{i}") }; @callback_refs<<proc_cmd; instance_variable_set("@h#{i}_btn",Tk::Tile::Button.new(@toolbar) { text:"H#{i}"; style:'Toolbar.TButton'; command:proc_cmd }); instance_variable_get("@h#{i}_btn").pack(side:'left',padx:1,pady:2); end
    @notebook=Tk::Tile::Notebook.new(@root); @notebook.pack(fill:'both',expand:true); @tab_frame=Tk::Tile::Frame.new(@notebook); @notebook.add(@tab_frame,text:@current_filename); @editor=EditorPane.new(@tab_frame,self)
    @status_frame=Tk::Tile::Frame.new(@root); @status_frame.style='Status.TFrame'; @status_frame.pack(fill:'x'); @status_left=Tk::Tile::Label.new(@status_frame) { text:'Words: 0 | Chars: 0 | Read: 0 min' }; @status_left.pack(side:'left',padx:Theme::SPACING[:sm],pady:2); @status_right=Tk::Tile::Label.new(@status_frame) { text:'Edit' }; @status_right.pack(side:'right',padx:Theme::SPACING[:sm],pady:2)
  end

  def apply_theme
    colors=Theme::THEMES[@current_theme]||Theme::THEMES[:sepia]; @root.configure(background:colors[:window_bg]); @menubar.configure(background:colors[:toolbar_bg]); @toolbar.configure(background:colors[:toolbar_bg]); @status_frame.configure(background:colors[:status_bg]); @editor.text.configure(background:colors[:editor_bg],foreground:colors[:text_fg],insertbackground:colors[:text_fg],selectbackground:colors[:selection],selectforeground:colors[:text_fg]); @editor.highlighter.apply_theme(colors); @settings.set(:theme,@current_theme); save_settings
  end
  def apply_font_settings; @editor.text.configure(font:[Theme::FONTS[:editor][0],@base_font_size]); @editor.highlighter.apply_font_settings(@base_font_size); @editor.text.configure(spacing1:@line_spacing,spacing3:@line_spacing,padx:@text_padding_x,pady:@text_padding_y); save_settings; end
  def zoom_in; @base_font_size=[@base_font_size+1,72].min; apply_font_settings; end
  def zoom_out; @base_font_size=[@base_font_size-1,8].max; apply_font_settings; end
  def reset_zoom; @base_font_size=12; apply_font_settings; end
  def change_spacing(delta); @line_spacing=[[ @line_spacing+delta,0].max,40].min; apply_font_settings; end
  def change_text_padding(delta); @text_padding_x=[[ @text_padding_x+delta,0].max,100].min; @text_padding_y=[[ @text_padding_y+delta,0].max,100].min; apply_font_settings; end
  def quit_app; if @is_modified; answer=Tk.messageBox(type:'yesnocancel',icon:'question',title:'Unsaved Changes',message:'Save changes before quitting?'); return if answer=='cancel'; save_file if answer=='yes'; end; save_settings; @editor.cancel_timers; Tk.exit; end
