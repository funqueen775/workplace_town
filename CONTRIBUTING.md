# 协作开发

## 首次配置

1. 安装 Git LFS、Godot 4.7.x 和 Python 3.10+。
2. 克隆仓库后运行 `git lfs install` 和 `git lfs pull`，下载鸿蒙工程使用的 Godot Web 导出文件。
3. 复制 `backend/local_llm_config.example.json` 为 `backend/local_llm_config.json`，在本机填写自己的 API 配置。真实密钥不得提交、截图或放进共享压缩包。
4. Windows 下双击 `Start-Game.cmd` 启动游戏和本机 API。

## 提交规范

- 从最新 `main` 创建 `feature/简短名称`、`fix/简短名称` 或 `docs/简短名称` 分支，通过 Pull Request 合并；不要直接向 `main` 推送。
- 保留项目运行所需的美术源文件、剧情数据和 Godot `.import` 元数据；不要提交本机数据库、`.godot/` 缓存、测试截图、部署副本或压缩包。
- 修改 API 时同步更新 `contracts/openapi.yaml` 和相关 fixture；修改评分或剧情时运行相邻的后端/Godot 测试。
- 提交前检查 `git status`、确认没有真实密钥，并检查变更是否意外删除仍被场景或脚本引用的资源。

后端基础自测：`python backend/api/selftest.py`。
