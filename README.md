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
