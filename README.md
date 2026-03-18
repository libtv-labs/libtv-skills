# 🎬 libtv-skills

> AI Agent Skills for [LibLib.tv](https://www.liblib.tv) — 让你的 AI Agent 轻松调用 LibTV 的生图、生视频等 AIGC 能力。

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Python 3.6+](https://img.shields.io/badge/Python-3.6+-green.svg)](https://python.org)

## ✨ 简介

**libtv-skills** 是一组面向 AI Agent 的技能包（Skills），通过 [LibLib.tv](https://www.liblib.tv) 的 OpenAPI 提供 **AI 生图**、**AI 生视频** 等 AIGC 能力。Agent 可以通过这些技能创建会话、发送创作指令、查询生成进展，并获取最终的图片/视频结果。

本项目遵循 [OpenClaw](https://github.com/anthropics/openclaw) 技能规范，可被支持该规范的 AI Agent 平台直接识别和调用。

## 📦 技能列表

| 技能 | 描述 | 脚本 |
|------|------|------|
| **libtv-skill** | Agent-IM 会话技能 — 创建会话、发送生图/生视频消息、上传文件、查询进展、批量下载结果 | `create_session.py` `query_session.py` `change_project.py` `upload_file.py` `download_results.py` |

## 📥 快速安装

通过 `npx skills` 一键安装技能到你的项目中：

```bash
# 交互式选择要安装的技能
npx skills add libtv-labs/libtv-skills

# 直接安装指定技能
npx skills add libtv-labs/libtv-skills --skill libtv-skill
```

安装完成后，设置环境变量即可使用：

```bash
export LIBTV_ACCESS_KEY="your-access-key"
```

> 🎉 **就这么简单！** 技能文件会被添加到你的项目中，AI Agent 将自动识别并调用，无需手动执行任何脚本。

可选配置（一般无需修改）：

| 变量 | 必填 | 默认值 | 说明 |
|------|------|--------|------|
| `LIBTV_ACCESS_KEY` | ✅ | — | LibTV API 鉴权密钥 |
| `OPENAPI_IM_BASE` | ❌ | `https://im.liblib.tv` | IM 服务地址 |
| `IM_BASE_URL` | ❌ | `https://im.liblib.tv` | IM 服务地址（备选） |

## 🛠️ 手动使用 / 调试

<details>
<summary>如果你需要手动调用脚本或调试，点击展开查看详细用法</summary>

### 前置要求

- **Python 3.6+**（仅使用标准库，无需安装额外依赖）
- **`LIBTV_ACCESS_KEY`** 环境变量已设置

### 创建会话 & 发送生成指令

```bash
# 创建新会话，发送「生一个动漫视频」
python3 skills/libtv-skill/scripts/create_session.py "生一个动漫视频"

# 向已有会话追加消息
python3 skills/libtv-skill/scripts/create_session.py "再生成一张风景图" --session-id <SESSION_ID>

# 只创建/绑定会话，不发消息
python3 skills/libtv-skill/scripts/create_session.py
```

**输出示例：**

```json
{
  "projectUuid": "aa3ba04c5044477cb7a00a9e5bf3b4d0",
  "sessionId": "90f05e0c-5d08-4148-be40-e30fc7c7bedf",
  "projectUrl": "https://www.liblib.tv/canvas?projectId=aa3ba04c5044477cb7a00a9e5bf3b4d0"
}
```

### 查询会话进展

```bash
# 查询会话消息列表
python3 skills/libtv-skill/scripts/query_session.py <SESSION_ID>

# 增量拉取（只返回 seq > N 的新消息，适合轮询）
python3 skills/libtv-skill/scripts/query_session.py <SESSION_ID> --after-seq 5

# 附带项目地址
python3 skills/libtv-skill/scripts/query_session.py <SESSION_ID> --project-id <PROJECT_UUID>
```

**输出示例：**

```json
{
  "messages": [
    { "id": "msg-xxx", "role": "user", "content": "生一个动漫视频" },
    { "id": "msg-yyy", "role": "assistant", "content": "..." }
  ],
  "projectUrl": "https://www.liblib.tv/canvas?projectId=..."
}
```

### 切换项目

```bash
# 切换当前 accessKey 绑定的项目
python3 skills/libtv-skill/scripts/change_project.py
```

**输出示例：**

```json
{
  "projectUuid": "新项目UUID",
  "projectUrl": "https://www.liblib.tv/canvas?projectId=新项目UUID"
}
```

### 上传文件

```bash
# 上传图片
python3 skills/libtv-skill/scripts/upload_file.py /path/to/image.png

# 上传视频
python3 skills/libtv-skill/scripts/upload_file.py /path/to/video.mp4
```

**输出示例：**

```json
{
  "url": "https://libtv-res.liblib.art/claw/{projectUuid}/{uuid}.png"
}
```

### 下载结果

```bash
# 从会话自动提取并下载所有图片/视频
python3 skills/libtv-skill/scripts/download_results.py <SESSION_ID>

# 指定输出目录
python3 skills/libtv-skill/scripts/download_results.py <SESSION_ID> --output-dir ~/Desktop/my_project

# 指定文件名前缀（如 storyboard_01.png, storyboard_02.png ...）
python3 skills/libtv-skill/scripts/download_results.py <SESSION_ID> --prefix "storyboard"

# 直接下载指定 URL 列表（无需 session_id）
python3 skills/libtv-skill/scripts/download_results.py --urls URL1 URL2 URL3 --output-dir ./output
```

**输出示例：**

```json
{
  "output_dir": "/Users/xxx/Downloads/libtv_results",
  "downloaded": ["/Users/xxx/Downloads/libtv_results/01.png", "..."],
  "total": 9
}
```

</details>

## 📁 项目结构

```
libtv-skills/
├── README.md
├── LICENSE
└── skills/
    └── libtv-skill/                  # Agent-IM 会话技能
        ├── SKILL.md                # 技能描述文件（OpenClaw 规范）
        └── scripts/
            ├── _common.py          # 公共模块（鉴权、HTTP 请求、API 封装）
            ├── create_session.py   # 创建会话 / 发送消息
            ├── query_session.py    # 查询会话消息进展
            ├── change_project.py   # 切换绑定项目
            ├── upload_file.py      # 上传图片 / 视频文件到 OSS
            └── download_results.py # 批量下载生成结果到本地
```

## 🔧 API 参考

### 鉴权

所有 API 请求通过 HTTP Header 进行 Bearer Token 鉴权：

```
Authorization: Bearer <LIBTV_ACCESS_KEY>
```

### 接口列表

| 方法 | 路径 | 说明 |
|------|------|------|
| `POST` | `/openapi/session` | 创建会话 / 发送消息 |
| `GET` | `/openapi/session/:sessionId` | 查询会话消息列表 |
| `POST` | `/openapi/session/change-project` | 切换绑定项目 |
| `POST` | `/openapi/file/upload` | 上传图片 / 视频文件到 OSS |

### 请求 & 响应

<details>
<summary><b>POST /openapi/session</b> — 创建会话 / 发送消息</summary>

**Request Body:**

```json
{
  "sessionId": "（可选）已有会话 ID",
  "message": "（可选）要发送的消息内容"
}
```

**Response:**

```json
{
  "data": {
    "projectUuid": "aa3ba04c5044477cb7a00a9e5bf3b4d0",
    "sessionId": "90f05e0c-5d08-4148-be40-e30fc7c7bedf"
  }
}
```

</details>

<details>
<summary><b>GET /openapi/session/:sessionId</b> — 查询会话消息</summary>

**Query Params:**

| 参数 | 类型 | 说明 |
|------|------|------|
| `afterSeq` | int | 可选，只返回 seq 大于该值的消息（增量拉取） |

**Response:**

```json
{
  "data": {
    "messages": [
      { "id": "msg-xxx", "role": "user", "content": "生一个动漫视频" },
      { "id": "msg-yyy", "role": "assistant", "content": "..." }
    ]
  }
}
```

</details>

<details>
<summary><b>POST /openapi/session/change-project</b> — 切换项目</summary>

**Request Body:** `{}`（空）

**Response:**

```json
{
  "data": {
    "projectUuid": "新项目UUID"
  }
}
```

</details>

<details>
<summary><b>POST /openapi/file/upload</b> — 上传文件</summary>

**Request Body:** `multipart/form-data`，包含 `file` 字段（图片或视频文件）

**Response:**

```json
{
  "data": {
    "url": "https://libtv-res.liblib.art/claw/{projectUuid}/{uuid}.png"
  }
}
```

> 仅支持图片（`image/*`）和视频（`video/*`）类型，其他类型会被拒绝。

</details>

## 🤖 Agent 集成指南

本技能包设计为被 AI Agent 自动调用。典型的工作流如下：

```
用户指令 → Agent 解析意图 → 调用 create_session.py 发送指令
                                    ↓
                          获取 sessionId + projectUuid
                                    ↓
                          轮询 query_session.py 获取结果
                                    ↓
                     download_results.py 批量下载到本地
                                    ↓
                      向用户展示：生成结果 + 项目画布链接
```

### 最佳实践

- **自动下载**：任务完成后，使用 `download_results.py` 将图片/视频批量下载到本地，再同时向用户展示 **本地文件路径** 和 **项目画布链接**（`projectUrl`）
- **增量轮询**：使用 `--after-seq` 参数进行增量拉取，避免重复获取已处理的消息
- **项目管理**：当需要隔离不同任务时，使用 `change_project.py` 切换到新项目
- **文件上传**：在发送生图/生视频指令前，可先用 `upload_file.py` 上传参考图片或素材，获取 OSS 地址后再一并传入消息

## 🤝 贡献

欢迎提交 Pull Request 来添加新的技能或改进现有技能！

### 添加新技能

1. 在 `skills/` 目录下创建新的技能文件夹
2. 编写 `SKILL.md` 技能描述文件（遵循 OpenClaw 规范）
3. 在 `scripts/` 子目录中实现功能脚本
4. 更新本 README 的技能列表

## 📄 License

本项目采用 [MIT License](LICENSE) 开源。

Copyright © 2026 [libtv-labs](https://github.com/libtv-labs)