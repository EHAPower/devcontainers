# devcontainers

为 EHAPower 项目提供预装常用工具的基础开发镜像。共享工具在本仓库维护，项目专用依赖在各项目的 Dockerfile 中追加。

```dockerfile
FROM ghcr.io/ehapower/devcontainers:latest
```

## 预装工具

基础系统为 Ubuntu 26.04。构建时更新系统包，Rust 跟随 stable，Node.js 跟随官方 `node:current` 镜像，Python/npm 全局工具和 PlantUML 跟随当前版本。

| 用途 | 工具 |
|---|---|
| Rust | rustup、rustc、Cargo、Clippy、rustfmt、llvm-tools-preview |
| C/C++ 与 FFI | GCC/G++、Clang、LLVM、LLD、CMake、Ninja、Make、pkg-config、libclang、OpenSSL 开发库 |
| Python | Python 3、pip、venv、独立环境中的 pre-commit |
| Node.js | 官方 current Node.js、npm@latest、npm-check-updates |
| 文档 | Graphviz、Java、PlantUML、Mermaid CLI |
| 容器协作 | Dev Container CLI |
| Git 与远程访问 | Git、Git LFS、GitHub CLI、OpenSSH client |
| Shell 与排障 | zsh、vim、ripgrep、fd、bat、jq、tree、htop、less、curl、wget、unzip |

镜像提供 `dev` 用户、zsh 和免密码 sudo。镜像默认仍以 root 执行，便于派生 Dockerfile 安装系统包；Dev Container 使用 `remoteUser: dev`。默认工作区为 `/workspace`。

## 派生项目

项目保留自己的 `.devcontainer/Dockerfile`，例如：

```dockerfile
FROM ghcr.io/ehapower/devcontainers:latest

# 在这里追加项目专用依赖。
RUN rustup target add thumbv7em-none-eabihf
```

项目自己的 `devcontainer.json` 声明工作区、用户、容器名称及设备访问。H723、AArch64、CAN、数据库、模拟器等专用需求由派生项目维护。

私有 GHCR package 需要给消费仓库授予 package 的 Actions Read 权限；消费仓库 workflow 声明 `packages: read` 并登录 GHCR。开发者通过 `docker login ghcr.io` 配置拉取凭据，凭据不写入仓库。

## 构建与发布

验收只要求镜像构建成功，不添加测试或运行时自检。

宿主机安装 Docker 后，在仓库根目录构建本机架构镜像：

```bash
docker build --pull --progress=plain -t devcontainers:local .
```

`.github/workflows/build.yml` 构建 `linux/amd64` 与 `linux/arm64`：

- PR：只构建，不登录 GHCR、不发布。
- main 上的 Dockerfile、构建上下文规则或 workflow 变更：构建并发布。
- 每周一 03:00 UTC：重新构建并发布，以更新工具和系统包。
- 手动运行：main 上构建并发布，其他分支只构建。

发布地址：`ghcr.io/ehapower/devcontainers`。每次发布提供 `latest` 和 `build-<run_id>-<run_attempt>` 标签，并记录源码 commit。默认消费 `latest`；需要重现某次环境时使用对应镜像 digest。

镜像产物保存在本地 Docker image store 或 GHCR。需要保存本地构建日志时，写入宿主机仓库的 `build/`（开发容器内对应 `/workspace/build/`），不提交 Git。

## 维护本仓库

| 用途 | 名称 |
|---|---|
| 发布基础镜像 | `ghcr.io/ehapower/devcontainers:latest` |
| 本地镜像 | `devcontainers:local` |
| Dev Container 显示名 | `devcontainers` |
| 常驻开发容器 | `devcontainers-devcontainer-{username}-{branch}` |

本仓库的 `.devcontainer/devcontainer.json` 直接构建根目录 Dockerfile。打开 Dev Container 前，在宿主 shell 中设置容器名称：

```bash
DEVCONTAINER_USER="$(id -un | sed -E 's/[^[:alnum:]_.-]+/-/g; s/^-+//; s/-+$//')"
DEVCONTAINER_BRANCH="$(git branch --show-current | sed -E 's/[^[:alnum:]_.-]+/-/g; s/^-+//; s/-+$//')"
if [ -z "$DEVCONTAINER_BRANCH" ]; then echo "请先切换到具名 Git 分支" >&2; exit 1; fi
export DEVCONTAINER_NAME="devcontainers-devcontainer-${DEVCONTAINER_USER}-${DEVCONTAINER_BRANCH}"
```

也可在完成镜像构建后，通过 Docker 创建并复用常驻容器：

```bash
docker inspect "$DEVCONTAINER_NAME" >/dev/null 2>&1 || docker run -d --name "$DEVCONTAINER_NAME" --mount "type=bind,src=$PWD,dst=/workspace" -w /workspace devcontainers:local sleep infinity
docker start "$DEVCONTAINER_NAME"
docker exec -it -u dev "$DEVCONTAINER_NAME" zsh
```

## 来源与迁移

初始 Dockerfile 来自 `EHAPower/project_template` 的 `.devcontainer/base.Dockerfile`，基线为 `e3eff71929d32a778a13f8a06bf3beae6aa35267`，保留原 MIT 许可和版权说明。

本仓库独立维护新镜像地址。`ghcr.io/ehapower/project_template/devcontainer` 的现有发布及各派生项目引用保持原状，项目可以在需要时切换到新地址。
