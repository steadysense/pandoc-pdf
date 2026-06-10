// =============================================================================
// SteadySense Document Template
// Typst equivalent of main.tex + preamble.sty
// Compatible with Pandoc YAML front matter
// Usage: pandoc input.md --to typst --template template.typ -o output.pdf
// =============================================================================


// -----------------------------------------------------------------------------
// 1. METADATA  (injected by Pandoc from YAML front matter)
// -----------------------------------------------------------------------------

#let project-id            = "$project-id$"
#let template-title        = "$template-title$"
#let template-identifier   = "$template-identifier$".replace("\\_", "_")
#let template-version      = "$template-version$"
#let template-author       = "$template-author$"
#let template-creation-date = "$template-creation-date$"
#let template-reviewer     = "$template-reviewer$"
#let template-review-date  = "$template-review-date$"
#let template-approver     = "$template-approver$"
#let template-approval-date = "$template-approval-date$"
#let release-tag           = "$release-tag$"


// -----------------------------------------------------------------------------
// 2. FONTS
// -----------------------------------------------------------------------------
// Arial is used in the LaTeX template via fontspec.
// Typst uses system fonts by default — "Arial" works on Windows/macOS.
// On Linux (CI/Docker), override via: --metadata body-font="Liberation Sans"

$if(body-font)$
#let body-font = "$body-font$"
$else$
#let body-font = ("Arial", "Liberation Sans", "DejaVu Sans")
$endif$
#let footer-size = 7pt
#let small-size  = 9pt    // \small in LaTeX at 11pt base ≈ 10pt, we use 9pt


// -----------------------------------------------------------------------------
// 3. PAGE LAYOUT  (mirrors \geometry settings from preamble.sty)
//    top=35mm, headheight=25mm, bottom=40mm, footskip=30mm
//    left=25mm, right=15mm
// -----------------------------------------------------------------------------

#set page(
  paper:  "a4",
  margin: (top: 35mm, bottom: 40mm, left: 25mm, right: 15mm),

  // ── Header ─────────────────────────────────────────────────────────────────
  // LaTeX:  L=logo  C=bold title + release-tag  R=project-id + page/total
  header: context {
    set text(font: body-font, size: 10pt)

    // Horizontal rule below header (LaTeX uses headrulewidth=0pt, so none)
    grid(
      columns: (2.5cm, 1fr, auto),
      gutter: 0pt,
      // Left: company logo (steadylogo.pdf must be on the resource-path)
      align(left + horizon)[
        #image("steadylogo.pdf", width: 2.5cm)
      ],
      // Centre: bold document title + optional release tag (one or two lines)
      align(center + horizon)[
        *#template-title*
        #if release-tag != "" [ \ #release-tag ]
      ],
      // Right: project-id + "page of total" (two lines)
      align(right + horizon)[
        #project-id \
        #context counter(page).display() of #context counter(page).final().first()
      ],
    )

    // thin separator line
    line(length: 100%, stroke: 0.4pt + luma(160))
  },

  // ── Footer ─────────────────────────────────────────────────────────────────
  // LaTeX:  L=created/reviewed/approved   C=identifier + version   R=confidential
  footer: context {
    set text(font: body-font, size: footer-size)

    // thin separator line above footer
    line(length: 100%, stroke: 0.4pt + luma(160))
    v(2pt)

    grid(
      columns: (1fr, 1fr, 1fr),
      gutter: 0pt,
      // Left column – three lines mirroring LaTeX \fancyfoot[L]
      align(left)[
        Created: #template-creation-date, #template-author \
        Reviewed: #template-review-date, #template-reviewer \
        Approved: #template-approval-date, #template-approver
      ],
      // Centre – identifier and version
      align(center)[
        #template-identifier \
        Version #template-version
      ],
      // Right – confidentiality
      align(right)[
        Confidential \
        Copyright by SteadySense GmbH
      ],
    )
  },
)


// -----------------------------------------------------------------------------
// 4. TYPOGRAPHY
// -----------------------------------------------------------------------------

// Language from YAML front matter: set lang: "de" or lang: "en" (etc.)
// Falls back to "de" (German) if not specified — activates the correct
// hyphenation dictionary for table cells where justify: true is set.
#set text(
  font:   body-font,
  size:   11pt,
  lang:   "$if(lang)$$lang$$else$de$endif$",
)

// No paragraph indent (LaTeX: \setlength{\parindent}{0pt})
#set par(
  first-line-indent: 0pt,
  justify: false,
)


// -----------------------------------------------------------------------------
// 5. HEADINGS
//
//  Matches the reference PDF layout exactly:
//    • All heading levels bold at body size (11pt) — no font size hierarchy.
//      Bold weight alone signals structure; the numbering provides depth.
//    • Space BEFORE heading: ~11pt (non-weak so it always applies, even after
//      lists or tables where Typst's weak-spacing collapses).
//    • Space AFTER heading: ~6pt (non-weak, so body text always has room).
//
//  Why non-weak: v(x, weak:true) collapses against adjacent paragraph spacing,
//  resulting in near-zero gaps after headings. Non-weak v() always inserts the
//  exact amount, matching the reference output.
// -----------------------------------------------------------------------------

