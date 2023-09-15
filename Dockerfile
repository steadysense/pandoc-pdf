FROM pandoc/latex:2.14

RUN wget -q -P /usr/share/fonts/ https://github.com/samuelngs/apple-emoji-linux/releases/latest/download/AppleColorEmoji.ttf
RUN apk add texmf-dist python3 py3-pip bash fontconfig ttf-dejavu msttcorefonts-installer && update-ms-fonts && fc-cache -f

COPY ./requirements.txt /
COPY ./texpkgs.txt /

RUN pip3 install -r /requirements.txt

RUN tlmgr install $(cat /texpkgs.txt)

RUN apk add parallel

RUN mkdir -p /github/workspace
WORKDIR /github/workspace

# Copies your code file from your action repository to the filesystem path `/` of the container
COPY entrypoint.sh /usr/local/bin/
COPY build.sh /usr/local/bin/
COPY pandoc_filter /usr/local/bin/

# Code file to execute when the docker container starts up (`entrypoint.sh`)
#ENTRYPOINT ["/entrypoint.sh"]
ENTRYPOINT ["entrypoint.sh"]
#CMD ["/build.sh"]
CMD build.sh