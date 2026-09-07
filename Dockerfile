# Copyright The devcontainers Contributors

# 官方镜像提供对应目标架构的 Node、uv 和 Docker CLI，版本跟随上游发布通道。
FROM node:current AS node
FROM ghcr.io/astral-sh/uv:latest AS uv
FROM docker:cli AS docker
FROM ubuntu:latest

LABEL org.opencontainers.image.source="https://github.com/EHAPower/devcontainers" \
    org.opencontainers.image.description="EHAPower development toolbox" \
    org.opencontainers.image.licenses="MIT"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG DEBIAN_FRONTEND=noninteractive

ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    SHELL=/usr/bin/zsh \
    EDITOR=nvim \
    VISUAL=nvim \
    RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    MISE_DATA_DIR=/opt/mise \
    UV_PYTHON_INSTALL_DIR=/opt/python \
    UV_PYTHON_BIN_DIR=/usr/local/bin \
    UV_TOOL_DIR=/opt/uv-tools \
    UV_TOOL_BIN_DIR=/usr/local/bin \
    PLANTUML_JAR=/opt/plantuml.jar \
    PATH=/opt/mise/shims:/usr/local/cargo/bin:/root/.local/bin:${PATH}

# Ubuntu 的当前仓库提供 C/C++、交叉编译、诊断和图形渲染所需的系统库。
# 每次构建更新系统包；语言和独立 CLI 则由下方各自的上游安装器保持最新。
# 清单依次按引导、原生构建、交叉编译、设备诊断、终端排障、文档渲染和交互终端排列。
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        wget \
        git \
        openssh-client \
        gnupg \
        locales \
        build-essential \
        clang \
        clang-format \
        clang-tidy \
        lld \
        llvm \
        libclang-dev \
        pkg-config \
        autoconf \
        automake \
        libtool \
        libssl-dev \
        libudev-dev \
        libusb-1.0-0-dev \
        gcc-aarch64-linux-gnu \
        g++-aarch64-linux-gnu \
        libc6-dev-arm64-cross \
        gcc-arm-none-eabi \
        binutils-arm-none-eabi \
        libnewlib-arm-none-eabi \
        gdb-multiarch \
        openocd \
        dfu-util \
        can-utils \
        iproute2 \
        iputils-ping \
        dnsutils \
        net-tools \
        netcat-openbsd \
        socat \
        usbutils \
        file \
        lsof \
        strace \
        rsync \
        zip \
        unzip \
        xz-utils \
        less \
        tree \
        htop \
        graphviz \
        default-jre-headless \
        poppler-utils \
        fonts-noto-cjk \
        libnss3 \
        libatk-bridge2.0-0 \
        libxkbcommon0 \
        libgbm1 \
        libasound2t64 \
        zsh \
        tmux \
        vim && \
    sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen && \
    usermod --shell /usr/bin/zsh root && \
    rm -rf /var/lib/apt/lists/*

# 直接复用官方发布的多架构二进制，避免在基础镜像内重建 Node、uv 或 Docker CLI。
COPY --from=node /usr/local/ /usr/local/
COPY --from=uv /uv /uvx /usr/local/bin/
COPY --from=docker /usr/local/bin/docker /usr/local/bin/docker
COPY --from=docker /usr/local/libexec/docker/cli-plugins/ /usr/local/libexec/docker/cli-plugins/

# mise 统一安装与系统包不同步的常用 CLI，并按目标架构解析上游最新发行版。
COPY config/mise.toml /etc/mise/config.toml
RUN curl -fsSL https://mise.run | MISE_INSTALL_PATH=/usr/local/bin/mise sh && \
    mise install --yes

# Rust 跟随 stable；预装 STM32H7 和 Linux AArch64 目标及常用开发组件。
RUN curl --proto '=https' --tlsv1.2 -fsSL https://sh.rustup.rs | \
    sh -s -- -y --no-modify-path --profile minimal --default-toolchain stable \
        --component clippy,rustfmt,rust-src,rust-analyzer,llvm-tools-preview \
        --target thumbv7em-none-eabihf,aarch64-unknown-linux-gnu && \
    cargo binstall --no-confirm cargo-edit cargo-expand cargo-binutils probe-rs-tools

# 默认 Python 与 pip 使用预置虚拟环境；各项目仍可用 uv 创建自己的隔离环境。
RUN uv python install --default && \
    uv venv --python /usr/local/bin/python --seed /opt/python-env && \
    uv tool install pre-commit && \
    uv tool install ruff

ENV PATH=/opt/python-env/bin:${PATH}

# Node 用于 Web 工具、Dev Container 和文档渲染，均在镜像构建时取最新稳定版。
RUN npm install -g npm@latest && \
    hash -r && \
    npm install -g \
        pnpm@latest \
        @devcontainers/cli@latest \
        @mermaid-js/mermaid-cli@latest \
        npm-check-updates@latest \
        @openai/codex@latest && \
    npm cache clean --force

# 文档图工具保留官方 PlantUML 发布物，并以轻量包装器提供稳定命令名。
RUN curl -fL https://github.com/plantuml/plantuml/releases/latest/download/plantuml.jar \
        -o /opt/plantuml.jar && \
    printf '#!/bin/sh\nexec java -jar /opt/plantuml.jar "$@"\n' > /usr/local/bin/plantuml && \
    chmod +x /usr/local/bin/plantuml

# 沿用 Ubuntu 默认 root 用户，配置熟悉的 Oh My Zsh 主题、补全和语法高亮。
RUN git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git /opt/oh-my-zsh && \
    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git \
        /opt/oh-my-zsh/custom/plugins/zsh-autosuggestions && \
    git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git \
        /opt/oh-my-zsh/custom/plugins/zsh-syntax-highlighting
COPY config/zshrc /root/.zshrc

# 镜像只提供工作区安全目录和 LFS 支持；身份、提交模板和工作流由各仓库决定。
RUN git config --system --add safe.directory /workspace && \
    git lfs install --system && \
    uv cache clean && \
    rm -rf /root/.cache /tmp/*

WORKDIR /workspace
CMD ["/usr/bin/zsh"]
