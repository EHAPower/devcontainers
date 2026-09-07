FROM node:current AS node
FROM ghcr.io/astral-sh/uv:latest AS uv
FROM docker:cli AS docker
FROM ubuntu:latest

LABEL org.opencontainers.image.source="https://github.com/EHAPower/devcontainers" \
    org.opencontainers.image.description="EHAPower development toolbox" \
    org.opencontainers.image.licenses="MIT"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ARG DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 \
    SHELL=/usr/bin/zsh EDITOR=nvim VISUAL=nvim \
    RUSTUP_HOME=/usr/local/rustup CARGO_HOME=/usr/local/cargo \
    MISE_DATA_DIR=/opt/mise \
    UV_PYTHON_INSTALL_DIR=/opt/python UV_PYTHON_BIN_DIR=/usr/local/bin \
    UV_TOOL_DIR=/opt/uv-tools UV_TOOL_BIN_DIR=/usr/local/bin \
    PLANTUML_JAR=/opt/plantuml.jar \
    PATH=/opt/mise/shims:/usr/local/cargo/bin:/root/.local/bin:${PATH}

# 系统依赖从当前 Ubuntu 软件源更新，不锁定包版本。
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
      ca-certificates curl wget git openssh-client gnupg locales \
      build-essential clang clang-format clang-tidy lld llvm libclang-dev \
      pkg-config autoconf automake libtool libssl-dev libudev-dev libusb-1.0-0-dev \
      gcc-aarch64-linux-gnu g++-aarch64-linux-gnu libc6-dev-arm64-cross \
      gcc-arm-none-eabi binutils-arm-none-eabi libnewlib-arm-none-eabi \
      gdb-multiarch openocd dfu-util can-utils \
      zsh tmux vim less tree htop file lsof strace rsync zip unzip xz-utils \
      iproute2 iputils-ping dnsutils net-tools netcat-openbsd socat usbutils \
      graphviz default-jre-headless poppler-utils fonts-noto-cjk \
      libnss3 libatk-bridge2.0-0 libxkbcommon0 libgbm1 libasound2t64 && \
    sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen && \
    usermod --shell /usr/bin/zsh root && \
    rm -rf /var/lib/apt/lists/*

COPY --from=node /usr/local/ /usr/local/
COPY --from=uv /uv /uvx /usr/local/bin/
COPY --from=docker /usr/local/bin/docker /usr/local/bin/docker
COPY --from=docker /usr/local/libexec/docker/cli-plugins/ /usr/local/libexec/docker/cli-plugins/

# 独立 CLI 使用上游最新稳定发行版，由 mise 处理架构和下载。
COPY config/mise.toml /etc/mise/config.toml
RUN curl -fsSL https://mise.run | MISE_INSTALL_PATH=/usr/local/bin/mise sh && \
    mise install --yes

RUN curl --proto '=https' --tlsv1.2 -fsSL https://sh.rustup.rs | \
    sh -s -- -y --no-modify-path --profile minimal --default-toolchain stable \
      --component clippy,rustfmt,rust-src,rust-analyzer,llvm-tools-preview \
      --target thumbv7em-none-eabihf,aarch64-unknown-linux-gnu && \
    cargo binstall --no-confirm cargo-edit cargo-expand cargo-binutils probe-rs-tools

# Python CLI 各自隔离，项目可直接使用 uv venv / uv sync。
RUN uv python install --default && \
    uv pip install --python /usr/local/bin/python --upgrade pip setuptools wheel && \
    printf '#!/bin/sh\nexec python -m pip "$@"\n' > /usr/local/bin/pip && \
    chmod +x /usr/local/bin/pip && ln -s pip /usr/local/bin/pip3 && \
    uv tool install pre-commit && uv tool install ruff

RUN npm install -g npm@latest && hash -r && \
    npm install -g pnpm@latest @devcontainers/cli@latest \
      @mermaid-js/mermaid-cli@latest npm-check-updates@latest @openai/codex@latest && \
    npm cache clean --force

RUN curl -fL https://github.com/plantuml/plantuml/releases/latest/download/plantuml.jar \
      -o /opt/plantuml.jar && \
    printf '#!/bin/sh\nexec java -jar /opt/plantuml.jar "$@"\n' > /usr/local/bin/plantuml && \
    chmod +x /usr/local/bin/plantuml

RUN git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git /opt/oh-my-zsh && \
    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git \
      /opt/oh-my-zsh/custom/plugins/zsh-autosuggestions && \
    git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git \
      /opt/oh-my-zsh/custom/plugins/zsh-syntax-highlighting
COPY config/zshrc /root/.zshrc

RUN git config --system --add safe.directory /workspace && \
    git lfs install --system && \
    uv cache clean && rm -rf /root/.cache /tmp/*

WORKDIR /workspace
CMD ["/usr/bin/zsh"]
