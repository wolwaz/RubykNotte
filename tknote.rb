require 'tk'
require 'tkextlib/tile'
require 'fileutils'
require 'json'

require_relative 'lib/theme'
require_relative 'lib/user_settings'
require_relative 'lib/markdown_highlighter'
require_relative 'lib/find_replace_dialog'
require_relative 'lib/editor_pane'
require_relative 'lib/markdown_editor'

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
