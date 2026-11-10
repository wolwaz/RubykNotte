# frozen_string_literal: true

# Tiny JSON preferences file. Invalid or missing files fall back to defaults
# so a corrupt settings.json can never keep the editor from starting.
class UserSettings
  DEFAULTS = {
    theme: :sepia,
    font_size: 12,
    line_spacing: 4,
    text_padding_x: 25,
    text_padding_y: 20
  }.freeze

  def self.default_path
    File.join(Dir.home, '.markdown_editor_backups', 'settings.json')
  end

  attr_reader :path

  def initialize(path = nil)
    @path = path || self.class.default_path
    @values = DEFAULTS.dup
    load_from_disk
  end

  def [](key)
    @values[key]
  end

  def to_h
    @values.dup
  end

  def replace(attrs)
    attrs.each do |key, value|
      key = key.to_sym
      next unless DEFAULTS.key?(key)
      @values[key] = normalize(key, value)
    end
    self
  end

  def save
    FileUtils.mkdir_p(File.dirname(@path))
    tmp_path = "#{@path}.tmp.#{Process.pid}"
    File.write(tmp_path, JSON.pretty_generate(serializable), encoding: 'UTF-8')
    FileUtils.mv(tmp_path, @path, force: true)
    true
  rescue SystemCallError, JSON::GeneratorError
    false
  ensure
    File.delete(tmp_path) if defined?(tmp_path) && tmp_path && File.exist?(tmp_path)
  end

  private

  def load_from_disk
    return unless File.file?(@path)

    raw = JSON.parse(File.read(@path, encoding: 'UTF-8'))
    return unless raw.is_a?(Hash)

    replace(raw)
  rescue JSON::ParserError, SystemCallError, EncodingError, RangeError
    @values = DEFAULTS.dup
  end

  def normalize(key, value)
    case key
    when :theme
      name = value.to_s.to_sym
      Theme::THEMES.key?(name) ? name : DEFAULTS[:theme]
    when :font_size
      clamp_int(value, 8, 24, DEFAULTS[:font_size])
    when :line_spacing
      clamp_int(value, 0, 40, DEFAULTS[:line_spacing])
    when :text_padding_x, :text_padding_y
      clamp_int(value, 2, 100, DEFAULTS[key])
    else
      value
    end
  end

  def clamp_int(value, min, max, fallback)
    return fallback if value.is_a?(Numeric) && !value.finite?

    n = Integer(value)
    [[n, min].max, max].min
  rescue ArgumentError, TypeError, RangeError
    fallback
  end

  def serializable
    {
      'theme' => @values[:theme].to_s,
      'font_size' => @values[:font_size],
      'line_spacing' => @values[:line_spacing],
      'text_padding_x' => @values[:text_padding_x],
      'text_padding_y' => @values[:text_padding_y]
    }
  end
end
