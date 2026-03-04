FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# 安装系统基础工具（不含 Chromium，减少约 400MB）
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    wget \
    git \
    vim \
    unzip \
    build-essential \
    python3 \
    python3-pip \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# 安装 Node.js 22 + 全局 npm 包（合并层，统一清理缓存）
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/* \
    && npm install -g openclaw@latest \
    && npm install -g @anthropic-ai/claude-code \
    && npm install -g @openai/codex \
    && npm install -g acpx \
    && openclaw plugins install @openclaw/feishu \
    && openclaw plugins install acpx \
    && cd /usr/lib/node_modules/openclaw/extensions/acpx && npm install \
    && npm cache clean --force \
    && rm -rf /tmp/*

# 复制入口脚本
COPY --chmod=755 entrypoint.sh /usr/local/bin/entrypoint.sh

# 复制配置模板
COPY config/ /opt/openclaw/config/

# 创建工作用户和目录
RUN useradd -m -s /bin/bash openclaw \
    && mkdir -p /home/openclaw/.openclaw /workspace \
    && chown -R openclaw:openclaw /home/openclaw /workspace

# 预配置 Claude Code 无头运行环境（跳过首次运行交互式设置）
RUN mkdir -p /home/openclaw/.claude \
    && echo '{"permissions":{"allow":["Bash(*)", "Read(*)", "Write(*)", "Edit(*)", "Glob(*)", "Grep(*)"],"deny":[]},"hasCompletedOnboarding":true}' > /home/openclaw/.claude/settings.json \
    && chown -R openclaw:openclaw /home/openclaw/.claude

USER openclaw
WORKDIR /workspace

EXPOSE 18789

HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD curl -f http://localhost:18789/health || exit 1

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