#set heading(numbering: "1.1")

// Shared heading style — size, space-before, and space-after per level.
#let heading-style(it, size: 11pt, before: 8pt, after: 6pt) = {
  set text(font: body-font, size: size, weight: "bold")
  v(before)
  block(spacing: 0pt, it)
  v(after)
}

//  Level 1  14pt — top-level chapter
//  Level 2  12pt — subsection
//  Level 3  11pt — sub-subsection (body size, bold enough to stand out)
//  Level 4  11pt — paragraph heading
//
//  before: space separating heading from preceding content
//  after:  breathing room between heading and its body text
#show heading.where(level: 1): it => heading-style(it, size: 14pt, before: 14pt, after: 6pt)
#show heading.where(level: 2): it => heading-style(it, size: 12pt, before: 10pt, after: 5pt)
#show heading.where(level: 3): it => heading-style(it, size: 11pt, before: 8pt,  after: 6pt)
#show heading.where(level: 4): it => heading-style(it, size: 11pt, before: 6pt,  after: 4pt)


// -----------------------------------------------------------------------------
// 6. TABLES
//    Column widths are set by table-columns.lua (smart fixed/flex split).
//    The show-rule here handles styling only: font, stroke, header row.
// -----------------------------------------------------------------------------

#set table(
  stroke:  0.5pt + luma(150),
  inset:   (x: 6pt, y: 5pt),
  fill:    none,
)

// Header row: bold text
#show table.cell.where(y: 0): set text(weight: "bold")

// All table text: small font, left-aligned, full text width.
// justify: true activates Typst's German hyphenation (lang: "de") inside cells,
// breaking long compound words like "Überwachungsaudit" correctly.
#show table: it => block(
  width: 100%,
  {
    set text(font: body-font, size: small-size)
    set align(left)
    set par(justify: true)
    it
  }
)

// Long tables: Typst handles page breaks automatically — no longtable needed.


// -----------------------------------------------------------------------------
// 7. LISTS  (LaTeX: \tightlist — compact spacing)
// -----------------------------------------------------------------------------

#set list(
  indent:  1em,
  spacing: 4pt,   // tight list equivalent
)

#set enum(
  indent:  1em,
  spacing: 4pt,
)


// -----------------------------------------------------------------------------
// 8. CODE BLOCKS  (mirrors lstlisting settings from preamble.sty)
//    backgroundcolor={220,220,220} → luma(220)
//    basicstyle=\footnotesize → 8pt in Typst
// -----------------------------------------------------------------------------

#show raw.where(block: true): it => {
  set text(font: "Courier New", size: 8pt)
  block(
    fill:   luma(220),
    inset:  8pt,
    radius: 2pt,
    width:  100%,
    it,
  )
}

#show raw.where(block: false): it => {
  set text(font: "Courier New", size: 9pt)
  it
}


// -----------------------------------------------------------------------------
// 9. LINKS  (LaTeX: colorlinks=false, hidelinks → no visible link decoration)
//
// Long link texts like "FB_2.2_30_Medical_File_SteadyTemp" would overflow
// table cells because underscores and hyphens are not line-break opportunities.
// A document-wide show regex inserts a zero-width space after every _ and -,
// giving Typst break points without changing the visible text or the URL.
// Using show regex (not show "_") avoids the infinite-recursion problem that
// occurs when a show rule for a single character fires inside itself.
// -----------------------------------------------------------------------------

// Allow line-breaking after underscores and hyphens throughout the document.
// This is especially important for long link texts and file paths in tables.
#show regex("[_\-]"): it => it + sym.zws

#show link: it => {
  set text(fill: black)
  underline(it)
}


// -----------------------------------------------------------------------------
// 10. IMAGES  (LaTeX: width=0.7\maxwidth, keepaspectratio)
// -----------------------------------------------------------------------------

#set image(width: 70%)


// -----------------------------------------------------------------------------
// 11. TABLE OF CONTENTS
//     Pandoc passes toc=true when [TOC] is in the markdown.
//     The TOC heading itself is excluded from numbering.
// -----------------------------------------------------------------------------

$if(toc)$
#outline(
  title:  [Contents],
  depth:  4,
  indent: 1em,
)
#pagebreak()
$endif$


// -----------------------------------------------------------------------------
// 12. PANDOC HELPERS  (functions pandoc's Typst writer expects)
// -----------------------------------------------------------------------------

// Horizontal rule — generated by pandoc for markdown "---" thematic breaks.
#let horizontalrule = {
  v(0.5em)
  line(length: 100%, stroke: 0.4pt + luma(160))
  v(0.5em)
}


// -----------------------------------------------------------------------------
// 13. DOCUMENT BODY  (Pandoc inserts converted markdown here)
// -----------------------------------------------------------------------------

$body$
