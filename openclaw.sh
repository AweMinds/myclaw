#!/bin/bash

# OpenClaw 管理脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查 Docker 是否安装
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker 未安装,请先安装 Docker"
        exit 1
    fi

    if ! command -v docker compose &> /dev/null; then
        print_error "Docker Compose 未安装,请先安装 Docker Compose"
        exit 1
    fi

    print_info "Docker 环境检查通过"
}

# 检查环境变量配置
check_env() {
    if [ ! -f .env.backup ]; then
        print_error ".env 文件不存在,请先配置环境变量"
        print_info "可以复制 .env.example 并填入实际配置: cp .env.example .env"
        exit 1
    fi

    # 检查必要的环境变量是否已配置
    source .env.backup

    if [ -z "$FEISHU_APP_ID" ] || [ -z "$FEISHU_APP_SECRET" ] || [ -z "$OPENAI_API_KEY" ]; then
        print_error "环境变量未完整配置,请编辑 .env 文件填入实际值"
        exit 1
    fi

    print_info "环境变量配置检查通过"
}

# 构建镜像
build() {
    print_info "开始构建 OpenClaw Docker 镜像..."
    print_warn "首次构建可能需要 10-15 分钟,请耐心等待"
    docker compose build
    print_info "镜像构建完成"
}

# 启动容器
start() {
    print_info "启动 OpenClaw 容器..."
    docker compose up -d
    print_info "容器已启动"
    print_info "Web UI 地址: http://localhost:18789"
    print_info "查看日志: ./openclaw.sh logs"
}

# 停止容器
stop() {
    print_info "停止 OpenClaw 容器..."
    docker compose down
    print_info "容器已停止"
}

# 重启容器
restart() {
    print_info "重启 OpenClaw 容器..."
    docker compose restart
    print_info "容器已重启"
}

# 查看日志
logs() {
    docker compose logs -f openclaw-agent
}

# 查看状态
status() {
    print_info "容器状态:"
    docker compose ps
    echo ""
    print_info "资源使用:"
    docker stats openclaw-agent --no-stream
}

# 进入容器
shell() {
    print_info "进入 OpenClaw 容器..."
    docker compose exec openclaw-agent bash
}

# 首次配置
setup() {
    print_info "开始首次配置..."
    print_info "请按照提示完成配置"
    echo ""

    docker compose exec openclaw-agent openclaw onboard
    echo ""

    print_info "添加飞书渠道..."
    docker compose exec openclaw-agent openclaw channels add
    echo ""

    print_info "创建 Agent..."
    docker compose exec openclaw-agent openclaw agents create --name "研发助手"
    echo ""

    print_info "配置完成!"
}

# 备份数据
backup() {
    BACKUP_FILE="openclaw-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
    print_info "备份数据到 $BACKUP_FILE..."
    tar -czf "$BACKUP_FILE" openclaw-data
    print_info "备份完成: $BACKUP_FILE"
}

# 显示帮助
help() {
    cat << EOF
OpenClaw 管理脚本

用法: ./openclaw.sh [命令]

命令:
  check       检查 Docker 环境和配置
  build       构建 Docker 镜像
  start       启动容器
  stop        停止容器
  restart     重启容器
  logs        查看日志
  status      查看容器状态和资源使用
  shell       进入容器 shell
  setup       首次配置(添加飞书渠道和创建 Agent)
  backup      备份数据
  help        显示此帮助信息

示例:
  ./openclaw.sh check       # 检查环境
  ./openclaw.sh build       # 构建镜像
  ./openclaw.sh start       # 启动容器
  ./openclaw.sh setup       # 首次配置
  ./openclaw.sh logs        # 查看日志

EOF
}

# 主函数
main() {
    case "${1:-help}" in
        check)
            check_docker
            check_env
            ;;
        build)
            check_docker
            check_env
            build
            ;;
        start)
            check_docker
            check_env
            start
            ;;
        stop)
            stop
            ;;
        restart)
            restart
            ;;
        logs)
            logs
            ;;
        status)
            status
            ;;
        shell)
            shell
            ;;
        setup)
            setup
            ;;
        backup)
            backup
            ;;
        help|*)
            help
            ;;
    esac
}

main "$@"
