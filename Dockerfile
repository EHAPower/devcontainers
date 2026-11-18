# Copyright The devcontainers Contributors

# 官方镜像提供对应目标架构的 Node、uv 和 Docker CLI，版本跟随上游发布通道。
FROM node:current AS node
FROM ghcr.io/astral-sh/uv:latest AS uv
FROM docker:cli AS docker

# Verimag 只发布 x86_64 Linux 二进制；两个平台均从同一份源码编译 lv6。
FROM ubuntu:latest AS lustre-tools
ARG TARGETARCH
WORKDIR /tmp
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential ca-certificates curl git libffi-dev m4 ocaml opam pkg-config unzip
RUN opam init --yes --disable-sandboxing --compiler=ocaml-system && \
    opam pin add --yes --no-action lutils.1.56.0 https://www-verimag.imag.fr/DIST-TOOLS/SYNCHRONE/pool/lutils.v1.56.0.tgz && \
    opam pin add --yes --no-action rdbg.1.200.11 https://www-verimag.imag.fr/DIST-TOOLS/SYNCHRONE/pool/rdbg.v1.200.11.tgz
RUN set -eu; \
    src=https://www-verimag.imag.fr/DIST-TOOLS/SYNCHRONE/pool/lustre-v6.v6.113.0.tgz; \
    curl -fsSL --retry 3 "$src" -o lv6.tgz; \
    tar -xzf lv6.tgz; \
    cd lustre-v6.v6.113.0; \
    opam install --yes --deps-only ./lustre-v6.opam; \
    opam exec -- dune build bin/lv6/main.exe; \
    install -D _build/default/bin/lv6/main.exe /out/bin/lv6; \
    install -Dm644 LICENSE /out/share/doc/lv6/LICENSE; \
    echo "$src" > /out/share/doc/lv6/source

# Kind 2 使用对应架构的 v3.0.0 发布包。
RUN set -eu; \
    case "$TARGETARCH" in \
        amd64) arch=x86_64 ;; \
        arm64) arch=arm64 ;; \
        *) exit 1 ;; \
    esac; \
    curl -fsSL --retry 3 "https://github.com/kind2-mc/kind2/releases/download/v3.0.0/kind2-v3.0.0-linux-$arch.tar.gz" -o kind2.tgz; \
    tar -xzf kind2.tgz kind2; \
    install kind2 /out/bin/kind2; \
    mkdir -p /out/share/doc/kind2; \
    curl -fsSL --retry 3 https://raw.githubusercontent.com/kind2-mc/kind2/v3.0.0/LICENSE.rst -o /out/share/doc/kind2/LICENSE.rst

FROM ubuntu:latest

LABEL org.opencontainers.image.source="https://github.com/EHAPower/devcontainers" \
    org.opencontainers.image.description="EHAPower development toolbox" \
    org.opencontainers.image.licenses="MIT"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG DEBIAN_FRONTEND=noninteractive

ENV SHELL=/usr/bin/zsh \
    EDITOR=vim \
    VISUAL=vim \
    RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    UV_PYTHON_INSTALL_DIR=/opt/python \
    UV_PYTHON_BIN_DIR=/usr/local/bin \
    UV_TOOL_DIR=/opt/uv-tools \
    UV_TOOL_BIN_DIR=/usr/local/bin \
    PLANTUML_JAR=/opt/plantuml.jar \
    PATH=/usr/local/cargo/bin:/root/.local/bin:${PATH}

# Ubuntu 的当前仓库提供 C/C++、交叉编译、诊断和图形渲染所需的系统库。
# 每次构建更新系统包；语言工具链与扩展由下方各自的安装器维护。
# 清单依次按引导、原生构建、交叉编译、设备诊断、终端排障、文档渲染和交互终端排列。
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        wget \
        git \
        git-lfs \
        gh \
        openssh-client \
        gnupg \
        locales \
        language-pack-zh-hans \
        build-essential \
        cmake \
        ninja-build \
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
        gcc-riscv64-unknown-elf \
        binutils-riscv64-unknown-elf \
        picolibc-riscv64-unknown-elf \
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
        jq \
        yq \
        shellcheck \
        shfmt \
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
        lazygit \
        bat \
        eza \
        fd-find \
        fzf \
        just \
        ripgrep \
        zoxide \
        vim && \
    sed -i -e '/en_US.UTF-8/s/^# //g' \
        -e '/zh_CN.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen && \
    usermod --shell /usr/bin/zsh root && \
    rm -rf /var/lib/apt/lists/*

# 默认英文 UTF-8；可通过 LANG=zh_CN.UTF-8 切换到简体中文。
ENV LANG=en_US.UTF-8

# 直接复用官方发布的多架构二进制，避免在基础镜像内重建 Node、uv 或 Docker CLI。
COPY --from=node /usr/local/ /usr/local/
COPY --from=uv /uv /uvx /usr/local/bin/
COPY --from=docker /usr/local/bin/docker /usr/local/bin/docker
COPY --from=docker /usr/local/libexec/docker/cli-plugins/ /usr/local/libexec/docker/cli-plugins/

# Rust 跟随 stable；预装 STM32H7 和 Linux AArch64 目标及常用开发组件。
RUN curl --proto '=https' --tlsv1.2 -fsSL https://sh.rustup.rs | \
    sh -s -- -y --no-modify-path --profile minimal --default-toolchain stable \
        --component clippy,rustfmt,rust-src,rust-analyzer,llvm-tools-preview \
        --target thumbv7em-none-eabihf,aarch64-unknown-linux-gnu && \
    cargo install --locked cargo-edit cargo-expand cargo-binutils probe-rs-tools

# 默认 Python 与 pip 使用预置虚拟环境；各项目仍可用 uv 创建自己的隔离环境。
RUN uv python install --default && \
    uv venv --python /usr/local/bin/python --seed /opt/python-env && \
    uv pip install --python /opt/python-env/bin/python PyYAML==6.0.3 Jinja2==3.1.6 z3-solver==5.4.1.0 && \
    uv tool install pre-commit && \
    uv tool install ruff

ENV PATH=/opt/python-env/bin:${PATH}

COPY --from=lustre-tools /out/ /usr/local/

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
COPY zshrc /root/.zshrc

# 镜像只提供工作区安全目录和 LFS 支持；身份、提交模板和工作流由各仓库决定。
RUN git config --system --add safe.directory /workspace && \
    git lfs install --system && \
    uv cache clean && \
    rm -rf /root/.cache /tmp/*

WORKDIR /workspace
CMD ["/usr/bin/zsh"]
