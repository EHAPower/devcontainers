# devcontainers

EHAPower 的共享开发基础镜像。预装工具参考 eha_controller、ranger、ranger-monitor 的技术栈，以及日常 Mac 开发环境。

```dockerfile
FROM ghcr.io/ehapower/devcontainers:latest
# 在这里安装项目自己的依赖。
```

默认用户为 `root`，默认 shell 为 zsh，工作目录为 `/workspace`。

支持英文和简体中文 UTF-8 locale，预装简体中文语言包和 Noto CJK 字体。默认 `LANG=en_US.UTF-8`，设置 `LANG=zh_CN.UTF-8` 可切换中文界面。

PATH、Vim 编辑器及语言工具链环境变量统一由 Dockerfile 的 `ENV` 提供，zshrc 继承使用，无需重复 export。

## 预装工具

直接阅读 [Dockerfile](./Dockerfile)

## 构建与更新

```bash
docker build --pull --no-cache -t devcontainers:local .
```

验收只要求构建成功。

GitHub Actions 使用单个 job，通过 Buildx + QEMU 构建 amd64/arm64 多架构镜像。修改 Dockerfile 或 zshrc 后，推送 main 会构建并发布；PR 只构建。每周一 03:00 UTC 自动更新，也可手动触发，只有 main 发布镜像。

镜像发布到 `ghcr.io/ehapower/devcontainers`，只提供 `latest` 标签。可选构建日志保存在仓库 `build/` 中。
