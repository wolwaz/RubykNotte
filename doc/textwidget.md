# Text Widget (TkText) Reference

The TkText widget is the core editing surface, instantiated within `EditorPane`. It handles text display, scrolling, undo/redo, and Markdown tag rendering.

## Creation

Initialized inside `EditorPane#initialize`:

```ruby
@text = TkText.new(@text_frame) {
  width 80
  height 24
  wrap 'word'
  font Theme::FONTS[:editor]
  borderwidth 0
  highlightthickness 1
  padx Theme::SPACING[:editor_x]   # 25, later @text_padding_x
  pady Theme::SPACING[:editor_y]   # 20, later @text_padding_y
  undo true
  autoseparators false
  yscrollcommand proc { |first, last| scroll.set(first, last) }
}
```

`autoseparators false` is set so undo granularity is controlled with explicit `edit_separator` calls during formatting and text manipulation.

## Runtime configuration

### Theming (`apply_theme`)

When a theme is applied, the widget's colors are updated to match the active `Theme::THEMES` palette:

- `background` → `editor_bg`
- `foreground` → `text_fg`
- `insertbackground` → `text_fg` (cursor color)
- `selectbackground` → `selection`
- `selectforeground` → `text_fg`
- `highlightbackground` / `highlightcolor` → `border`

Highlighter tags are reconfigured in place (no full re-parse required for color changes).

### Font, spacing, and padding (`apply_font_settings`)

Zoom, spacing, and padding reconfigure the widget:

- `font` → `[Noto Sans, @base_font_size]`
- `spacing1`, `spacing2`, `spacing3` → `@line_spacing`
- `padx` → `@text_padding_x` (min 2)
- `pady` → `@text_padding_y` (min 2)

### State toggling (`toggle_readonly`)

The widget's state is toggled between `'normal'` and `'disabled'`. Opening a file, creating a new file, or loading recovery forces `'normal'`.

## Tag stack

`MarkdownHighlighter` applies `h1`–`h6`, `bold`, `italic`, `bold_italic`, `code`, `strikethrough`, `blockquote`, `hr`, and `md_symbol`. `md_symbol` is raised last so `#`, `*`, `` ` ``, and `~~` stay muted over the content tags.
