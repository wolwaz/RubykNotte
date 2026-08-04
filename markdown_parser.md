Markdown Parser

The MarkdownHighlighter is a line-based parser — it does not maintainany cross-line state. Each call to parse_line(n) re-derives all tagsfor line n independently.
Supported Syntax
Element	Pattern	Tags Applied
H1	^#\s+(.*)	h1 on full line, md_symbol on #
H2	^##\s+(.*)	h2 + md_symbol on ##
H3–H6	^#{3,6}\s+(.*)	h3–h6 + md_symbol
Bold	\*\*(?!\*)(.+?)(?<!\*)\*\*	bold on content, md_symbol on ** markers
Italic	(?<!\*)\*([^*]+?)\*(?!\*)	italic on content, md_symbol on * markers
Tag Configuration
Tag	Font	Foreground
md_symbol	(inherits)	#888888 default, theme :md_symbol
bold	editor font + bold	(inherits)
italic	editor font + italic	(inherits)
h1	editor font + 6pt + bold	theme :text_fg
h2	editor font + 4pt + bold	theme :text_fg
h3	editor font + 2pt + bold	theme :text_fg
h4	editor font + 1pt + bold	theme :text_fg
h5	editor font + bold	theme :text_fg
h6	editor font + italic	theme :text_fg

md_symbol is raised to the top of the tag stack via tag_raise so italways visually overrides bold/italic on the marker characters.
Parsing Strategy
parse_line(line_num)

    Get text from line_num.0 to line_num.end
    Remove all markdown tags from that line range
    If line matches header regex → apply h{n} to whole line, md_symbol to #*s
    Scan for bold matches → apply bold to content, md_symbol to each **
    Scan for italic matches → apply italic to content, md_symbol to each *

parse_current_line

Parses the cursor's line and the line above it. The line above isre-parsed because some edits (like deleting a #) may shift the previousline's classification — though in practice this is a safety net.
parse_entire_document

Iterates lines 1 through end - 1 (the -1 excludes the trailing emptyline that Tk always appends).
Header Extraction (get_headers)

headers = [](1..total_lines).each do |line_num|  line_text = text.get("#{line_num}.0", "#{line_num}.end")  if m = line_text.match(/^(\#{1,6})\s+(.*)/)    hash_count = m[1].length    content = m[2] || ""    indent = "    " * (hash_count - 1)   # 4 spaces per level    headers << { line: line_num, text: "#{indent}#{content.strip}" }  endend

     Headers are indented in the popup by 4 spaces per level (H1 = 0, H2 = 4, H3 = 8, ...).
     Only #-style headers are recognized (no setext === or ---).
     A space after # is required (#\s+), so #NoSpace is not a header.

Current Header Detection

get_current_header_line iterates all headers and returns the last one
whose :line is <= the cursor's line. This gives the "section" the
cursor is currently inside.
Limitations

     No support for code blocks (```), blockquotes (>), or links [text](url)
     No multi-line bold/italic (each line is parsed independently)
     Inline code (`) is auto-paired by EditorPane but not highlighted differently
     Setext headers are not recognized