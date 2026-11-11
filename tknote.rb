require 'tk'
require 'tkextlib/tile'
require 'fileutils'
require 'json'

# Detect the directory this script lives in, then load the modules from
# a lib/ subdirectory if it exists, otherwise from the same directory.
# This lets the files sit either under lib/ or flat next to tknote.rb.
script_dir = File.expand_path(File.dirname(__FILE__))
lib_dir = File.join(script_dir, 'lib')
load_dir = Dir.exist?(lib_dir) ? lib_dir : script_dir

$LOAD_PATH.unshift(load_dir) unless $LOAD_PATH.include?(load_dir)

require 'theme'
require 'user_settings'
require 'markdown_highlighter'
require 'find_replace_dialog'
require 'editor_pane'
require 'markdown_editor'

# ==========================================
# APP ENTRY POINT WITH CRASH HANDLER
# ==========================================

Signal.trap('SIGINT') { raise Interrupt }
Signal.trap('SIGTERM') { raise SignalException.new('SIGTERM') }

app = nil
begin
  app = MarkdownEditor.new
  app.run
rescue Exception => e
  is_exit = e.is_a?(SystemExit) || e.is_a?(Interrupt) || e.is_a?(SignalException)
  puts "Application Crashed: #{e.message}" unless is_exit
  puts e.backtrace unless is_exit

  begin
    app.emergency_save! if app
  rescue => inner_e
    puts "Failed to save recovery file: #{inner_e.message}"
  end

  Tk.exit rescue nil
  raise
end
