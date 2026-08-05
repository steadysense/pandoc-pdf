// =============================================================================
// SteadySense Report Template
// For external reports and non-QM documents
// Compatible with Pandoc YAML front matter (title, subtitle, author, date, version)
// Usage: pandoc input.md --to typst --template template-report.typ -o output.pdf
//
// Supported metadata:
//   title        Document title (shown in header + title page)
//   subtitle     Optional subtitle (title page only)
//   author       Author name(s)
//   date         Document date (e.g. 2026-08-04)
//   version      Version string (e.g. v1.0)
//   lang         Language code for hyphenation (default: en)
//   release-tag  Optional tag shown below title in header (e.g. "draft")
//   no-title-page  Set to true to suppress the auto-generated title page
// =============================================================================


// -----------------------------------------------------------------------------
// 1. METADATA  (injected by Pandoc from YAML front matter or --metadata flags)
// -----------------------------------------------------------------------------

#let doc-title        = "$if(title)$$title$$else$$endif$".replace("\\_", "_")
#let doc-subtitle     = "$if(subtitle)$$subtitle$$else$$endif$".replace("\\_", "_")
#let doc-author       = "$for(author)$$author$$sep$, $endfor$"
#let doc-date         = "$if(date)$$date$$else$$endif$"
#let doc-version      = "$if(version)$$version$$else$$endif$"
#let release-tag      = "$if(release-tag)$$release-tag$$else$$endif$"
#let company-name      = "$if(company-name)$$company-name$$else$SteadySense GmbH$endif$"
#let company-address   = "$if(company-address)$$company-address$$else$Johann-Schreiner-Straße 3$endif$"
#let company-address-2 = "$if(company-address-2)$$company-address-2$$else$A-8074 Raaba-Grambach$endif$"
#let company-website   = "$if(company-website)$$company-website$$else$www.steadysense.at$endif$"
#let company-mail      = "$if(company-mail)$$company-mail$$else$office@steadysense.at$endif$"


// -----------------------------------------------------------------------------
// 2. FONTS
// -----------------------------------------------------------------------------
// macOS: Arial / Courier New
// Linux/Docker: Liberation Sans / Liberation Mono  (pass via --metadata body-font=...)

$if(body-font)$
#let body-font = "$body-font$"
$else$
#let body-font = ("Arial", "Liberation Sans", "DejaVu Sans")
$endif$

$if(code-font)$
#let code-font = "$code-font$"
$else$
#let code-font = ("Courier New", "Liberation Mono", "DejaVu Sans Mono")
$endif$

#let footer-size = 7pt
#let small-size  = 9pt


// -----------------------------------------------------------------------------
// 3. PAGE LAYOUT
//    Same margins as the QM template for visual consistency.
// -----------------------------------------------------------------------------

#set page(
  paper:  "a4",
  margin: (top: 35mm, bottom: 40mm, left: 25mm, right: 15mm),

  // ── Header ─────────────────────────────────────────────────────────────────
  // Left: company logo  |  Centre: bold title + date (or release-tag)
  // Right: page / total
  header: context {
    set text(font: body-font, size: 10pt)

    grid(
      columns: (2.5cm, 1fr, auto),
      gutter: 0pt,
      align(left + horizon)[
        #image("steadylogo.pdf", width: 2.5cm)
      ],
      align(center + horizon)[
        *#doc-title* \
        #text(size: 9pt, weight: "regular")[
          #if release-tag != "" [#release-tag] else [#doc-date]
        ]
      ],
      align(right + horizon)[
        #context counter(page).display() of #context counter(page).final().first()
      ],
    )

    line(length: 100%, stroke: 0.4pt + luma(160))
  },

  // ── Footer ─────────────────────────────────────────────────────────────────
  // Left: company name + address  |  Centre: website + email  |  Right: Confidential
  footer: context {
    set text(font: body-font, size: footer-size)

    line(length: 100%, stroke: 0.4pt + luma(160))
    v(2pt)

    grid(
      columns: (1fr, 1fr, 1fr),
      gutter: 0pt,
      align(left)[
        #company-name \
        #company-address \
        #company-address-2
      ],
      align(center)[
        #company-website \
        #company-mail
      ],
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

#set text(
  font: body-font,
  size: 11pt,
  lang: "$if(lang)$$lang$$else$en$endif$",
)

#set par(
  first-line-indent: 0pt,
  justify: false,
)


