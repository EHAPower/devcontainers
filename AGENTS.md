# AGENTS.md

本仓库维护 EHAPower 项目共享的基础开发镜像。各项目从该镜像派生，并在项目仓库维护专用依赖、设备访问、挂载和初始化命令。

- 首先阅读 README.md，核对分支、HEAD 和工作区状态，保留无关修改。
- 优先使用中文；命令、工具名、配置键和标识符保持英文。
- Dockerfile 是预装工具的唯一实现来源；工具清单变化时同步 README.md。
- 持续采用最新稳定工具，默认发布 latest。按开发习惯预装常用工具，不以缩小镜像为目标强行精简。
- 验收仅要求 Docker 镜像构建成功。不建立或运行测试、smoke、版本自检脚本等额外门禁。
- 宿主机承担 Git 和 Docker/Dev Container 编排；其他项目命令在常驻开发容器或 CI runner 中运行。构建日志写入仓库内 build/，不提交。
- 不提交凭据、机器本地路径或会话记录。镜像发布使用 GitHub Actions 的 GITHUB_TOKEN。
- 新仓库仅发布 ghcr.io/ehapower/devcontainers；不修改旧基础镜像或派生项目。
- 提交使用中文 Conventional Commits、Signed-off-by 和 Co-authored-by: OpenAI Codex <codex@openai.com>。
