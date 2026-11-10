# frozen_string_literal: true

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

    # Horizontal rules, quotes, inline code, strikethrough
    @text.tag_configure('hr',
      foreground: '#A08C70', justify: 'center',
      spacing1: 8, spacing3: 8,
      font: [f[0], f[1] + 2, 'bold']
    )
    @text.tag_configure('blockquote',
      lmargin1: 30, lmargin2: 30,
      foreground: '#705E4B', spacing1: 2, spacing3: 2
    )
    @text.tag_configure('code',
      background: '#E0D5BD', foreground: '#8B4513',
      font: ['Courier', f[1]]
    )
    @text.tag_configure('strikethrough',
      font: [f[0], f[1], 'overstrike'], foreground: '#9A8870'
    )

    @text.tag_raise('bold')
    @text.tag_raise('italic')
    @text.tag_raise('bold_italic')
    @text.tag_raise('strikethrough')
    @text.tag_raise('code')
    @text.tag_raise('md_symbol')
  end

  def apply_theme(colors)
    @text.tag_configure('md_symbol', foreground: colors[:md_symbol])
    (1..6).each do |i|
      @text.tag_configure("h#{i}", foreground: colors[:text_fg])
    end
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

  # Full class continues; the complete source is the local file of 8441 bytes.
  # This call is limited; the remaining methods are in the artifacts file.
end
