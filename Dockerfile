# Copyright The Project Template Contributors
# Copyright The Devcontainers Contributors

FROM node:current AS node

FROM ubuntu:26.04

LABEL org.opencontainers.image.source="https://github.com/EHAPower/devcontainers" \
    org.opencontainers.image.description="Shared development base image for EHAPower projects" \
    org.opencontainers.image.licenses="MIT"

ARG DEBIAN_FRONTEND=noninteractive

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PLANTUML_JAR=/opt/plantuml/plantuml.jar \
    CARGO_TERM_COLOR=always \
    PATH=/usr/local/cargo/bin:${PATH}

# System packages:
# - bootstrap/runtime helpers
# - source control and SSH
# - native build and FFI tooling
# - shell, editor, search, JSON, and documentation utilities
# - Python runtime used by pre-commit and helper scripts
RUN set -eux; \
    apt-get update; \
    apt-get upgrade -y; \
    apt-get install --no-install-recommends --fix-missing -y \
        ca-certificates \
        curl \
        gnupg \
        sudo \
        unzip \
        wget \
        git \
        git-lfs \
        gh \
        openssh-client \
        build-essential \
        clang \
        cmake \
        lld \
        llvm \
        libclang-dev \
        libssl-dev \
        make \
        ninja-build \
        pkg-config \
        bat \
        fd-find \
        graphviz \
        htop \
        jq \
        less \
        locales \
        default-jre-headless \
        ripgrep \
        tree \
        vim \
        zsh \
        python3 \
        python3-pip \
        python3-venv \
        python-is-python3; \
    ln -sf /usr/bin/fdfind /usr/local/bin/fd; \
    ln -sf /usr/bin/batcat /usr/local/bin/bat; \
    sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen; \
    locale-gen; \
    apt-get autoremove -y; \
    apt-get clean -y; \
    rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    useradd --create-home --user-group --shell /usr/bin/zsh dev; \
    echo "dev ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/dev; \
    chmod 0440 /etc/sudoers.d/dev

# Keep pre-commit isolated from system Python packages.
RUN set -eux; \
    python3 -m venv /opt/pre-commit; \
    /opt/pre-commit/bin/pip install --no-cache-dir --upgrade \
        pip \
        pre-commit \
        setuptools \
        wheel; \
    ln -sf /opt/pre-commit/bin/pre-commit /usr/local/bin/pre-commit

# Install the latest upstream PlantUML jar with Java and Graphviz from apt.
RUN set -eux; \
    mkdir -p "$(dirname "${PLANTUML_JAR}")"; \
    curl --proto '=https' --tlsv1.2 -fsSL \
        -o "${PLANTUML_JAR}" \
        https://github.com/plantuml/plantuml/releases/latest/download/plantuml.jar; \
    printf '%s\n' \
        '#!/usr/bin/env sh' \
        "exec java -jar ${PLANTUML_JAR} \"\$@\"" \
        > /usr/local/bin/plantuml; \
    chmod 0755 /usr/local/bin/plantuml

# Use the official current Node.js runtime so npm@latest has a supported engine.
COPY --from=node /usr/local/ /usr/local/

# Shared npm tools for documentation, Dev Container workflows, and upgrades.
RUN set -eux; \
    npm install -g npm@latest; \
    hash -r; \
    npm install -g \
        @devcontainers/cli \
        @mermaid-js/mermaid-cli \
        npm-check-updates

# Rust stable and common Cargo tooling are shared across derived projects.
RUN set -eux; \
    curl --proto '=https' --tlsv1.2 -fsSL https://sh.rustup.rs \
        | sh -s -- -y \
        --profile minimal \
        --default-toolchain stable \
        --component clippy,rustfmt,llvm-tools-preview; \
    chmod -R a+w "${RUSTUP_HOME}" "${CARGO_HOME}"

# Remove download caches after installing shared tools.
RUN set -eux; \
    npm cache clean --force; \
    rm -rf /tmp/*

ENV SHELL=/usr/bin/zsh

WORKDIR /workspace
