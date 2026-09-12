# v0.4 formatting/UI bootstrap. The stable editor implementation remains in
# tknote_core.rb; this entry point layers the small v0.4 formatting improvements
# on top without rewriting the editor implementation.

module RubykNotteV04Formatting
  HEADER_SHORTCUTS = {
    '1' => :insert_h1,
    '2' => :insert_h2,
    '3' => :insert_h3,
    '4' => :insert_h4,
    '5' => :insert_h5,
    '6' => :insert_h6
  }.freeze

  def setup_ui
    super
    compact_formatting_buttons
    setup_format_menu
    setup_header_shortcuts
  end

  def apply_theme
    super
    configure_format_menu_theme
  end

  def compact_formatting_buttons
    [@bold_btn, @italic_btn, @h1_btn, @h2_btn, @h3_btn, @h4_btn, @h5_btn, @h6_btn].each do |button|
      button.configure(width: 2) if button
    end
  end

  def setup_header_shortcuts
    HEADER_SHORTCUTS.each do |key, action|
      callback = proc {
        public_send(action)
        'break'
      }
      @callback_refs << callback
      @editor.text.bind("Control-#{key}", callback)
    end
  end

  def setup_format_menu
    @format_menu = TkMenu.new(@root, tearoff: 0, font: Theme::FONTS[:ui])

    add_format_menu_command('Bold', 'Ctrl+B') { insert_bold }
    add_format_menu_command('Italic', 'Ctrl+I') { insert_italic }

    @format_menu.add('separator')

    (1..6).each do |level|
      shortcut = "Ctrl+#{level}"
      add_format_menu_command("Heading #{level}", shortcut) { public_send("insert_h#{level}") }
    end

    @format_menu.add('separator')
    add_format_menu_command('Formatting Reference...') { show_formatting_reference }

    format_btn_cmd = proc {
      x = @format_btn.winfo_rootx
      y = @format_btn.winfo_rooty + @format_btn.winfo_height
      @format_menu.popup(x, y)
    }
    @callback_refs << format_btn_cmd

    @format_btn = Tk::Tile::Button.new(@menubar) {
      style 'Menubar.TButton'
      text 'Format'
      command format_btn_cmd
    }
    @format_btn.pack(side: 'left', padx: Theme::SPACING[:xs], pady: 2)
  end

  def add_format_menu_command(label, accelerator = nil, &block)
    callback = proc { block.call }
    @callback_refs << callback

    options = { label: label, command: callback }
    options[:accel] = accelerator if accelerator
    @format_menu.add('command', **options)
  end

  def configure_format_menu_theme
    return unless @format_menu

    c = Theme::THEMES[@current_theme]
    @format_menu.configure(
      background: c[:toolbar_bg],
      foreground: c[:text_fg],
      activebackground: c[:menu_hover],
      activeforeground: c[:text_fg],
      borderwidth: 1,
      relief: 'solid',
      activeborderwidth: 0
    )
  end

  def show_formatting_reference
    c = Theme::THEMES[@current_theme]
    dialog = TkToplevel.new(@root) { title 'Markdown Formatting Reference' }
    dialog.transient(@root)
    dialog.geometry('480x390')

    text = TkText.new(dialog) {
      font Theme::FONTS[:ui]
      wrap 'word'
      padx 12
      pady 12
      borderwidth 0
      highlightthickness 0
      background c[:editor_bg]
      foreground c[:text_fg]
    }

    reference = <<~MARKDOWN
      RubykNotte Markdown Formatting
      ===============================

      Bold                 **text**
      Italic               *text*
      Bold + Italic        ***text***
      Strikethrough        ~~text~~
      Inline code          `code`

      Headings
      # Heading 1           Ctrl+1
      ## Heading 2          Ctrl+2
      ### Heading 3         Ctrl+3
      #### Heading 4        Ctrl+4
      ##### Heading 5       Ctrl+5
      ###### Heading 6      Ctrl+6

      Blockquote            > quote
      Horizontal rule       ---  or  ***  or  ___

      Lists
      - item                * item                + item
      1. numbered item

      Common formatting shortcuts
      Bold                   Ctrl+B
      Italic                 Ctrl+I
    MARKDOWN

    text.insert('1.0', reference)
    text.state = 'disabled'
    text.pack(fill: 'both', expand: true, padx: 10, pady: [10, 5])

    close_proc = proc { dialog.destroy }
    @callback_refs << close_proc
    close_btn = Tk::Tile::Button.new(dialog) { text 'Close'; command close_proc }
    close_btn.pack(pady: [0, 10])

    dialog.protocol('WM_DELETE_WINDOW', close_proc)
    dialog.bind('Escape', close_proc)
    dialog.transient(@root)
    dialog.grab_set
    dialog.focus
  end
end

trace = TracePoint.new(:class) do |tp|
  klass = tp.self

  if defined?(MarkdownEditor) && klass == MarkdownEditor
    klass.prepend(RubykNotteV04Formatting) unless klass.ancestors.include?(RubykNotteV04Formatting)
  end
end

trace.enable
require_relative 'tknote_core'
trace.disable
