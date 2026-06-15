# pandoc-pdf

Converts Markdown documents to PDF using [Pandoc](https://pandoc.org/) and [Typst](https://typst.app/).
Designed for SteadySense QM documents with a corporate template (header, footer, logo, metadata table).

## How it works

`build.sh` scans a directory for `*.md` files matching a filename pattern, then calls Pandoc for each file.
Pandoc converts Markdown to Typst using the bundled template and Lua filters, then Typst renders the final PDF.
Output files are written to a `build/` subdirectory, mirroring the source directory structure.

---

## Local usage

### Prerequisites

- [Docker](https://docs.docker.com/get-docker/) (recommended — no local Pandoc/Typst install needed)
- **Or** install manually: `pandoc` >= 3.0, `typst`, `bash`

### Option A: Docker (recommended)

**1. Pull the image from GitHub Container Registry**

```bash
docker pull ghcr.io/steadysense/pandoc-pdf:latest
```

**Or build it locally:**

```bash
git clone <this-repo>
cd pandoc-pdf
docker build -t pandoc-pdf .
```

**2. Run a conversion**

```bash
docker run --rm \
  -v /path/to/your/documents:/docs \
  -e INPUT_DOCUMENT_DIRECTORY=/docs \
  -e RELEASE=draft \
  ghcr.io/steadysense/pandoc-pdf:latest
```

Converted PDFs appear in `/path/to/your/documents/build/`.

**Environment variables**

| Variable                   | Default               | Description                                               |
|----------------------------|-----------------------|-----------------------------------------------------------|
| `INPUT_DOCUMENT_DIRECTORY` | *(required)*          | Path to the directory containing `.md` files              |
| `INPUT_TEMPLATE_DIRECTORY` | `/typst` (bundled)    | Override with a custom Typst template directory           |
| `RELEASE`                  | `draft`               | Release tag shown in the PDF header (e.g. `v2026-06-10`) |
| `DOC_ID`                   | `FB\|PB\|DA\|AA\|QMH` | Regex to filter which `.md` files are converted           |

**Example: convert only `FB` files with a release tag**

```bash
docker run --rm \
  -v "$(pwd)/testdocs":/docs \
  -e INPUT_DOCUMENT_DIRECTORY=/docs \
  -e RELEASE=v2026-06-15 \
  -e DOC_ID=FB \
  ghcr.io/steadysense/pandoc-pdf:latest
```

---

### Option B: Without Docker

**1. Install dependencies**

- [Pandoc](https://pandoc.org/installing.html) >= 3.0
- [Typst](https://github.com/typst/typst/releases) (add to `PATH`)
- Fonts: Liberation Sans, Liberation Mono, Noto Emoji

**2. Run a conversion**

```bash
export TEMPLATE_DIR="$(pwd)/typst"
export DOCUMENT_DIR=/path/to/your/documents
export RELEASE=draft

bash build.sh
```

PDFs are written to `build/` relative to `DOCUMENT_DIR`.

**Convert a single file manually**

```bash
pandoc my-document.md \
  --from markdown+emoji \
  --to typst \
  --template typst/template.typ \
  --toc \
  --number-sections \
  --lua-filter typst/fix-internal-links.lua \
  --lua-filter typst/strip-toc-marker.lua \
  --lua-filter typst/table-columns.lua \
  --lua-filter typst/fix-typst-escaping.lua \
  --resource-path "typst:$(dirname my-document.md)" \
  --metadata "release-tag=draft" \
  --metadata "body-font=Liberation Sans" \
  --metadata "code-font=Liberation Mono" \
  --output my-document.pdf
```

---

## Document format

Each Markdown file must include a YAML front matter block:

```yaml
---
project-id: " "
template-title: Requirement Specification
template-identifier: FB_2.2_02
template-version: 4
template-author: V. Mustermann
template-creation-date: 2024-01-15
template-reviewer: A. Reviewer
template-review-date: 2024-01-20
template-approver: B. Approver
template-approval-date: 2024-01-25
---

# Section 1
...
```

See `testdocs/FB_2.2_02_Requirement-Specification.md` for a full example.

**Supported Markdown features**

- Tables, images, code blocks, numbered/bulleted lists
- Image sizing: `![alt](path){width=600px}`
- Emoji shortcodes: `:check-mark-button:`, `:warning:`, etc.
- Internal anchor links
- `[TOC]` marker (stripped automatically; TOC is generated from the template)

---

## GitHub Actions usage

This repository is also a GitHub Action. Add it to a workflow:

```yaml
- name: Generate PDFs
  uses: steadysense/pandoc-pdf@main
  with:
    document_directory: ./QM-Documents
    release_tag: ${{ github.ref_name }}
    doc_id: 'FB\|PB\|DA\|AA\|QMH'
```

PDFs are placed in `./QM-Documents/build/`.

**Action inputs**

| Input                | Required | Default               | Description                                    |
|----------------------|----------|-----------------------|------------------------------------------------|
| `document_directory` | yes      |                       | Directory containing the Markdown files        |
| `template_directory` | no       | bundled `/typst`      | Override the bundled Typst templates           |
| `release_tag`        | no       | `draft`               | Release tag shown in the PDF header            |
| `doc_id`             | no       | `FB\|PB\|DA\|AA\|QMH` | Regex pattern to filter which files to convert |

---

## Repository structure

```
pandoc-pdf/
├── typst/                    # Typst template and Lua filters (bundled in Docker image)
│   ├── template.typ          # Main document template
│   ├── steadylogo.pdf        # Logo used in the header
│   ├── fix-internal-links.lua
│   ├── strip-toc-marker.lua
│   ├── table-columns.lua
│   └── fix-typst-escaping.lua
├── build.sh                  # Conversion script (called inside Docker or directly)
├── entrypoint.sh             # Docker entrypoint (maps action inputs to env vars)
├── Dockerfile                # Docker image definition
├── action.yml                # GitHub Action definition
└── testdocs/                 # Example QM documents
```
