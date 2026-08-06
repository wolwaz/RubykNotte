# frozen_string_literal: true

require 'minitest/autorun'
require 'tempfile'

# Load application classes without starting Tk or opening a GUI window.
source = File.read(File.expand_path('../tknote.rb', __dir__))
source = source.sub(/\Arequire 'tk'\s*/, '')
source = source.sub(/\Arequire 'tkextlib\/tile'\s*/, '')
source = source.sub(/\n# 5\. APP ENTRY POINT WITH CRASH HANDLER.*\z/m, '')

module Tk
  def self.messageBox(**_kwargs)
    'ok'
  end
end

Object.class_eval(source, __FILE__, 1)

class FakeText
  attr_accessor :state
  attr_reader :value, :cursor

  def initialize(value = '')
    @value = value
    @cursor = 0
    @selection = nil
    @state = 'normal'
  end

  def value=(new_value)
    @value = new_value.to_s
    @cursor = 0
    @selection = nil
  end

  def get(start_index, end_index)
    @value[offset_for(start_index)...offset_for(end_index)] || ''
  end

  def index(index)
    offset = offset_for(index)
    return "#{line_count + 1}.0" if offset > @value.length

    before = @value[0...offset]
    line = before.count("\n") + 1
    column = offset - (before.rindex("\n") || -1) - 1
    "#{line}.#{column}"
  end

  def count(_start_index, end_index, _unit)
    [offset_for(end_index)]
  end

  def insert(index, string)
    offset = offset_for(index)
    @value = @value[0...offset] + string.to_s + @value[offset..]
    @cursor = offset + string.to_s.length
  end

  def replace(start_index, end_index, string)
    start_offset = offset_for(start_index)
    end_offset = offset_for(end_index)
    @value = @value[0...start_offset] + string.to_s + @value[end_offset..]
    @cursor = start_offset + string.to_s.length
  end

  def delete(start_index, end_index)
    replace(start_index, end_index, '')
  end

  def mark_set(mark, index)
    raise ArgumentError, "Unsupported mark #{mark}" unless mark == 'insert'

    @cursor = offset_for(index)
  end

  def see(_index); end

  def edit_separator; end

  def tag_add(tag, start_index, end_index)
    return unless tag == 'sel'

    @selection = [offset_for(start_index), offset_for(end_index)]
  end

  def tag_remove(tag, _start_index, _end_index)
    @selection = nil if tag == 'sel'
  end

  def tag_ranges(tag)
    return [] unless tag == 'sel' && @selection

    [index(@selection[0]), index(@selection[1])]
  end

  def tag_names
    []
  end

  def edit_reset; end

  def tag_configure(*_args, **_kwargs); end

  def tag_raise(*_args); end

  def configure(*_args, **_kwargs); end

  def background(*_args); end

  def foreground(*_args); end

  def yview
    [0.0, 1.0]
  end

  def yview_moveto(_position); end

  private

  def line_count
    @value.count("\n") + 1
  end

  def offset_for(index)
    case index
    when Integer
      index
    when '1.0'
      0
    when 'end'
      @value.length + 1
    when 'end - 1 char'
      @value.length
    when 'insert'
      @cursor
    when 'sel.first'
      raise ArgumentError, 'No selection' unless @selection

      @selection[0]
    when 'sel.last'
      raise ArgumentError, 'No selection' unless @selection

      @selection[1]
    else
      if (match = /\A(\d+)\.(\d+)\z/.match(index))
        line = match[1].to_i
        column = match[2].to_i
        lines = @value.split("\n", -1)
        lines.first(line - 1).sum { |text| text.length + 1 } + column
      elsif (match = /\A(\d+)\.end\z/.match(index))
        line = match[1].to_i
        lines = @value.split("\n", -1)
        lines.first(line).sum { |text| text.length + 1 } - 1
      elsif (match = /\A1\.0 \+ (\d+) chars\z/.match(index))
        match[1].to_i
      elsif (match = /\A(.+) \+ (\d+) chars\z/.match(index))
        offset_for(match[1]) + match[2].to_i
      elsif (match = /\A(.+) \+ (\d+) char\z/.match(index))
        offset_for(match[1]) + match[2].to_i
      elsif (match = /\A(.+) - (\d+) chars\z/.match(index))
        offset_for(match[1]) - match[2].to_i
      elsif (match = /\A(.+) - (\d+) char\z/.match(index))
        offset_for(match[1]) - match[2].to_i
      else
        raise ArgumentError, "Unsupported text index #{index.inspect}"
      end
    end
  end
end

class FakeEditor
  attr_reader :text, :highlighter, :app

  def initialize(text = '')
    @text = FakeText.new(text)
    @highlighter = MarkdownHighlighter.new(@text)
    @app = Object.new
    @app.define_singleton_method(:update_header_list) {}
  end
end

class FakeNotebook
  attr_reader :configured_text

  def itemconfigure(_tab_frame, text:)
    @configured_text = text
  end
end

class FakeLabel
  attr_accessor :text
end

class MarkdownHighlighterRegressionTest < Minitest::Test
  def setup
    @text = FakeText.new
    @highlighter = MarkdownHighlighter.new(@text)
  end

  def test_headers_support_levels_one_through_six
    @text.value = "# One\n## Two\n### Three\n#### Four\n##### Five\n###### Six"

    @highlighter.parse_entire_document

    assert_equal [1, 2, 3, 4, 5, 6], @highlighter.get_headers.map { |header| header[:line] }
  end
end

class FindReplaceRegressionTest < Minitest::Test
  def test_backward_find_wraps_to_last_match
    editor = FakeEditor.new('alpha beta alpha')
    dialog = FindReplaceDialog.allocate
    dialog.instance_variable_set(:@editor, editor)
    dialog.instance_variable_set(:@text, editor.text)
    dialog.instance_variable_set(:@find_entry, Struct.new(:value).new('alpha'))
    dialog.instance_variable_set(:@match_case, Struct.new(:value).new('0'))
    dialog.instance_variable_set(:@use_regex, Struct.new(:value).new('0'))

    editor.text.mark_set('insert', '1.0')
    dialog.find(:backward)

    assert_equal '1.11', editor.text.index('sel.first')
    assert_equal '1.16', editor.text.index('sel.last')
  end
end

class EditorPaneRegressionTest < Minitest::Test
  def test_italic_without_selection_creates_a_pair_and_places_cursor_inside
    pane = EditorPane.allocate
    text = FakeText.new
    pane.instance_variable_set(:@text, text)

    pane.insert_italic

    assert_equal '**', text.value
    assert_equal 1, text.cursor
  end

  def test_duplicate_line_handles_an_empty_line
    pane = EditorPane.allocate
    text = FakeText.new("first\n\nthird")
    pane.instance_variable_set(:@text, text)
    pane.instance_variable_set(:@highlighter, Object.new)
    pane.instance_variable_get(:@highlighter).define_singleton_method(:parse_line) { |_line_num| }

    text.mark_set('insert', '2.0')
    pane.duplicate_line

    assert_equal "first\n\n\nthird", text.value
  end
end

class FileOperationRegressionTest < Minitest::Test
  def test_open_file_loads_contents_and_marks_document_clean
    Tempfile.create(['rubyknotte', '.md']) do |file|
      file.write("# Heading\n\nHello")
      file.flush

      editor = MarkdownEditor.allocate
      fake_editor = FakeEditor.new
      notebook = FakeNotebook.new
      status_center = FakeLabel.new
      status_left = FakeLabel.new
      backup_file = File.join(File.dirname(file.path), 'recovery.md')

      editor.instance_variable_set(:@editor, fake_editor)
      editor.instance_variable_set(:@notebook, notebook)
      editor.instance_variable_set(:@tab_frame, Object.new)
      editor.instance_variable_set(:@status_center, status_center)
      editor.instance_variable_set(:@status_left, status_left)
      editor.instance_variable_set(:@is_modified, true)
      editor.instance_variable_set(:@backup_file, backup_file)

      editor.define_singleton_method(:update_header_list) {}
      Tk.define_singleton_method(:getOpenFile) { |**_kwargs| file.path }

      editor.open_file

      assert_equal "# Heading\n\nHello", fake_editor.text.value
      refute editor.is_modified
      assert_equal File.basename(file.path), status_center.text
    end
  end
end

class QuitRegressionTest < Minitest::Test
  def test_save_and_quit_does_not_exit_when_save_does_not_clear_modified_state
    editor = MarkdownEditor.allocate
    root = Object.new
    destroyed = false
    root.define_singleton_method(:destroy) { destroyed = true }

    editor.instance_variable_set(:@root, root)
    editor.instance_variable_set(:@is_modified, true)
    editor.define_singleton_method(:save_file) {}
    Tk.define_singleton_method(:messageBox) { |**_kwargs| 'yes' }

    editor.quit_app

    refute destroyed
  end
end
