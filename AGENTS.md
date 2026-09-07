# AGENTS.md

本仓库维护 EHAPower 共享开发基础镜像，工具安装在 Dockerfile 和 config/ 中维护。

- 先读 README.md，保留工作区中的无关修改。
- 使用默认 root 和 zsh；采用最新稳定工具，不固定版本。
- 根据实际开发习惯预装工具，项目依赖留在派生仓库。
- 验收只要求 Docker 构建成功，不添加测试或运行时自检。
- 不写入个人身份、机器路径、凭据或会话记录。
- 修改工具或默认配置时同步 README.md。
- 提交用中文 Conventional Commits、DCO signoff 和 Codex co-author。
