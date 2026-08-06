Known Limitations
Markdown Parsing

No code block support — ``` fenced code blocks and 4-space indented code are not highlighted. Content inside them is parsed as normal Markdown.No blockquote support — > lines are not styled.No link styling — [text](url) is not highlighted; the [] and () are auto-paired but the text is plain.No image syntax — ![alt](url) is not recognized.No setext headers — === and --- underlines are not detected; only ATX (#) headers work.No multi-line bold/italic — **bold\nbold** will not highlight across the newline because parsing is line-local.***bold+italic*** — Only the bold tag applies; the parser does not handle triple-asterisk combinations.

Editor Behavior

Single tab only — The notebook has one tab. Multiple files cannot be open simultaneously.No multi-file auto-save — The app has a single-file crash recovery backup (`recovery.md`), but no timer-based autosave for individual open files. There is no version history.No file watching — If the file changes on disk while open in the editor, no reload prompt is shown.Undo granularity — `autoseparators false` is used; manual `edit_separator` calls are placed strategically, but consecutive character inserts may still result in per-keystroke undo steps depending on binding flow.No drag-and-drop — Files cannot be dropped onto the window to open them.Word wrap is hardcoded — wrap 'word'; no option for no-wrap or char-wrap.

Auto-Close Pairing

Marks are content-anchored (Tk default), not boundary-anchored — If you cut text containing an auto-close mark and paste it elsewhere, the mark may not travel correctly. reset_auto_close_tracking is only called on new_file and open_file.No auto-close for " or ' — Only *, `, [], () are paired.Symmetric char ambiguity — Typing * immediately after a * that was NOT auto-inserted (e.g., you typed * then deleted the closer manually) will insert a new pair rather than closing. This is by design (the mark tracking prevents false closes) but can feel surprising.Max 10 tracked marks — To prevent memory bloat, `@auto_close_marks` is capped at 10. Typing an 11th pair silently unsets the oldest mark.

Find & Replace

Replace All re-parses entire document — On very large files, this causes a visible freeze. No chunked/batched replacement.No find-in-selection — Replace All always operates on the whole document.Regex uses Ruby Regexp — Lookbehind/lookahead limitations of Ruby's regex engine apply. No PCRE-specific features.No incremental search — Find does not update as you type; you must press Return or click "Find Next".

Header Navigation

Header popup is a TkListbox — No fuzzy search, no keyboard type-ahead filtering. If you have 100 headers, you must scroll.Popup closes on any outside click — There is no "pin" option.Header text truncated if length exceeds 30 chars; result is 28 chars + "..." in the button label. Full text shows in the popup.

Themes

Only two themes — Sepia and Dark. No light/white theme, no user customization.Font family is hardcoded — Noto Sans. If not installed, Tk falls back silently to a default which may look different.No theme persistence — The chosen theme resets to Sepia on restart.

Platform

Tk required — The tk Ruby gem must be installed. Not bundled with default Ruby since 2.x.Emacs bindings disabled globally — Ctrl-B, Ctrl-I, Ctrl-K, Ctrl-F, Ctrl-G, Ctrl-S, Ctrl-O, Ctrl-N, Ctrl-Q are killed on all Text widgets. Ctrl-H and Ctrl-D are intentionally left alone.No high-DPI awareness — On Retina/4K displays, the editor may appear small. Use Ctrl+Plus to zoom.No clipboard integration beyond Tk default — No "Copy as HTML" or "Paste from Markdown" features.

Performance

parse_entire_document is O(n) — On a 10,000-line file, opening or theme-switching will cause a noticeable pause (~1–2 seconds).Debounce is 300ms fixed — Not configurable. Fast typists on slow machines may see lag.Status bar updates on every KeyRelease — Word counting scans the entire document each time. On very large files, this adds per-keystroke overhead.

Missing Features (Not Bugs)

No table syntax supportNo task list (- [ ]) supportNo footnote supportNo export to HTML/PDFNo split view (editor + preview)No word count goal / progress barNo multi-file session restorationNo diff/version history
