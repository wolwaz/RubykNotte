
# Text Widget (`TkText`) Reference

## Creation

```ruby
@text = TkText.new(@text_frame) {
  width 80
  height 24
  wrap 'word'
  font Theme::FONTS[:editor]
  borderwidth 0
  highlightthickness 1
  padx Theme::SPACING[:editor_x]   # 25
  pady Theme::SPACING[:editor_y]   # 20
  undo true
  yscrollcommand proc { |first, last| scroll.set(first, last) }
}