# ==========================================
# RubykNotte Settings
# ==========================================
# Small local persistence layer for user preferences.
# The application can grow this into a full settings system later;
# for v0.4 it intentionally stays simple and dependency-free.

require 'fileutils'
require 'json'

module RubykNotte
  class Settings
    DEFAULTS = {
      theme: :sepia,
      font_size: 12,
      line_spacing: 4,
      text_padding_x: 25,
      text_padding_y: 20
    }.freeze

    attr_reader :path

    def initialize(path = nil)
      @path = path || default_path
      @values = DEFAULTS.dup
      load
    end

    def get(key)
      key = key.to_sym
      @values.fetch(key, DEFAULTS[key])
    end

    def set(key, value)
      key = key.to_sym
      return false unless DEFAULTS.key?(key)

      @values[key] = normalize(key, value)
      true
    end

    def update(values)
      values.each { |key, value| set(key, value) }
      self
    end

    def to_h
      @values.dup
    end

    def save
      FileUtils.mkdir_p(File.dirname(@path))
      tmp_path = "#{@path}.tmp"
      File.write(tmp_path, JSON.pretty_generate(stringify_keys(@values)), encoding: 'UTF-8')
      FileUtils.mv(tmp_path, @path, force: true)
      true
    rescue SystemCallError, JSON::GeneratorError
      false
    ensure
      File.delete(tmp_path) if defined?(tmp_path) && File.exist?(tmp_path)
    end

    def reset
      @values = DEFAULTS.dup
      self
    end

    private

    def default_path
      File.join(Dir.home, '.config', 'rubyknotte', 'settings.json')
    end

    def load
      return unless File.file?(@path)

      raw = JSON.parse(File.read(@path, encoding: 'UTF-8'))
      return unless raw.is_a?(Hash)

      raw.each { |key, value| set(key, value) }
    rescue JSON::ParserError, SystemCallError
      # Invalid or inaccessible settings should never prevent the editor
      # from starting. Keep defaults and let the next save repair the file.
      @values = DEFAULTS.dup
    end

    def normalize(key, value)
      case key
      when :theme
        value.to_s.to_sym
      when :font_size
        [[value.to_i, 8].max, 72].min
      when :line_spacing
        [[value.to_i, 0].max, 40].min
      when :text_padding_x, :text_padding_y
        [[value.to_i, 0].max, 100].min
      else
        value
      end
    end

    def stringify_keys(hash)
      hash.each_with_object({}) { |(key, value), result| result[key.to_s] = value.to_s if key == :theme; result[key.to_s] = value unless key == :theme }
    end
  end
end
