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

  def parse_line(line_num, force_render = false)
    start_idx = "#{line_num}.0"
    end_idx = "#{line_num}.end"
    line_text = @text.get(start_idx, end_idx)

    ['h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'bold', 'italic', 'bold_italic', 'md_symbol', 'hr', 'blockquote', 'code', 'strikethrough'].each do |tag|
      @text.tag_remove(tag, start_idx, end_idx)
    end

    # Headers
    if m = line_text.match(/^(\#{1,6})\s+(.*)/)
      hash_count = m[1].length
      tag = "h#{hash_count}"
      @text.tag_add(tag, start_idx, end_idx)
      @text.tag_add('md_symbol', "#{line_num}.0", "#{line_num}.#{hash_count}")
    end

    # Horizontal Rule
    if line_text.match(/^\s*(-{3,}|\*{3,}|_{3,})\s*$/)
      cursor_line = @text.index('insert').split('.')[0].to_i
      # Only render the thick separator bar if the cursor is NOT on this line,
      # or if we are forcefully parsing the whole document (e.g., opening a file).
      if force_render || line_num != cursor_line
        @text.tag_add('hr', start_idx, end_idx)
        return
      else
        # While typing, just color the symbols so it doesn't obstruct typing
        @text.tag_add('md_symbol', start_idx, end_idx)
      end
    end

    # Blockquote
    if m = line_text.match(/^(\>\s?)(.*)/)
      @text.tag_add('blockquote', start_idx, end_idx)
      @text.tag_add('md_symbol', "#{line_num}.0", "#{line_num}.#{m[1].length}")
    end

    # Bold
    line_text.scan(/(?<!\*)\*\*(?!\*)(.+?)(?<!\*)\*\*(?!\*)/) do
      m = Regexp.last_match
      content_start = m.begin(1)
      content_end   = m.end(1)
      symbol_start  = m.begin(0)

      @text.tag_add('bold', "#{line_num}.#{content_start}", "#{line_num}.#{content_end}")
      @text.tag_add('md_symbol', "#{line_num}.#{symbol_start}", "#{line_num}.#{symbol_start + 2}")
      @text.tag_add('md_symbol', "#{line_num}.#{content_end}", "#{line_num}.#{content_end + 2}")
    end

    # Italic
    line_text.scan(/(?<!\*)\*(?!\*)([^*]+?)\*(?!\*)/) do
      m = Regexp.last_match
      content_start = m.begin(1)
      content_end   = m.end(1)
      symbol_start  = m.begin(0)

      @text.tag_add('italic', "#{line_num}.#{content_start}", "#{line_num}.#{content_end}")
      @text.tag_add('md_symbol', "#{line_num}.#{symbol_start}", "#{line_num}.#{symbol_start + 1}")
      @text.tag_add('md_symbol', "#{line_num}.#{content_end}", "#{line_num}.#{content_end + 1}")
    end
    
    # Bold + Italic (***text***)
    line_text.scan(/\*\*\*(.+?)\*\*\*/) do
      m = Regexp.last_match
      content_start = m.begin(1)
      content_end   = m.end(1)
      symbol_start  = m.begin(0)

      @text.tag_add('bold_italic', "#{line_num}.#{content_start}", "#{line_num}.#{content_end}")
      @text.tag_add('md_symbol', "#{line_num}.#{symbol_start}", "#{line_num}.#{symbol_start + 3}")
      @text.tag_add('md_symbol', "#{line_num}.#{content_end}", "#{line_num}.#{content_end + 3}")
    end
    
    # Inline Code
    line_text.scan(/`([^`]+)`/) do
      m = Regexp.last_match
      content_start = m.begin(1)
      content_end   = m.end(1)
      symbol_start  = m.begin(0)

      @text.tag_add('code', "#{line_num}.#{content_start}", "#{line_num}.#{content_end}")
      @text.tag_add('md_symbol', "#{line_num}.#{symbol_start}", "#{line_num}.#{symbol_start + 1}")
      @text.tag_add('md_symbol', "#{line_num}.#{content_end}", "#{line_num}.#{content_end + 1}")
    end

    # Strikethrough
    line_text.scan(/~~(.+?)~~/) do
      m = Regexp.last_match
      content_start = m.begin(1)
      content_end   = m.end(1)
      symbol_start  = m.begin(0)

      @text.tag_add('strikethrough', "#{line_num}.#{content_start}", "#{line_num}.#{content_end}")
      @text.tag_add('md_symbol', "#{line_num}.#{symbol_start}", "#{line_num}.#{symbol_start + 2}")
      @text.tag_add('md_symbol', "#{line_num}.#{content_end}", "#{line_num}.#{content_end + 2}")
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
      parse_line(line_num, true)
    end
    rebuild_headers_cache
  end

  def rebuild_headers_cache
    @headers_cache = []
    total_lines = @text.index('end').split('.')[0].to_i - 1

    (1..total_lines).each do |line_num|
      line_text = @text.get("#{line_num}.0", "#{line_num}.end")
      if m = line_text.match(/^(\#{1,6})\s+(.*)/)
        hash_count = m[1].length
        content = m[2] || ""
        indent = "    " * (hash_count - 1)
        @headers_cache << { line: line_num, text: "#{indent}#{content.strip}" }
      end
    end
  end

  def get_headers
    @headers_cache
  end

  def get_current_header_line
    current_line = @text.index('insert').split('.')[0].to_i
    current_header_line = nil

    @headers_cache.each do |h|
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
    @headers_cache.find { |h| h[:line] == line }&.dig(:text)
  end
end
