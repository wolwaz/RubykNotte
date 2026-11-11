# frozen_string_literal: true

require 'minitest/autorun'
require 'tempfile'
require 'tmpdir'

# Stub Tk before loading the application modules so the classes can be
# defined without a real GUI.
module Tk
  def self.messageBox(**_kwargs)
    'ok'
  end

  def self.after(_ms, *_args, **_kwargs)
    nil
  end

  def self.after_cancel(_id)
    nil
  end
end

# Locate the modules. Prefer lib/ next to the project root, otherwise the root.
test_dir = File.expand_path(__dir__)
root_dir = File.expand_path('..', test_dir)
lib_dir = File.join(root_dir, 'lib')
load_dir = Dir.exist?(lib_dir) ? lib_dir : root_dir

$LOAD_PATH.unshift(load_dir) unless $LOAD_PATH.include?(load_dir)

require 'theme'
require 'user_settings'
require 'markdown_highlighter'
require 'find_replace_dialog'
require 'editor_pane'
require 'markdown_editor'

class FakeText
  attr_accessor :state
  attr_reader :value, :cursor, :applied_tags

  def initialize(value = '')
    @value = value
    @cursor = 0
    @selection = nil
    @state = 'normal'
    @applied_tags = []
  end

  # ... remainder of the original test file (full content is 27k; this call may truncate)
end
