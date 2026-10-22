# 后端服务目录

后端同学在此目录实现 API、数据库迁移、测试与部署说明。技术语言可自行选择，但对外接口必须实现 `../contracts/openapi.yaml`。

开始前先完成：

1. `POST /api/v1/sessions`
2. `GET /api/v1/sessions/{sessionId}/next`
3. `POST /api/v1/sessions/{sessionId}/events`
4. 事件幂等和 `GET /api/v1/sessions/{sessionId}` 恢复

V1.2 的 39 件主线使用 `data/story/story_key_map_v12.json` 对齐评分卡。六个月晋升检查点通过 `POST /api/v1/sessions/{sessionId}/assessments/{month}` 结算；前置剧情未完成时返回 409，重复请求不会重复晋升。会话状态下发 `currentMonth` 与 `assessmentHistory`，不下发内部阈值。第 48 月终局主线未结算前 `POST /report` 返回 409；报告由服务端生成，客户端先请求生成再读取。训练谷战斗结果不参与评分。

V1.2 行动力窗口的三次区域活动消耗分别上报 `action_spent`。同一窗口记录完整的剩余点数 2、1、0 后，在当前六个月考核窗内获得一次封顶累积加分；跨窗口刷行动不会重复加分。NPC 对话不消耗行动力，但原话进入事件流与对应 NPC 的 social 记忆；尚无经校准的语义评分规则。训练谷胜负只作证据，二者都不直接改变晋升分数。

手机和室内聊天调用 `POST /api/v1/sessions/{sessionId}/npcs/{npcId}/chat`。角色设定来自 `data/town/npcs.json`，后端从本会话事件推导记忆上下文；同一 `eventId` 重试返回同一回复。本机后端从被 Git 忽略的 `backend/local_llm_config.json` 读取 DeepSeek 密钥、模型和地址；环境变量 `NPC_LLM_PROVIDER`、`DEEPSEEK_API_KEY`、`DEEPSEEK_MODEL`、`DEEPSEEK_API_URL` 可覆盖文件设置。原有 Ark 模式继续使用 `ARK_API_KEY`、`ARK_MODEL`、`ARK_API_URL`。未配置或模型请求失败时返回 `generatedBy: template`，不会改变晋升分数。每位开发者自行从 `backend/local_llm_config.example.json` 创建本地配置并填写自己有权使用的密钥；真实密钥不得提交 Git 或放入共享压缩包。

V1.2 的 C1-C5 成就节点配置在 `data/story/achievements_v12.json`：按文档顺序插在 E08、E12、E22、E38、E34 后。它们只展示剧情、写记忆便签和 `achievement_view` 埋点，C4/C5 的轻选择也不进入隐藏测评；训练谷目前只接入已完成的第一关，后续关卡保留待设计。

职业月历允许玩家确认后跳到未来月份。前端发送 `month_jump` 事件及 `targetMonth`；服务端把目标月之前未完成的主线记入 `skippedStoryIds`，推进经过的晋升检查点，但不为跳过的事件生成选择或评分。目标月的主线仍需完成；报告的 `decisionCount` 只计真实选择，并列出跳过的主线。

Godot 的 `mock` 模式只演示流程，不生成晋升结果和报告。本机已将 `data/integration/api_config.json` 设为 `live`、`http://127.0.0.1:8077` 和 `v1.2`；运行游戏前需启动本目录的 API 服务（默认端口 8077）。旧版本的本地事件队列和会话不能混入 V1.2 会话；切换前请检查并备份 `user://workplace_town_api_queue.json` 与 `user://workplace_town_api_session.json`，可使用 `python tools/prepare_live_api.py` 归档并新建活动队列。`127.0.0.1` 仅适用于同一台电脑，移动设备需要可访问的服务地址。

在 Windows 上安装 Python 3.10+ 和 Godot 4.7 后，双击项目根目录的 `Start-Game.cmd`，即可启动本机后端和游戏；Godot 不在 PATH 或 WinGet 目录时可设置 `GODOT_EXE`。克隆项目后先复制 `backend/local_llm_config.example.json` 为 `backend/local_llm_config.json`，并在本地填写自己的模型配置。该文件已被 `.gitignore` 排除，不要提交或共享真实密钥。公开部署前还需鉴权和额度限制，不能直接把本地无鉴权 API 暴露到互联网。

公网试玩设置 `WORKPLACE_PUBLIC_MODE=1`：新会话签发独立令牌，客户端保存在本机并在续接及后续请求中提交；只有令牌哈希保存在 SQLite 中。未持有令牌者不能读取或修改该会话。服务限制每 IP 每小时新建 20 个会话、每小时 60 次聊天，以及每会话每天 40 次、全站每天 300 次聊天。API 必须通过同源 HTTPS 反向代理访问，Python 只监听 `127.0.0.1`。玩家无需账号，`sessions` 表代表匿名游玩会话，不等于去重后的真实人数。管理员在服务器执行 `python3 /opt/workplace-town/backend/api/admin_stats.py` 可查看聚合数据，原始事件和报告保存在 `/var/lib/workplace-town/game.sqlite3`。DeepSeek Key 只放在服务器的 `/etc/workplace-town.env`，不要打进 Godot Web 包或发给玩家。这是限额的公开试玩版，不是带账号系统和长期运营防滥用的正式版。
