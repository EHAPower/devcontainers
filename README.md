# devcontainers

EHAPower 的共享开发基础镜像。预装工具参考 eha_controller、ranger、ranger-monitor 的技术栈，以及日常 Mac 开发环境。

```dockerfile
FROM ghcr.io/ehapower/devcontainers:latest
# 在这里安装项目自己的依赖。
```

默认用户为 `root`，默认 shell 为 zsh，工作目录为 `/workspace`。无需创建用户或配置 sudo。旧项目若设置了 `USER dev` 或 `remoteUser: dev`，切换镜像时删除该设置。

## 预装工具

| 用途 | 工具 |
|---|---|
| Rust | stable、Cargo、Clippy、rustfmt、rust-src、rust-analyzer、LLVM tools、cargo-binstall、cargo-edit、cargo-expand、cargo-binutils、probe-rs |
| C/C++ | GCC/G++、Clang、clang-format、clang-tidy、LLVM/LLD、CMake、Ninja、Make、pkg-config、Autotools |
| 交叉编译与硬件 | ARM bare-metal 与 AArch64 GNU 工具链、GDB multiarch、OpenOCD、dfu-util、can-utils；Rust 的 `thumbv7em-none-eabihf` 和 `aarch64-unknown-linux-gnu` target |
| Python | 最新稳定 Python、uv/uvx、pip、venv、pre-commit、Ruff |
| Node.js | current、npm、pnpm、npm-check-updates、Codex CLI |
| Git 与终端 | Git、Git LFS、gh、lazygit、OpenSSH、zsh、tmux、neovim、vim、fzf、fd、ripgrep、bat、eza、zoxide、just |
| 数据与排障 | jq、yq、ShellCheck、shfmt、curl、wget、rsync、tree、htop、file、lsof、strace、iproute2、ping、DNS tools、netcat、socat、USB tools |
| 文档与容器 | Graphviz、Java、PlantUML、Mermaid CLI、Poppler、中文字体、Docker CLI、Buildx、Compose、Dev Container CLI |

默认 Python 与 pip 使用同一个预置虚拟环境。项目可用 `uv venv` / `uv sync`；全局 Python CLI 各有独立环境。Docker CLI 连接外部 Docker daemon，项目按需配置连接和设备访问。

## 终端与 Git

zsh 使用 Oh My Zsh 的 `robbyrussell` 主题，启用 Git/fzf 插件、自动建议、语法高亮和历史去重。`Ctrl-R` 搜历史，`Ctrl-T` 找文件，`Alt-C` 选目录；`z` 跳常用目录，`ll` 列文件，`lt` 看目录树，`lg` 打开 lazygit。编辑器默认 neovim。

镜像只配置 Git LFS 和 `safe.directory=/workspace`。忽略项、文件属性、提交模板属于各仓库；镜像不设置身份和提交规则。

本仓库的 `.gitattributes`、`.gitignore`、`.gitmessage` 参考 eha_controller 并精简。维护本仓库时，可启用中文提交模板：

```bash
git config --local commit.template .gitmessage
```

## 构建与更新

```bash
docker build --pull --no-cache -t devcontainers:local .
```

验收只要求构建成功。修改 Dockerfile 或 config/ 后，推送 main 会在原生 amd64/arm64 runner 并行构建，两者成功后发布多架构镜像；PR 只构建。每周一 03:00 UTC 自动更新，也可手动触发。

基础系统跟随 `ubuntu:latest`，Node.js 跟随 `node:current`，Rust 跟随 stable，uv 安装最新稳定 Python。独立 CLI 由 [mise](https://mise.jdx.dev/) 从上游获取 `latest`，npm/Python CLI 和 PlantUML 使用最新发行版，zsh 插件跟随上游。系统库、编译器和硬件工具使用当前 Ubuntu 软件源的最新包版本，可能晚于上游源码发行。构建使用 `--pull --no-cache`，确保重新解析更新。

镜像发布到 `ghcr.io/ehapower/devcontainers`，提供 `latest` 和 `build-<run_id>-<run_attempt>` 标签；需要重现或回退时使用对应 digest。可选构建日志保存在仓库 `build/` 中。
