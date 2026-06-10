FROM pandoc/core:latest

# Install Typst (musl build for Alpine), fonts and utilities
RUN apk add --no-cache bash curl xz font-liberation ttf-dejavu font-noto-emoji fontconfig && \
    curl -L "https://github.com/typst/typst/releases/latest/download/typst-x86_64-unknown-linux-musl.tar.xz" \
    | tar -xJ --strip-components=1 -C /usr/local/bin && \
    fc-cache -f

# Bundle template files
COPY typst/template.typ           /typst/template.typ
COPY typst/steadylogo.pdf         /typst/steadylogo.pdf
COPY typst/strip-toc-marker.lua   /typst/strip-toc-marker.lua
COPY typst/fix-internal-links.lua /typst/fix-internal-links.lua
COPY typst/table-columns.lua      /typst/table-columns.lua
COPY typst/fix-typst-escaping.lua /typst/fix-typst-escaping.lua

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY build.sh      /usr/local/bin/build.sh
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/build.sh

RUN mkdir -p /github/workspace
WORKDIR /github/workspace

ENTRYPOINT ["entrypoint.sh"]
CMD ["build.sh"]
