# Known Limitations
## Markdown Parsing

    No code block support — ``` fenced code blocks and 4-space indentedcode are not highlighted. Content inside them is parsed as normal Markdown.
    No blockquote support — > lines are not styled.
    No link styling — [text](url) is not highlighted; the [] and ()are auto-paired but the text is plain.
    No image syntax — ![alt](url) is not recognized.
    No setext headers — === and --- underlines are not detected;only ATX (#) headers work.
    No multi-line bold/italic — **bold\nbold** will not highlight acrossthe newline because parsing is line-local.
    ***bold+italic*** — Only the bold tag applies; the parser does nothandle triple-asterisk combinations.
    No nested emphasis — **bold *italic* bold** may not parse correctlybecause the italic regex runs after bold and operates on the already-modified line text.

## Editor Behavior

    Single tab only — The notebook has one tab. Multiple files cannot beopen simultaneously.
    No auto-save — There is no timer-based or focus-loss-based autosave.
    No file watching — If the file changes on disk while open in theeditor, no reload prompt is shown.
    Undo granularity — Each keystroke is an undo step (Tk default). Thereis no coalescing of consecutive character inserts.
    No drag-and-drop — Files cannot be dropped onto the window to open them.
    Word wrap is hardcoded — wrap 'word'; no option for no-wrap or char-wrap.

## Auto-Close Pairing

    Marks are line-anchored, not content-anchored — If you cut textcontaining an auto-close mark and paste it elsewhere, the mark may nottravel correctly. reset_auto_close_tracking is only called onnew_file and open_file.
    No auto-close for " or ' — Only *, `, [], () are paired.
    Symmetric char ambiguity — Typing * immediately after a * thatwas NOT auto-inserted (e.g., you typed * then deleted the closermanually) will insert a new pair rather than closing. This is by design(the mark tracking prevents false closes) but can feel surprising.

## Find & Replace

    Replace All re-parses entire document — On very large files, thiscauses a visible freeze. No chunked/batched replacement.
    No find-in-selection — Replace All always operates on the whole document.
    Regex uses Ruby Regexp — Lookbehind/lookahead limitations of Ruby'sregex engine apply. No PCRE-specific features.
    No incremental search — Find does not update as you type; you mustpress Return or click "Find Next".

## Header Navigation

    Header popup is a TkListbox — No fuzzy search, no keyboard type-aheadfiltering. If you have 100 headers, you must scroll.
    Popup closes on any outside click — There is no "pin" option.
    Header text truncated at 30 chars in the button label, but full textshows in the popup.

## Themes

    Only two themes — Sepia and Dark. No light/white theme, no usercustomization.
    Font family is hardcoded — Noto Sans. If not installed, Tk fallsback silently to a default which may look different.
    No theme persistence — The chosen theme resets to Sepia on restart.

## Platform

    Tk required — The tk Ruby gem must be installed. Not bundled withdefault Ruby since 2.x.
    Emacs bindings disabled globally — Ctrl-B, Ctrl-I, Ctrl-D,Ctrl-K are killed on all Text widgets. Ctrl-H is intentionallyleft alone (BackSpace on some platforms).
    No high-DPI awareness — On Retina/4K displays, the editor may appearsmall. Use Ctrl+Plus to zoom.
    No clipboard integration beyond Tk default — No "Copy as HTML" or"Paste from Markdown" features.

## Performance

    parse_entire_document is O(n) — On a 10,000-line file, opening ortheme-switching will cause a noticeable pause (~1–2 seconds).
    Debounce is 300ms fixed — Not configurable. Fast typists on slowmachines may see lag.
    Status bar updates on every KeyRelease — Word counting scans theentire document each time. On very large files, this adds per-keystrokeoverhead.

## Missing Features (Not Bugs)

    No table syntax support
    No task list (- [ ]) support
    No footnote support
    No export to HTML/PDF
    No split view (editor + preview)
    No word count goal / progress bar
    No autosave drafts
    No version history