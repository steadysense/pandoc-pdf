# pandoc-pdf

Converts Markdown documents to PDF using [Pandoc](https://pandoc.org/) and LaTeX (lualatex).
Designed for SteadySense QM documents with a corporate template (header, footer, logo, metadata table).

> **New Typst pipeline available for testing**
> A faster, LaTeX-free pipeline using [Typst](https://typst.app/) is in development on the
> [`feature/typst-template`](https://github.com/steadysense/pandoc-pdf/tree/feature/typst-template) branch
> and published as `ghcr.io/steadysense/pandoc-pdf:typst`.
> This branch (`main`) remains the stable production pipeline.

---

## How it works

`build.sh` scans a directory for `*.md` files matching a filename pattern, then calls Pandoc for each file.
Pandoc converts Markdown to PDF via the `main.tex` LaTeX template using `lualatex` as the PDF engine.
Output files are written to a `build/` subdirectory, mirroring the source directory structure.

---

## GitHub Actions usage

This repository is a GitHub Action. Add it to a workflow:

```yaml
- name: Generate PDFs
  uses: steadysense/pandoc-pdf@main
  with:
    template_directory: ./QM-Documents/templates
    document_directory: ./QM-Documents
```

**Action inputs**

| Input                | Required | Description                                          |
|----------------------|----------|------------------------------------------------------|
| `template_directory` | yes      | Directory containing the LaTeX template files        |
| `document_directory` | yes      | Directory containing the Markdown files to convert   |

PDFs are placed in `<document_directory>/build/`.

---

## Docker usage

**Pull the image**

```bash
docker pull ghcr.io/steadysense/pandoc-pdf:latest
```

**Run a conversion**

```bash
docker run --rm \
  -v /path/to/templates:/github/workspace/templates \
  -v /path/to/documents:/github/workspace/documents \
  -e INPUT_TEMPLATE_DIRECTORY=templates/ \
  -e INPUT_DOCUMENT_DIRECTORY=documents/ \
  ghcr.io/steadysense/pandoc-pdf:latest
```

PDFs are written to `/path/to/documents/build/`.

---

## Document format

Each Markdown file must include a YAML front matter block with template metadata.
See the documents in your QM repository for examples.

**Supported Markdown features**

- Tables, images, code blocks, numbered/bulleted lists
- Image sizing: `![alt](path){width=600px}`
- Internal anchor links
- `[TOC]` marker (generates a table of contents)

---

## Repository structure

```
pandoc-pdf/
├── templates/                # LaTeX templates and assets (mounted at runtime)
│   ├── main.tex              # Main LaTeX document template
│   ├── preamble.sty          # LaTeX style definitions
│   ├── pandoc_filter.py      # Pandoc filter for custom processing
│   └── steadylogo.pdf        # Logo used in the header
├── build.sh                  # Conversion script (called inside Docker)
├── entrypoint.sh             # Docker entrypoint
├── Dockerfile                # Docker image definition (pandoc/latex base)
├── action.yml                # GitHub Action definition
├── requirements.txt          # Python dependencies for pandoc_filter
└── texpkgs.txt               # Additional LaTeX packages installed at build time
```

---

## GHCR image tags

| Tag | Branch | Pipeline | Status |
|-----|--------|----------|--------|
| `latest` | `main` | LaTeX / lualatex | stable, production |
| `typst` | `feature/typst-template` | Typst | testing |
