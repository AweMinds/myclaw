# OpenClaw 容器化部署

基于 Docker 容器的 OpenClaw AI Agent 部署方案,支持通过飞书进行交互。

## 📋 前置要求

- Docker 和 Docker Compose 已安装
- 飞书企业自建应用(需要 App ID 和 App Secret)
- Anthropic API Key(Claude Code + 主模型)

## 🚀 快速开始

### 方式一：一键脚本（推荐）

无需 clone 仓库,直接运行:

```bash
curl -fsSL https://raw.githubusercontent.com/your-org/openclaw-staff/main/setup.sh -o setup.sh
chmod +x setup.sh
./setup.sh
```

脚本会交互式引导你填写配置,自动生成 `docker-compose.yml` 和 `.env`,拉取镜像并启动。

### 方式二：手动 docker-compose

创建一个空目录,在其中放入以下两个文件:

**docker-compose.yml:**
```yaml
services:
  openclaw-agent:
    image: registry.cn-shanghai.aliyuncs.com/aweminds/myclaw:latest
    container_name: openclaw-agent
    restart: unless-stopped
    ports:
      - "18789:18789"
    volumes:
      - ./openclaw-data:/home/openclaw/.openclaw
      - ./openclaw-data/claude-code:/home/openclaw/.claude
      - ./workspace:/workspace
      - ./logs:/var/log/openclaw
    environment:
      - FEISHU_APP_ID=${FEISHU_APP_ID}
      - FEISHU_APP_SECRET=${FEISHU_APP_SECRET}
      - OPENAI_API_KEY=${OPENAI_API_KEY}
      - OPENAI_BASE_URL=${OPENAI_BASE_URL}
      - ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
      - ANTHROPIC_BASE_URL=${ANTHROPIC_BASE_URL}
```

**.env:**
```env
FEISHU_APP_ID=cli_xxxxxxxxxxxxx
FEISHU_APP_SECRET=xxxxxxxxxxxxxxxxxxxxx
ANTHROPIC_API_KEY=sk-xxxxxxxxxxxxxxxxxxxxx
ANTHROPIC_BASE_URL=https://api.anthropic.com
```

然后:
```bash
docker compose up -d
```

### 配置飞书应用

访问 [飞书开放平台](https://open.feishu.cn/) 创建企业自建应用:

1. **创建应用**: 填写应用名称(如"OpenClaw 研发助手")、描述和图标
2. **获取凭证**: 复制 App ID 和 App Secret
3. **配置权限**: 添加以下权限
   - `im:message` - 收发消息
   - `im:chat.members:bot_access` - 访问群成员信息
4. **启用机器人**: 在应用能力中启用机器人功能
5. **配置事件订阅**: 选择"使用长连接接收事件(WebSocket)",添加 `im.message.receive_v1` 事件
6. **发布应用**: 创建版本并提交审核发布

### 验证

```bash
docker compose ps          # 确认容器运行中
docker compose logs -f     # 查看日志
```

访问 http://localhost:18789/ 打开 Web UI,在飞书中找到机器人发送消息测试。

## 🔧 常用命令

```bash
docker compose up -d          # 启动
docker compose down           # 停止
docker compose restart        # 重启
docker compose logs -f        # 查看日志
docker compose exec openclaw-agent bash  # 进入容器
```

## 💾 数据备份

```bash
tar -czf openclaw-backup-$(date +%Y%m%d).tar.gz openclaw-data
```

## 🔨 开发者

如需本地构建镜像:

```bash
git clone <repo>
cd openclaw-staff
cp .env.backup.example .env.backup && vim .env.backup
docker compose -f docker-compose.dev.yml up -d --build
```

构建并推送镜像:

```bash
docker compose -f docker-compose.dev.yml build
docker tag openclaw-agent registry.cn-shanghai.aliyuncs.com/aweminds/myclaw:latest
docker push registry.cn-shanghai.aliyuncs.com/aweminds/myclaw:latest
```

## 📁 仓库结构

```
openclaw-staff/
├── setup.sh                      # 一键部署脚本（自包含,无需 clone）
├── Dockerfile                    # Docker 镜像定义
├── docker-compose.yml            # 生产用（image 引用预构建镜像）
├── docker-compose.dev.yml        # 开发用（本地 build）
├── .env.example                  # 环境变量模板
├── config/                       # 配置模板（打包进镜像）
│   ├── openclaw.json.template    # OpenClaw 配置模板
│   └── SOUL.md                   # Agent 人格 + 编程规范
└── entrypoint.sh                 # 容器入口脚本（自动初始化）
```

## 🔒 安全说明

- `.env` 文件包含敏感信息,请勿提交到版本控制
- 容器以非 root 用户运行,并启用了安全限制
- 资源使用受限(CPU: 2 核,内存: 4GB)
- 日志自动轮转,防止磁盘占满

## 📚 更多信息

- [OpenClaw 官方文档](https://docs.openclaw.ai/)
- [飞书开放平台](https://open.feishu.cn/)
