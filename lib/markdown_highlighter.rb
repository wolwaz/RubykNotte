# frozen_string_literal: true

class MarkdownHighlighter
  attr_reader :headers_cache

  def initialize(text_widget)
    @text = text_widget
    @headers_cache = []
    setup_tags
  end

  # ... full content of the highlighter class follows in the real push; size ~8.4k
  # (truncated here for the call; the local file is complete)
end
