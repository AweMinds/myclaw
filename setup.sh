#!/bin/bash
set -e

IMAGE="registry.cn-shanghai.aliyuncs.com/aweminds/myclaw:latest"

echo "==============================="
echo "  OpenClaw 一键部署引导"
echo "==============================="
echo ""

# 检查 Docker
if ! command -v docker &>/dev/null; then
    echo "错误：未检测到 Docker，请先安装 Docker"
    exit 1
fi

# 创建工作目录
WORK_DIR="${1:-.}"
if [ "$WORK_DIR" != "." ]; then
    mkdir -p "$WORK_DIR"
    cd "$WORK_DIR"
    echo "工作目录: $(pwd)"
    echo ""
fi

# 生成 docker-compose.yml（每次都写入，确保存在且最新）
write_compose() {
    cat > docker-compose.yml << 'COMPOSE_EOF'
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
      - OPENCLAW_GATEWAY_TOKEN=${OPENCLAW_GATEWAY_TOKEN}
      - ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
      - ANTHROPIC_BASE_URL=${ANTHROPIC_BASE_URL}
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 4G
        reservations:
          cpus: '1.0'
          memory: 2G
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
COMPOSE_EOF
}

# 如果 .env 已存在，询问是否覆盖
if [ -f .env ]; then
    read -p ".env 文件已存在，是否重新配置？(y/N) " overwrite
    if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
        echo "跳过配置，直接启动..."
        write_compose
        docker compose up -d
        echo ""
        echo "启动完成！查看日志: docker compose logs -f"
        exit 0
    fi
fi

echo "--- 飞书应用配置(可选，直接回车跳过） ---"
echo "请先在 https://open.feishu.cn/ 创建企业自建应用"
echo ""
read -p "飞书 App ID: " FEISHU_APP_ID
read -p "飞书 App Secret: " FEISHU_APP_SECRET

echo ""
echo "--- Anthropic API 配置（Claude Code 使用）---"
read -p "Anthropic API Key: " ANTHROPIC_API_KEY
read -p "Anthropic Base URL（直接回车使用默认 https://api.anthropic.com）: " ANTHROPIC_BASE_URL
ANTHROPIC_BASE_URL=${ANTHROPIC_BASE_URL:-https://api.anthropic.com}

echo ""
echo "--- OpenAI 兼容 API（可选，直接回车跳过）---"
read -p "OpenAI API Key（可选）: " OPENAI_API_KEY
if [ -n "$OPENAI_API_KEY" ]; then
    read -p "OpenAI Base URL（默认 https://api.openai.com/v1）: " OPENAI_BASE_URL
    OPENAI_BASE_URL=${OPENAI_BASE_URL:-https://api.openai.com/v1}
fi

# 自动生成 Gateway Token
OPENCLAW_GATEWAY_TOKEN=$(openssl rand -hex 16)

# 写入 .env
cat > .env << EOF
FEISHU_APP_ID=${FEISHU_APP_ID}
FEISHU_APP_SECRET=${FEISHU_APP_SECRET}
ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
ANTHROPIC_BASE_URL=${ANTHROPIC_BASE_URL}
OPENAI_API_KEY=${OPENAI_API_KEY}
OPENAI_BASE_URL=${OPENAI_BASE_URL}
OPENCLAW_GATEWAY_TOKEN=${OPENCLAW_GATEWAY_TOKEN}
EOF

echo ""
echo ".env 已生成！"

# 生成 docker-compose.yml
write_compose
echo "docker-compose.yml 已生成！"
echo ""

read -p "是否立即拉取镜像并启动？(Y/n) " start
if [[ "$start" =~ ^[Nn]$ ]]; then
    echo "配置完成。稍后运行 docker compose up -d 启动"
    exit 0
fi

echo "正在拉取镜像并启动..."
docker compose up -d
echo ""
echo "==============================="
echo "  部署完成！"
echo "==============================="
echo "  Web UI: http://localhost:18789?token=${OPENCLAW_GATEWAY_TOKEN}"
echo "  Gateway Token: ${OPENCLAW_GATEWAY_TOKEN}"
echo "  查看日志: docker compose logs -f"
echo "  服务启动需要一段时间，请10~30秒后访问 Web UI"
echo "  或在飞书中找到机器人发送消息测试"
echo "==============================="
