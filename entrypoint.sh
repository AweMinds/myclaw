#!/bin/bash

# 首次启动时从模板生成配置文件
init_config() {
    CONFIG_DIR="/home/openclaw/.openclaw"
    CLAUDE_DIR="/home/openclaw/.claude"
    TEMPLATE_DIR="/opt/openclaw/config"

    # 1. 首次启动：从模板生成 openclaw.json
    if [ ! -f "$CONFIG_DIR/openclaw.json" ]; then
        echo "[init] First boot - generating openclaw.json..."
        mkdir -p "$CONFIG_DIR/workspace"
        node -e "
            const fs = require('fs');
            let t = fs.readFileSync('$TEMPLATE_DIR/openclaw.json.template', 'utf8');
            const vars = {
                FEISHU_APP_ID: process.env.FEISHU_APP_ID || '',
                FEISHU_APP_SECRET: process.env.FEISHU_APP_SECRET || '',
                ANTHROPIC_API_KEY: process.env.ANTHROPIC_API_KEY || '',
                ANTHROPIC_BASE_URL: process.env.ANTHROPIC_BASE_URL || 'https://api.anthropic.com',
                OPENAI_API_KEY: process.env.OPENAI_API_KEY || '',
                OPENAI_BASE_URL: process.env.OPENAI_BASE_URL || 'https://api.openai.com/v1',
            };
            for (const [k, v] of Object.entries(vars)) {
                t = t.split('\${' + k + '}').join(v);
            }
            JSON.parse(t); // validate
            fs.writeFileSync('$CONFIG_DIR/openclaw.json', t);
        "
        echo "[init] openclaw.json created"
    fi

    # 2. 首次启动：复制 SOUL.md
    if [ ! -f "$CONFIG_DIR/workspace/SOUL.md" ]; then
        mkdir -p "$CONFIG_DIR/workspace"
        cp "$TEMPLATE_DIR/SOUL.md" "$CONFIG_DIR/workspace/SOUL.md"
        echo "[init] SOUL.md copied"
    fi

    # 3. 每次启动：生成/更新 claude-code settings.json（env vars 可能变化）
    mkdir -p "$CLAUDE_DIR"
    if [ -n "$ANTHROPIC_API_KEY" ]; then
        node -e "
            const fs = require('fs');
            const path = '$CLAUDE_DIR/settings.json';
            let settings = {};
            try { settings = JSON.parse(fs.readFileSync(path, 'utf8')); } catch(e) {}
            settings.permissions = settings.permissions || {allow:['Bash(*)','Read(*)','Write(*)','Edit(*)','Glob(*)','Grep(*)'],deny:[]};
            settings.hasCompletedOnboarding = true;
            settings.env = settings.env || {};
            settings.env.ANTHROPIC_API_KEY = process.env.ANTHROPIC_API_KEY;
            settings.env.ANTHROPIC_BASE_URL = process.env.ANTHROPIC_BASE_URL || 'https://api.anthropic.com';
            fs.writeFileSync(path, JSON.stringify(settings, null, 2));
        "
        echo "[init] claude-code settings.json updated"
    fi
}

# 后台自动批准设备配对请求 + 飞书用户配对请求
auto_approve() {
    # 等待 gateway 启动
    sleep 10

    while true; do
        # 1. 自动批准设备配对
        pending_device_ids=$(openclaw devices list --json 2>/dev/null \
            | node -e "
                let d='';
                process.stdin.on('data',c=>d+=c);
                process.stdin.on('end',()=>{
                    try {
                        const j=d.substring(d.indexOf('{'));
                        const r=JSON.parse(j);
                        (r.pending||[]).forEach(p=>console.log(p.requestId));
                    } catch(e) {}
                });
            " 2>/dev/null)

        for id in $pending_device_ids; do
            openclaw devices approve "$id" 2>/dev/null && \
                echo "[auto-approve] approved device: $id"
        done

        # 2. 自动批准飞书用户配对
        pending_pairing_codes=$(openclaw pairing list --json 2>/dev/null \
            | node -e "
                let d='';
                process.stdin.on('data',c=>d+=c);
                process.stdin.on('end',()=>{
                    try {
                        const j=d.substring(d.indexOf('{'));
                        const r=JSON.parse(j);
                        (r.requests||[]).forEach(p=>console.log(p.code));
                    } catch(e) {}
                });
            " 2>/dev/null)

        for code in $pending_pairing_codes; do
            openclaw pairing approve feishu "$code" --notify 2>/dev/null && \
                echo "[auto-approve] approved feishu pairing: $code"
        done

        sleep 5
    done
}

# 如果未设置 OPENCLAW_GATEWAY_TOKEN，自动生成并导出
if [ -z "$OPENCLAW_GATEWAY_TOKEN" ]; then
    export OPENCLAW_GATEWAY_TOKEN=$(head -c 16 /dev/urandom | xxd -p)
    echo "[init] Generated OPENCLAW_GATEWAY_TOKEN: $OPENCLAW_GATEWAY_TOKEN"
fi

# 初始化配置（首次启动生成，后续启动更新）
init_config

auto_approve &

# 启动 gateway（前台运行，作为 PID 1）
exec openclaw gateway --port 18789 --bind lan
