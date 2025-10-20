FROM lsiobase/kasmvnc:ubuntunoble

# Set the commit ID for version tracking
ARG commit_id=dev
ENV COMMIT_ID=${commit_id}

# Install dependencies (fix openbox autostart error by installing python3-pyxdg)
RUN apt-get update && \
    apt-get install -y \
        anki \
        wget \
        zstd \
        xdg-utils \
        libxcb-xinerama0 \
        libxcb-cursor0 \
        python3-xdg \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ARG ANKI_VERSION=25.09

# Download, Extract, and Install Anki
RUN dpkg --remove anki && \
  wget https://github.com/ankitects/anki/releases/download/${ANKI_VERSION}/anki-launcher-${ANKI_VERSION}-linux.tar.zst && \
  tar --use-compress-program=unzstd -xvf anki-launcher-${ANKI_VERSION}-linux.tar.zst && \
  cd anki-launcher-${ANKI_VERSION}-linux && ./install.sh &&  cd .. && \
  rm -rf anki-launcher-${ANKI_VERSION}-linux anki-launcher-${ANKI_VERSION}-linux.tar.zst

RUN apt-get update && \
    apt-get install -y \
        language-pack-zh-hans \
        fonts-noto-cjk \
		mplayer \
		mplayer-gui \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create a config directory to be mounted
RUN mkdir -p /config/.local/share

COPY ./root /

EXPOSE 3000 8765
