require 'tk'
require 'tkextlib/tile'
require 'fileutils'
require 'json'

# Search lib/ first, then the directory this script lives in.
# A module can sit in either place.
script_dir = File.expand_path(File.dirname(__FILE__))
lib_dir = File.join(script_dir, 'lib')
$LOAD_PATH.unshift(script_dir) unless $LOAD_PATH.include?(script_dir)
$LOAD_PATH.unshift(lib_dir) if Dir.exist?(lib_dir) && !$LOAD_PATH.include?(lib_dir)

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
