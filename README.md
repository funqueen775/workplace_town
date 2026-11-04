# 熊心壮职 · 职场小镇

Godot 4 职场剧情体验游戏。玩家经历十二个月的工作与生活事件，探索八个部门、参与区域活动，并在流程结束后查看由本局选择和行为记录生成的职业画像报告。HarmonyOS 版本由 ArkTS 应用壳通过 ArkWeb 加载 Godot Web 导出内容；剧情、玩法与报告仍由 Godot 实现。

## 项目组成

| 路径 | 内容 |
|---|---|
| `Startup.tscn`、`Main.tscn` | 开场与小镇入口 |
| `scripts/`、`data/`、`assets/` | Godot 游戏逻辑、剧情数据和运行素材 |
| `backend/api/`、`backend/engine_core/` | 本地 API、NPC 对话、事件与评分服务 |
| `entry/`、`AppScope/`、`hvigor/` | HarmonyOS ArkTS 外壳和 DevEco 构建工程 |
| `entry/src/main/resources/rawfile/game/` | 打包到 HAP 的 Godot Web 游戏文件，属于运行资源，不是缓存 |
| `tests/`、`tools/` | 自动化测试和开发辅助工具 |

## 克隆与资源

仓库使用 Git LFS 保存较大的 Godot Web PCK。先安装 Git 与 Git LFS，再克隆项目：

```powershell
git lfs install
git clone https://github.com/funqueen775/workplace_town.git
cd workplace_town
git lfs pull
```

若 LFS 未安装或未拉取，`index.pck` 等文件可能显示为很小的指针文本，游戏和 HAP 都无法正常运行。

## Windows 本地运行

安装 Godot 4.7.x（建议使用与项目一致的 4.7.2）和 Python 3.10 或更新版本。后端仅使用 Python 标准库，不需要 `pip install`。

双击项目根目录的 `Start-Game.cmd`。启动脚本会检查 Godot 与本地 API，自动启动 API 服务，在游戏启动前执行一次 Godot headless 资源导入，再打开 `Startup.tscn`。首次启动需要等待 Godot 导入资源；导入结果写入本机 `.godot/`，之后启动会复用缓存。

如果 Godot 没有加入 PATH，在 PowerShell 中设置 `GODOT_EXE` 后再运行启动脚本：

```powershell
$env:GODOT_EXE = 'D:\Apps\Godot\Godot_v4.7.2-stable_win64.exe'
Start-Game.cmd
```

也可以在 Godot 编辑器中打开项目根目录。正常游玩时建议通过 `Start-Game.cmd` 启动，以便 API 服务同时运行。API 默认只监听本机 `127.0.0.1:8077`。

NPC 对话在没有模型密钥时使用本地预设回复，游戏和评分流程仍可运行。需要启用大模型 NPC 对话时，将 `backend/local_llm_config.example.json` 复制为 `backend/local_llm_config.json`，再填写自己的服务商、模型和 API Key。该文件已被忽略，不要提交密钥；不要把真实密钥放进 README、源码或截图。

## DevEco 真机调试

1. 安装 DevEco Studio 和 HarmonyOS SDK，使用 Git LFS 克隆并拉取完整资源。
2. 在 DevEco Studio 中打开项目根目录（包含 `build-profile.json5` 的 `workplace_town`），等待 Hvigor 同步完成。按本机 SDK 安装位置配置 SDK；`local.properties` 是机器配置，不提交。
3. 用 USB 连接 HarmonyOS 手机，在手机上开启开发者调试并授权这台电脑；在 DevEco 设备列表中选择该真机。
4. 选择 `entry` 模块的 `default` 目标，点击运行。首次安装按 DevEco 提示生成或选择本机调试签名；签名文件不提交。

也可以从项目根目录用 Hvigor 构建 HAP。将下面的路径替换为本机 DevEco 安装目录：

```powershell
$env:DEVECO_SDK_HOME = 'D:\deveco\DevEco Studio\sdk'
& 'D:\deveco\DevEco Studio\tools\hvigor\bin\hvigorw.bat' `
  --mode module -p product=default -p module=entry@default assembleHap
```

HAP 输出在 `entry/build/default/outputs/default/`。若修改 Godot 游戏内容，先用 Godot 的 `Harmony Web` 导出预设重新导出到 `entry/src/main/resources/rawfile/game/index.html`，再将更新后的 Web 文件与代码一起提交。云模拟器与不同真机的 WebGL/GPU 能力可能不同，最终显示效果要在目标真机上验证。

## 缓存与提交规则

- 不提交 `.godot/`、`.idea/`、`.hvigor/`、`oh_modules/`、`entry/build/`、HAP、数据库、Python `__pycache__/`、本地配置和签名文件。这些是缓存、构建产物或个人环境数据。
- 提交游戏实际引用的原始图片、音频、字体、Web 导出文件，以及 Godot 的 `*.import` 导入设置和脚本 `*.uid`。`.import` 是资源导入设置，不是 `.godot/` 导入缓存；其他人克隆后会在自己的 `.godot/` 重新生成导入结果。
- `entry/src/main/resources/rawfile/game/index.pck` 使用 Git LFS；其他需要跟随工程共享的大型二进制资源也按仓库 LFS 规则管理。
- API Key、`local.properties`、HarmonyOS 调试签名、数据库、截图和临时导出物均不得提交。
- 通过功能分支提交并创建 Pull Request 到 `main`；不要直接在 `main` 上开发。提交前检查 `git status`、`git diff --check`，运行下方相关校验。

## 校验

在项目根目录运行数据与后端检查：

```powershell
python tools/v12m_validate.py
python tools/audit_v12m.py
python backend/api/selftest.py
python backend/api/npc_chat_test.py
```

Godot 命令行校验示例（按安装路径调整可执行文件）：

```powershell
$godot = 'D:\Apps\Godot\Godot_v4.7.2-stable_win64_console.exe'
& $godot --headless --editor --path . --import --quit
& $godot --headless --path . res://tests/StartupFlowTest.tscn
& $godot --headless --path . res://tests/V12CoreFlowTest.tscn
& $godot --headless --path . res://tests/V12MilestonesTest.tscn
```

改动某个玩法模块时，同时运行对应的 `tests/` 场景。数据校验中的历史警告需结合本次改动判断，不要误当作测试失败。
