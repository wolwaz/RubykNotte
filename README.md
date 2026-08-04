# RubykNotte

**Disclaimer, this app is vibe coded entirely, and I have no idea what I'm even doing**

**Also, its broken as hell**

A lightweight Markdown editor written in pure Ruby + Tk.

## Goals

- Fast startup
- Low memory usage
- Comfortable writing
- Pure Ruby
- Pure Tk
- No Electron
- Large document support

## Features

### Core Features (Stable)
- **Markdown highlighting** - Headers (`#`, `##`), bold (`**bold**`), italic (`*italic*`), and markdown symbols
- **Find/Replace** - Search forward/backward, replace current, replace all (with regex and case-sensitive options)
- **Themes** - Sepia and Dark themes with customizable colors
- **Header navigation** - Dropdown popup for jumping to headers in the document
- **Word statistics** - Real-time word count, character count, and estimated reading time
- **Line spacing** - Adjustable line spacing for better readability

### Editing Features (Stable)
- **Basic editing** - Standard text editing with undo/redo support
- **Bold/Italic shortcuts** - `Ctrl+B` for bold, `Ctrl+I` for italic
- **Header insertion** - `Ctrl+H1`/`Ctrl+H2` (via toolbar) for quick header formatting
- **List continuation** - Auto-continues numbered and bulleted lists on Enter
- **Auto-pairing** - Automatically closes `*`, `` ` ``, `[ ]`, and `( )` pairs
- **Smart cursor movement** - Skip over markdown symbols when navigating with arrow keys
- **Line manipulation** - Move line up/down (`Ctrl+Up/Down`), duplicate line (`Ctrl+Shift+D`)

### Advanced Features (Needs Testing)
- **Read-Only Mode** - Toggle read-only state for the editor (via toolbar button)
- **Zoom In/Out** - Adjust font size with `Ctrl++`/`Ctrl+-` (reset with `Ctrl+0`)
- **Go to Line** - Jump to a specific line number (`Ctrl+G`)
- **Multi-tab support** - Notebook interface for multiple documents (basic implementation)
- **Paste handling** - Syntax highlighting updates after pasting
- **Real-time preview** - Live updating of header list and current header display

### Known Issues
- Italic text highlighting may not work correctly with single asterisks (`*text*`)
- Find/Replace regex mode may have edge cases with empty matches
- Header navigation popup may not close properly on all platforms
- Line movement (up/down) does not preserve text selection
- Duplicating empty lines may create extra blank lines
- No confirmation dialog when overwriting existing files on save
- Header navigation popup cant be closed and the content cant be selected
- Auto pairing broken
