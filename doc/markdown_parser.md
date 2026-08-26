# Markdown Parser

The `MarkdownHighlighter` is a line-based parser — it does not maintain any cross-line state. Each call to `parse_line(n)` re-derives all tags for line `n` independently.

`parse_line(line_num, force_render = false)` accepts a second argument used by horizontal rules: when `force_render` is true (full-document parse, or the HR Enter shortcut), the separator bar is applied even if the cursor is on that line.

## Supported Syntax

| Element | Pattern | Tags applied |
|---|---|---|
| H1–H6 | `^(#{1,6})\s+(.*)` | `hN` on the full line, `md_symbol` on the `#`s |
| Horizontal rule | `^\s*(-{3,}\|\*{3,}\|_{3,})\s*$` | `hr` when cursor is elsewhere or `force_render`; else `md_symbol` |
| Blockquote | `^(>\s?)(.*)` | `blockquote` on the line, `md_symbol` on `>` |
| Bold | `(?<!\*)\*\*(?!\*)(.+?)(?<!\*)\*\*(?!\*)` | `bold` on content, `md_symbol` on `**` |
| Italic | `(?<!\*)\*(?!\*)([^*]+?)\*(?!\*)` | `italic` on content, `md_symbol` on `*` |
| Bold+italic | `\*\*\*(.+?)\*\*\*` | `bold_italic` on content, `md_symbol` on `***` |
| Inline code | `` `([^`]+)` `` | `code` on content, `md_symbol` on backticks |
| Strikethrough | `~~(.+?)~~` | `strikethrough` on content, `md_symbol` on `~~` |

A space after `#` is required, so `#NoSpace` is not a header.

## Tag configuration

| Tag | Font | Color |
|---|---|---|
| `md_symbol` | inherits | theme `:md_symbol` |
| `bold` | editor + bold | inherits |
| `italic` | editor + italic | inherits |
| `bold_italic` | editor + bold italic | inherits |
| `h1`–`h6` | editor + 6/4/2/1pt + bold | theme `:text_fg` |
| `hr` | editor + 2pt + bold, centered | theme `:hr_color` |
| `blockquote` | inherits, left margin 30 | theme `:blockquote_fg` |
| `code` | Courier | theme `:code_bg` / `:code_fg` |
| `strikethrough` | editor + overstrike | theme `:strike_fg` |

`md_symbol` is raised to the top of the tag stack so markers stay muted over bold/italic/code.

## Parsing strategy

### `parse_line(line_num, force_render = false)`

1. Get text from `line_num.0` to `line_num.end`.
2. Remove all markdown tags from that line range.
3. Header match → `hN` + `md_symbol` on the hashes.
4. Horizontal rule match → `hr` (and return) or `md_symbol` while the cursor is on the line.
5. Blockquote match → `blockquote` + `md_symbol` on `>`.
6. Scan bold, italic, bold+italic, inline code, strikethrough on the original `line_text` and tag content vs markers.

Because regexes scan the original line and tag ranges overlap, simple nesting can still render (e.g. bold wrapping italic). Order is header → hr → quote → bold → italic → bold_italic → code → strike.

### `parse_current_line`

Parses the cursor's line and the line above it. Re-parsing the previous line is what turns an HR into the separator bar after you leave it.

### `parse_entire_document`

Iterates lines 1 through `end - 1` (the `-1` excludes the trailing empty line Tk always appends) with `force_render = true`, then `rebuild_headers_cache`.

## Header extraction

`get_headers` returns `@headers_cache`, rebuilt by scanning ATX headers only (no setext). Popup labels are indented 4 spaces per level (H1 = 0, H2 = 4, …).

`get_current_header_line` returns the last cached header whose `:line` is `<=` the cursor line.

## Limitations

See [Limitation.md](Limitation.md). In short: no fenced code, links, images, or setext headers; emphasis does not cross lines.
