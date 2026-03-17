---
name: libtv-skill
description: agent-im 会话技能 - 通过 OpenAPI 创建会话、发送生图/生视频等消息、上传图片/视频文件，并查询会话进展。当用户需要生图、生视频、上传文件或查询当前会话消息时激活此技能。
user-invocable: true
metadata:
  {
    "openclaw":
      {
        "emoji": "💬",
        "requires":
          {
            "bins": ["python3"],
            "env": ["LIBTV_ACCESS_KEY"]
          },
        "primaryEnv": "LIBTV_ACCESS_KEY"
      }
  }
---

# agent-im 会话（生图 / 生视频）

通过 agent-im 的 OpenAPI 创建会话、发送消息（生图、生视频等）、上传图片/视频文件，并查询会话消息进展。

## 功能

1. **创建会话 / 发消息** - 创建新会话或向已有会话发送一条消息（如「生一个动漫视频」）
2. **查询会话进展** - 根据 sessionId 拉取该会话的消息列表，用于轮询生图/生视频结果
3. **切换项目** - 将当前 accessKey 绑定的项目切换到新项目，后续 create_session 将使用新 projectUuid
4. **上传文件** - 上传图片或视频文件到 OSS，返回可访问的 OSS 地址

## 前置要求

```bash
export LIBTV_ACCESS_KEY="your-access-key"
```

可选：`OPENAPI_IM_BASE` 或 `IM_BASE_URL`，默认 `https://im.liblib.tv`。

无需安装额外依赖，仅使用 Python 标准库。

## 使用方法

### 1. 创建会话 / 发送消息

```bash
# 创建新会话并发送「生一个动漫视频」
python3 {baseDir}/scripts/create_session.py "生一个动漫视频"

# 向已有会话发送消息
python3 {baseDir}/scripts/create_session.py "再生成一张风景图" --session-id SESSION_ID

# 只创建/绑定会话，不发消息
python3 {baseDir}/scripts/create_session.py
```

### 2. 查询会话进展

```bash
# 查询会话消息列表
python3 {baseDir}/scripts/query_session.py SESSION_ID

# 增量拉取（只返回 seq 大于 N 的消息）
python3 {baseDir}/scripts/query_session.py SESSION_ID --after-seq 5

# 附带项目地址（传入 create_session 返回的 projectUuid，结果中带 projectUrl）
python3 {baseDir}/scripts/query_session.py SESSION_ID --project-id PROJECT_UUID
```

### 3. 切换项目

```bash
# 切换当前 accessKey 绑定的项目（后续创建会话将使用新项目）
python3 {baseDir}/scripts/change_project.py
```

### 4. 上传文件

当用户提供了参考的文件地址时，进行上传，仅支持图片、视频，文件大小必须在200M以下。

```bash
# 上传图片
python3 {baseDir}/scripts/upload_file.py /path/to/image.png

# 上传视频
python3 {baseDir}/scripts/upload_file.py /path/to/video.mp4
```

## 输出格式

**create_session** 返回：
```json
{
  "projectUuid": "aa3ba04c5044477cb7a00a9e5bf3b4d0",
  "sessionId": "90f05e0c-...",
  "projectUrl": "https://www.liblib.tv/canvas?projectId=aa3ba04c5044477cb7a00a9e5bf3b4d0"
}
```

**query_session** 返回：
```json
{
  "messages": [
    {"id": "msg-xxx", "role": "user", "content": "生一个动漫视频"},
    {"id": "msg-yyy", "role": "assistant", "content": "..."}
  ],
  "projectUrl": "https://www.liblib.tv/canvas?projectId=..."
}
```
（`projectUrl` 仅在传入 `--project-id` 时存在）

**change_project** 返回：
```json
{
  "projectUuid": "新项目UUID",
  "projectUrl": "https://www.liblib.tv/canvas?projectId=新项目UUID"
}
```

**upload_file** 返回：
```json
{
  "url": "https://libtv-res.liblib.art/claw/{projectUuid}/{uuid}.png"
}
```

## 最终向用户展示时（OpenClaw）

- **视频地址**：来自 `query_session` 返回的 `messages` 中 assistant 消息的 content 或结果里的视频/图片 URL，即「返回的结果」。
- **项目地址**：使用 `create_session` 返回的 `projectUrl`，或自行拼接 `https://www.liblib.tv/canvas?projectId=` + `projectUuid`。查询进展时若传入 `--project-id PROJECT_UUID`，`query_session` 会直接返回 `projectUrl`，便于一并展示。

在任务完成时，同时给出：**视频/图片结果链接** + **项目画布链接（projectUrl）**。
过程中，不要给出 **项目画布链接（projectUrl）**。

## 注意事项

- 鉴权方式为请求头 `Authorization: Bearer <LIBTV_ACCESS_KEY>`
- 创建会话时若不传 `message`，仅创建/绑定会话，不会调用 SendMessage
- 查询会话时可用 `--after-seq` 做增量拉取，便于轮询新消息（含 assistant 回复与生图/生视频结果）
- 项目画布地址固定为：`https://www.liblib.tv/canvas?projectId=` + projectUuid
- 切换项目后，Redis 缓存会更新，下次 create_session 将使用新的 projectUuid
- 上传文件仅支持图片（image/*）和视频（video/*）类型，其他类型会被拒绝
- 上传返回的 OSS 地址格式为 `https://libtv-res.liblib.art/claw/{projectUuid}/{uuid}{ext}`
- 注意要把生成的视频和图片，及时的返回并呈现给用户
- 注意要把用户的需求信息，及时的传递给agent
