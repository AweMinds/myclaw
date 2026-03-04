# OpenClaw 快速入门指南

## 前置条件

- 一台安装了 Docker 的服务器（或本地机器）
- 飞书企业自建应用的 App ID 和 App Secret
- Anthropic API Key（用于 Claude Code）

> 如果还没有飞书应用，请先完成[飞书应用配置](#附录飞书应用配置)。

---

## 一键部署（推荐）

使用 `setup.sh` 脚本，交互式完成配置并自动启动：

```bash
# 下载 setup.sh 后执行（或在项目目录中直接运行）
bash setup.sh
```

脚本会依次引导你：

1. **输入飞书应用凭证** — App ID 和 App Secret
2. **输入 Anthropic API Key** — 用于 Claude Code
3. **输入 OpenAI API Key**（可选）— 备用模型
4. **自动生成** `.env` 和 `docker-compose.yml`
5. **拉取镜像并启动容器**

启动成功后会输出：

```
===============================
  部署完成！
===============================
  Web UI: http://localhost:18789?token=xxx
  Gateway Token: xxx
  查看日志: docker compose logs -f
===============================
```

> 如果已有 `.env` 文件，脚本会询问是否覆盖；选择 N 则直接启动。

---

## 手动部署

如果需要更细粒度的控制，可以使用 `openclaw.sh` 管理脚本分步操作：

### 1. 配置环境变量

```bash
cp .env.example .env
vim .env   # 填入实际的 App ID、App Secret、API Key 等
```

### 2. 检查环境

```bash
./openclaw.sh check
```

确认输出：
```
[INFO] Docker 环境检查通过
[INFO] 环境变量配置检查通过
```

### 3. 构建镜像（仅本地开发需要）

```bash
./openclaw.sh build
```

> 首次构建约 10-15 分钟。线上部署直接拉取预构建镜像，无需此步骤。

### 4. 启动容器

```bash
./openclaw.sh start
```

### 5. 首次配置（添加渠道和 Agent）

```bash
./openclaw.sh setup
```

按提示完成：
- Onboard 初始化
- 添加飞书渠道
- 创建 Agent

---

## 验证

1. 打开 Web UI: `http://localhost:18789`
2. 在飞书中搜索机器人，发送 `你好`
3. 机器人应在几秒内回复

---

## 日常管理命令

所有操作通过 `./openclaw.sh` 完成：

```bash
./openclaw.sh start      # 启动容器
./openclaw.sh stop       # 停止容器
./openclaw.sh restart    # 重启容器
./openclaw.sh logs       # 查看实时日志
./openclaw.sh status     # 查看容器状态和资源使用
./openclaw.sh shell      # 进入容器 shell
./openclaw.sh backup     # 备份数据
./openclaw.sh help       # 查看所有命令
```

---

## 故障排查

| 问题 | 排查方法 |
|------|---------|
| 容器无法启动 | `./openclaw.sh logs` 查看日志；`lsof -i :18789` 检查端口占用 |
| 飞书连接失败 | 确认 App ID / Secret 正确；确认应用已发布；确认事件订阅使用**长连接** |
| LLM API 调用失败 | `docker compose exec openclaw-agent env \| grep ANTHROPIC` 检查配置 |

---

## 附录：飞书应用配置

1. 访问 [飞书开放平台](https://open.feishu.cn/)，创建**企业自建应用**
2. 在"凭证与基础信息"中获取 **App ID** 和 **App Secret**
3. 在"权限管理"中添加权限：
   - `im:message` — 获取与发送单聊、群组消息
   - `im:message:group` — 获取群组中所有消息
   - `im:chat` — 获取群信息
4. 在"应用功能"中启用**机器人**
5. 在"事件订阅"中选择**长连接**，添加事件 `im.message.receive_v1`
6. 创建版本并发布应用
