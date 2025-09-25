# pandoc-pdf Action

This action converts markdown files to pdf files using pandoc.

## Inputs

### `template-volume`

**Required** The directory containing the latex templates.

### `document-volume`
**Required** The directory containing the markdown files to convert.


## Example usage
```
uses: actions/pandoc-pdf@v1
with:
  template-volume: '/QM-documents'
  document-volume: '/00_Working_Documents'
```


# Local usage of pandoc-pdf converter

Pull docker image from github package registry:
```
docker pull ghcr.io/steadysense/pandoc-pdf/pandoc-pdf:latest
```
Convert markdown files:
```
docker run -it  \
  -v "$PATH-OUTPUT-DIRECTORY:/github/workspace" \
  -v "$PATH-TEMPLATE-DIRECTORY:/github/workspace/templates" \
  -v "$PATH-DOCUMENT-DIRECTORY:/github/workspace/documents" \
  --env INPUT_DOCUMENT_DIRECTORY="documents/" \
  --env INPUT_TEMPLATE_DIRECTORY="templates/QM-documents/" \
  --env DOC_ID="FB|PB|DA|QMH|" \
  steadysense/pdfgen:latest
```
with

`$PATH-OUTPUT-DIRECTORY`: directory where the pdf output files are stored in a `/build` folder

`$PATH-TEMPLATE-DIRECTORY`: directory containing the latex template files

`$PATH-DOCUMENT-DIRECTORY`: directory containing the markdown files to convert