// -----------------------------------------------------------------------------
// 5. HEADINGS
// -----------------------------------------------------------------------------

#set heading(numbering: "1.1")

#let heading-style(it, size: 11pt, before: 8pt, after: 6pt) = {
  set text(font: body-font, size: size, weight: "bold")
  v(before)
  block(spacing: 0pt, it)
  v(after)
}

#show heading.where(level: 1): it => heading-style(it, size: 14pt, before: 24pt, after: 10pt)
#show heading.where(level: 2): it => heading-style(it, size: 12pt, before: 20pt, after: 8pt)
#show heading.where(level: 3): it => heading-style(it, size: 11pt, before: 16pt, after: 7pt)
#show heading.where(level: 4): it => heading-style(it, size: 11pt, before: 12pt, after: 6pt)


// -----------------------------------------------------------------------------
// 6. TABLES
// -----------------------------------------------------------------------------

#set table(
  stroke: 0.5pt + luma(150),
  inset:  (x: 6pt, y: 5pt),
  fill:   none,
)

#show table.cell.where(y: 0): set text(weight: "bold")

#show table: it => block(
  width: 100%,
  {
    set text(font: body-font, size: small-size)
    set align(left)
    set par(justify: true)
    it
  }
)


// -----------------------------------------------------------------------------
// 7. LISTS
// -----------------------------------------------------------------------------

#set list(
  indent:  1em,
  spacing: 4pt,
)

#set enum(
  indent:  1em,
  spacing: 4pt,
)


// -----------------------------------------------------------------------------
// 8. CODE BLOCKS
// -----------------------------------------------------------------------------

#show raw.where(block: true): it => {
  set text(font: code-font, size: 8pt)
  block(
    fill:   luma(220),
    inset:  8pt,
    radius: 2pt,
    width:  100%,
    it,
  )
}

#show raw.where(block: false): it => {
  set text(font: code-font, size: 9pt)
  it
}


// -----------------------------------------------------------------------------
// 9. LINKS
// -----------------------------------------------------------------------------

// Zero-width space after _ and - for line-breaking in long identifiers/paths
#show regex("[_\-]"): it => it + sym.zws

#show link: it => {
  set text(fill: black)
  underline(it)
}


// -----------------------------------------------------------------------------
// 10. IMAGES
// -----------------------------------------------------------------------------

#set image(width: 70%)


// -----------------------------------------------------------------------------
// 11. TITLE PAGE
//     Auto-generated from metadata unless --metadata no-title-page=true is set.
//     Uses a separate page with no header/footer and centred layout.
// -----------------------------------------------------------------------------

$if(no-title-page)$
$else$
#v(1fr)

#align(center)[
  #image("steadylogo.pdf", width: 5cm)

  #v(2cm)

  #text(size: 22pt, weight: "bold")[#doc-title]

  #if doc-subtitle != "" {
    v(0.8cm)
    text(size: 15pt)[#doc-subtitle]
  }

  #if doc-date != "" {
    v(1cm)
    text(size: 11pt)[#doc-date]
  }
]

#v(1fr)

#pagebreak()
$endif$


// -----------------------------------------------------------------------------
// 12. TABLE OF CONTENTS
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
// 13. PANDOC HELPERS
// -----------------------------------------------------------------------------

#let horizontalrule = {
  v(0.5em)
  line(length: 100%, stroke: 0.4pt + luma(160))
  v(0.5em)
}


// -----------------------------------------------------------------------------
// 14. DOCUMENT BODY  (Pandoc inserts converted markdown here)
// -----------------------------------------------------------------------------

$body$
