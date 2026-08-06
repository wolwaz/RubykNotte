Text Widget (TkText) Reference
Creation

@text = TkText.new(@text_frame) {  width 80  height 24  wrap 'word'  font Theme::FONTS[:editor]  borderwidth 0  highlightthickness 1  padx Theme::SPACING[:editor_x]   # 25  pady Theme::SPACING[:editor_y]   # 20  undo true  autoseparators false  yscrollcommand proc { |first, last| scroll.set(first, last) }}

Text Widget (TkText) Reference

The TkText widget is the core editing surface, instantiated within EditorPane. It handles text display, scrolling, undo/redo, and Markdown tag rendering.
Creation

Initialized inside EditorPane#initialize. Note that autoseparators false is set so that undo granularity can be manually controlled via explicit edit_separator calls during formatting and text manipulation.

Runtime Configurations
Theming (apply_theme)

When a theme is applied, the widget's colors are updated to match the active Theme::THEMES palette:
 background → editor_bg
 foreground → text_fg
 insertbackground → text_fg (cursor color)
 selectbackground → selection
 selectforeground → text_fg
 highlightbackground / highlightcolor → border

Font & Spacing (apply_font_settings)

Zooming and spacing changes dynamically reconfigure the widget:
 font → [Noto Sans, @base_font_size]
 spacing1, spacing2, spacing3 → @line_spacing (controls line height padding)

State Toggling (toggle_readonly)

The widget's state is toggled between 'normal' and 'disabled' to enforce read-only mode. When opening a file or creating a new file, the state is explicitly forced back to 'normal'.
Tag Stack

The MarkdownHighlighter applies tags (h1–h6, bold, italic, md_symbol) to the text. md_symbol is explicitly raised to the top of the tag stack via tag_raise so that symbol characters (like ** or #) visually override the bold/italic font weights.
