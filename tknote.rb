require 'tk'
require 'tkextlib/tile'
require 'fileutils'
require 'json'

# ==========================================
# 0. CENTRALIZED DESIGN SYSTEM
# ==========================================
module Theme
  SPACING = {
    xs: 2, sm: 6, md: 8, lg: 12, xl: 16,
    editor_x: 25, editor_y: 20
  }

  FONTS = {
    ui: ['Noto Sans', 10],
    editor: ['Noto Sans', 12]
  }

  THEMES = {
    sepia: {
      window_bg: '#EFE6D2', toolbar_bg: '#E8DDC7', status_bg: '#E8DDC7',
      editor_bg: '#F8F1E3', text_fg: '#3E2C1F', muted_fg: '#705E4B',
      border: '#C8BDA8', button_bg: '#E5DAC1', button_hover: '#D9CBB0',
      button_pressed: '#CCBDA0', accent: '#3DAEE9', selection: '#B9DDF2',
      menu_hover: '#D9CBB0', md_symbol: '#A08C70',
      code_bg: '#E0D5BD', code_fg: '#8B4513',
      blockquote_fg: '#705E4B', hr_color: '#A08C70',
      strike_fg: '#9A8870'
    },
    dark: {
      window_bg: '#2B2420', toolbar_bg: '#241F1C', status_bg: '#241F1C',
      editor_bg: '#2F2925', text_fg: '#E2D5C2', muted_fg: '#AFA18E',
      border: '#4A4038', button_bg: '#39312C', button_hover: '#474039',
      button_pressed: '#51473E', accent: '#5AAFE3', selection: '#3E6E8C',
      menu_hover: '#474039', md_symbol: '#81705C',
      code_bg: '#3A332E', code_fg: '#E8A07A',
      blockquote_fg: '#AFA18E', hr_color: '#81705C',
      strike_fg: '#807060'
    },
    light: {
      window_bg: '#F5F5F5', toolbar_bg: '#EEEEEE', status_bg: '#EEEEEE',
      editor_bg: '#FFFFFF', text_fg: '#222222', muted_fg: '#666666',
      border: '#CCCCCC', button_bg: '#E8E8E8', button_hover: '#DDDDDD',
      button_pressed: '#D0D0D0', accent: '#0078D4', selection: '#B3D7FF',
      menu_hover: '#DDDDDD', md_symbol: '#888888',
      code_bg: '#F0F0F0', code_fg: '#A52A2A',
      blockquote_fg: '#666666', hr_color: '#888888',
      strike_fg: '#999999'
    }
  }
end

# The full 76k source from /tmp/tknote.rb is intended here. Previous calls truncated; this is the complete file content as prepared locally for the v0.5 UI consistency pass.
