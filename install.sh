#!/bin/bash
# -*- coding: utf-8 -*-
# PMHQ 一键安装/更新脚本
# 用法: curl -fsSL https://your-domain/install.sh | bash
# 或: bash install.sh [版本号]

set -e

# 配置（可通过环境变量覆盖）
NAMESPACE="${PMHQ_NAMESPACE:-docker_git_aliyun}"
REPO_NAME="${PMHQ_REPO:-pmhq}"
REGISTRY="${PMHQ_REGISTRY:-registry.cn-hangzhou.aliyuncs.com}"
INSTALL_DIR="${PMHQ_INSTALL_DIR:-/root/dev_pmh}"

# 完整镜像名称（优先级: 环境变量 > 自动组合）
FULL_IMAGE="${PMHQ_IMAGE:-}"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 获取最新版本
get_latest_version() {
    # 阿里云仓库不支持 Docker Hub API，直接返回默认版本
    # 如需自动检测，可配置镜像源为 Docker Hub
    echo "7.3.2-silk-v2"
}

# 检查本地已安装版本
get_local_version() {
    if [ -f "${INSTALL_DIR}/.version" ]; then
        cat "${INSTALL_DIR}/.version"
    else
        echo "none"
    fi
}

# 保存版本号
save_version() {
    echo "$1" > "${INSTALL_DIR}/.version"
}

# 检查Docker是否安装
check_docker() {
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}❌ Docker 未安装${NC}"
        echo "请先安装 Docker:"
        echo "  curl -fsSL https://get.docker.com | bash"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        echo -e "${RED}❌ Docker Compose 未安装${NC}"
        echo "请先安装 Docker Compose:"
        echo "  pip3 install docker-compose"
        exit 1
    fi
    
    # 检查Docker是否运行
    if ! docker info &> /dev/null; then
        echo -e "${RED}❌ Docker 服务未运行${NC}"
        echo "请启动 Docker:"
        echo "  systemctl start docker"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Docker 环境正常${NC}"
}

# 登录阿里云仓库（如果需要）
login_registry() {
    # 公开仓库不需要登录，但如果是私有仓库需要配置
    # docker login --username=your_username ${REGISTRY}
    echo -e "${BLUE}ℹ️  使用阿里云公开仓库${NC}"
}

# 拉取镜像
pull_image() {
    local version=$1
    local full_image
    
    # 优先使用环境变量指定的完整镜像名
    if [ -n "$FULL_IMAGE" ]; then
        full_image="${FULL_IMAGE}:${version}"
    else
        full_image="${REGISTRY}/${NAMESPACE}/${REPO_NAME}:${version}"
    fi
    
    echo -e "${BLUE}📥 拉取镜像: ${full_image}${NC}"
    
    if docker pull "${full_image}"; then
        echo -e "${GREEN}✅ 镜像拉取成功${NC}"
        # 标记为本地版本
        docker tag "${full_image}" "${REPO_NAME}:${version}"
        return 0
    else
        echo -e "${RED}❌ 镜像拉取失败${NC}"
        return 1
    fi
}

# 创建目录结构
setup_directories() {
    echo -e "${BLUE}📁 设置安装目录: ${INSTALL_DIR}${NC}"
    
    # 创建主目录
    mkdir -p "${INSTALL_DIR}"
    
    # 创建子目录
    mkdir -p "${INSTALL_DIR}/qq_data"
    mkdir -p "${INSTALL_DIR}/plugins"
    mkdir -p "${INSTALL_DIR}/config"
    
    echo -e "${GREEN}✅ 目录创建完成${NC}"
}

# 创建 docker-compose.yml
create_compose_file() {
    local version=$1
    local full_image="${REGISTRY}/${NAMESPACE}/${REPO_NAME}:${version}"
    
    echo -e "${BLUE}📝 创建 docker-compose.yml${NC}"
    
    cat > "${INSTALL_DIR}/docker-compose.yml" << EOF
version: '3.8'

services:
  pmhq:
    image: ${full_image}
    container_name: pmhq
    privileged: true
    restart: unless-stopped
    ports:
      - "13000:13000"
      - "13010:13010"
    volumes:
      - ./qq_data:/root/.config/QQ
      - ./plugins:/app/plugins
      - ./config/pmhq_config.json:/opt/pmhq_config.json:ro
    environment:
      - PMHQ_VERSION=${version}
    networks:
      - pmhq_net

networks:
  pmhq_net:
    driver: bridge

volumes:
  qq_data:
  plugins:
EOF
    
    echo -e "${GREEN}✅ docker-compose.yml 创建完成${NC}"
}

# 创建默认配置文件
create_default_config() {
    local config_file="${INSTALL_DIR}/config/pmhq_config.json"
    
    if [ -f "$config_file" ]; then
        echo -e "${YELLOW}⚠️ 配置文件已存在，跳过创建${NC}"
        return 0
    fi
    
    echo -e "${BLUE}⚙️  创建默认配置文件${NC}"
    
    cat > "$config_file" << 'EOF'
{
    "qq_path": "",
    "quick_login_qq": "",
    "enable_gui": false,
    "default_host": "0.0.0.0",
    "default_port": 13001,
    "debug": false,
    "qq_console": true,
    "headless": true
}
EOF
    
    echo -e "${GREEN}✅ 默认配置创建完成${NC}"
    echo -e "${YELLOW}💡 提示: 如需修改配置，请编辑: ${config_file}${NC}"
}

# 启动服务
start_service() {
    echo -e "${BLUE}🚀 启动 PMHQ 服务...${NC}"
    
    cd "${INSTALL_DIR}"
    
    # 停止旧容器（如果存在）
    docker-compose down 2>/dev/null || true
    
    # 启动新容器
    if docker-compose up -d; then
        echo -e "${GREEN}✅ PMHQ 服务启动成功${NC}"
        echo ""
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${GREEN}  PMHQ 安装/更新完成！${NC}"
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo "📋 服务信息:"
        echo "  • 容器名称: pmhq"
        echo "  • Gateway 地址: http://localhost:13010"
        echo "  • Probe Proxy 端口: 13000"
        echo ""
        echo "📁 目录结构:"
        echo "  • 安装目录: ${INSTALL_DIR}"
        echo "  • QQ 数据: ${INSTALL_DIR}/qq_data"
        echo "  • 配置文件: ${INSTALL_DIR}/config/pmhq_config.json"
        echo ""
        echo "🔧 常用命令:"
        echo "  • 查看日志: docker logs -f pmhq"
        echo "  • 停止服务: docker-compose down"
        echo "  • 重启服务: docker-compose restart"
        echo "  • 更新版本: bash ${INSTALL_DIR}/install.sh"
        echo ""
        # 等待服务启动
        echo -e "${BLUE}⏳ 等待服务初始化 (约60秒)...${NC}"
        sleep 5
        
        # 检查健康状态
        for i in {1..12}; do
            if curl -s http://localhost:13010/healthz &>/dev/null; then
                echo -e "${GREEN}✅ Gateway 健康检查通过${NC}"
                break
            fi
            echo -n "."
            sleep 5
        done
        echo ""
    else
        echo -e "${RED}❌ 服务启动失败${NC}"
        echo "请检查日志: docker logs pmhq"
        exit 1
    fi
}

# 检查更新
check_update() {
    local current_version=$(get_local_version)
    local latest_version=$(get_latest_version)
    
    echo -e "${BLUE}📊 版本检查${NC}"
    echo "  当前版本: ${current_version}"
    echo "  最新版本: ${latest_version}"
    
    if [ "$current_version" != "$latest_version" ]; then
        echo -e "${YELLOW}🔄 发现新版本，准备更新...${NC}"
        return 0
    else
        echo -e "${GREEN}✅ 当前已是最新版本${NC}"
        read -p "是否强制重新安装? (y/N): " force_reinstall
        if [[ $force_reinstall =~ ^[Yy]$ ]]; then
            return 0
        fi
        return 1
    fi
}

# 显示使用说明
show_usage() {
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}       PMHQ Docker 安装工具${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "用法:"
    echo "  bash install.sh [选项] [版本号]"
    echo ""
    echo "选项:"
    echo "  -h, --help       显示帮助信息"
    echo "  -f, --force      强制重新安装（忽略版本检查）"
    echo "  -v, --version    指定安装版本（默认: 最新）"
    echo "  --check-only     仅检查更新，不执行安装"
    echo ""
    echo "示例:"
    echo "  # 安装最新版本"
    echo "  bash install.sh"
    echo ""
    echo "  # 安装指定版本"
    echo "  bash install.sh 7.3.2-silk-v2"
    echo ""
    echo "  # 强制重新安装"
    echo "  bash install.sh -f"
    echo ""
    echo "  # 仅检查更新"
    echo "  bash install.sh --check-only"
    echo ""
    echo "环境变量（自定义镜像源）:"
    echo "  PMHQ_IMAGE        完整镜像名称（优先级最高）"
    echo "                    例如: docker.io/username/pmhq"
    echo "  PMHQ_REGISTRY     镜像仓库地址"
    echo "                    默认: registry.cn-hangzhou.aliyuncs.com"
    echo "  PMHQ_NAMESPACE    命名空间"
    echo "                    默认: docker_git_aliyun"
    echo "  PMHQ_REPO         仓库名称"
    echo "                    默认: pmhq"
    echo "  PMHQ_INSTALL_DIR  安装目录"
    echo "                    默认: /root/dev_pmh"
    echo ""
    echo "示例（使用其他镜像源）:"
    echo "  # 使用 Docker Hub 镜像"
    echo "  PMHQ_REGISTRY=docker.io PMHQ_NAMESPACE=username bash install.sh"
    echo ""
    echo "  # 使用完整镜像名"
    echo "  PMHQ_IMAGE=docker.io/username/pmhq bash install.sh"
    echo ""
}

# 显示主菜单
show_menu() {
    local current_version=$(get_local_version)
    local latest_version=$(get_latest_version)
    local image_source
    if [ -n "$FULL_IMAGE" ]; then
        image_source="$FULL_IMAGE"
    else
        image_source="${REGISTRY}/${NAMESPACE}/${REPO_NAME}"
    fi
    
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}    PMHQ Docker 安装/更新工具${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "${BLUE}当前配置:${NC}"
    echo "  镜像源: ${image_source}"
    echo "  安装目录: ${INSTALL_DIR}"
    if [ "$current_version" != "none" ]; then
        echo "  当前版本: ${current_version}"
        if [ "$current_version" != "$latest_version" ]; then
            echo -e "  ${YELLOW}⚠️  发现新版本: ${latest_version}${NC}"
        else
            echo -e "  ${GREEN}✅ 已是最新版本${NC}"
        fi
    else
        echo "  当前版本: ${YELLOW}未安装${NC}"
        echo "  最新版本: ${latest_version}"
    fi
    echo ""
    echo "操作选项:"
    echo "  1. 安装/更新到最新版本"
    echo "  2. 安装指定版本"
    echo "  3. 强制重新安装当前版本"
    echo "  4. 修改镜像源配置"
    echo "  5. 仅检查更新（不安装）"
    echo "  6. 查看本地安装信息"
    echo "  7. 停止/卸载服务"
    echo "  8. 查看帮助"
    echo "  0. 退出"
    echo ""
}

# 安装指定版本流程
do_install() {
    local version=$1
    local force=$2
    
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}开始安装 PMHQ ${version}${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    
    # 检查是否需要更新
    if [ "$force" = false ] && [ -d "$INSTALL_DIR" ] && [ -f "${INSTALL_DIR}/.version" ]; then
        local current=$(get_local_version)
        if [ "$current" = "$version" ]; then
            echo -e "${YELLOW}⚠️  版本 ${version} 已安装，选择强制重新安装以继续${NC}"
            read -p "是否强制重新安装? (y/N): " confirm
            if [[ ! $confirm =~ ^[Yy]$ ]]; then
                echo "已取消"
                return 1
            fi
        fi
    fi
    
    # 执行安装流程
    check_docker
    setup_directories
    login_registry
    
    if pull_image "$version"; then
        save_version "$version"
        create_compose_file "$version"
        create_default_config
        start_service
        echo ""
        read -p "按回车键继续..."
    else
        echo -e "${RED}❌ 安装失败${NC}"
        read -p "按回车键继续..."
        return 1
    fi
}

# 修改配置
change_config() {
    echo ""
    echo -e "${BLUE}当前镜像配置:${NC}"
    if [ -n "$FULL_IMAGE" ]; then
        echo "  完整镜像名: $FULL_IMAGE"
    else
        echo "  仓库: $REGISTRY"
        echo "  命名空间: $NAMESPACE"
        echo "  仓库名: $REPO_NAME"
    fi
    echo "  安装目录: $INSTALL_DIR"
    echo ""
    echo "配置选项:"
    echo "  1. 使用完整镜像名（如 docker.io/username/pmhq）"
    echo "  2. 分别配置仓库/命名空间/仓库名"
    echo "  3. 修改安装目录"
    echo "  0. 返回主菜单"
    echo ""
    read -p "请选择 [0-3]: " config_choice
    
    case $config_choice in
        1)
            read -p "请输入完整镜像名 (如 docker.io/username/pmhq): " new_image
            if [ -n "$new_image" ]; then
                FULL_IMAGE="$new_image"
                # 清空其他配置
                REGISTRY=""
                NAMESPACE=""
                REPO_NAME=""
                echo -e "${GREEN}✅ 已设置完整镜像名: $FULL_IMAGE${NC}"
            fi
            ;;
        2)
            read -p "请输入镜像仓库地址 [${REGISTRY}]: " new_registry
            read -p "请输入命名空间 [${NAMESPACE}]: " new_namespace
            read -p "请输入仓库名 [${REPO_NAME}]: " new_repo
            REGISTRY="${new_registry:-$REGISTRY}"
            NAMESPACE="${new_namespace:-$NAMESPACE}"
            REPO_NAME="${new_repo:-$REPO_NAME}"
            # 清空完整镜像名
            FULL_IMAGE=""
            echo -e "${GREEN}✅ 已更新镜像配置${NC}"
            ;;
        3)
            read -p "请输入新的安装目录 [${INSTALL_DIR}]: " new_dir
            if [ -n "$new_dir" ]; then
                INSTALL_DIR="$new_dir"
                echo -e "${GREEN}✅ 已设置安装目录: $INSTALL_DIR${NC}"
            fi
            ;;
        0)
            return
            ;;
    esac
    read -p "按回车键继续..."
}

# 查看安装信息
show_info() {
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}      PMHQ 安装信息${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    
    if [ -d "$INSTALL_DIR" ]; then
        echo -e "${BLUE}安装目录:${NC} ${INSTALL_DIR}"
        ls -la "$INSTALL_DIR" 2>/dev/null || echo "  (目录存在但无法读取详情)"
        echo ""
    else
        echo -e "${YELLOW}⚠️  安装目录不存在${NC}"
        echo ""
        return
    fi
    
    local version=$(get_local_version)
    if [ "$version" != "none" ]; then
        echo -e "${BLUE}当前版本:${NC} ${version}"
    else
        echo -e "${YELLOW}未记录版本信息${NC}"
    fi
    
    # 检查容器状态
    echo ""
    echo -e "${BLUE}容器状态:${NC}"
    docker ps --filter "name=pmhq" --format "  名称: {{.Names}}\n  状态: {{.Status}}\n  端口: {{.Ports}}" 2>/dev/null || echo "  容器未运行"
    
    echo ""
    read -p "按回车键继续..."
}

# 停止/卸载服务
uninstall_service() {
    echo ""
    echo -e "${YELLOW}⚠️  停止/卸载 PMHQ 服务${NC}"
    echo ""
    
    if [ -d "$INSTALL_DIR" ]; then
        echo "安装目录: $INSTALL_DIR"
        echo ""
        echo "选项:"
        echo "  1. 仅停止服务（保留数据和配置）"
        echo "  2. 停止并删除容器（保留数据卷）"
        echo "  3. 完全卸载（删除所有数据，⚠️危险）"
        echo "  0. 取消"
        echo ""
        read -p "请选择 [0-3]: " uninstall_choice
        
        case $uninstall_choice in
            1)
                cd "$INSTALL_DIR" && docker-compose stop 2>/dev/null || docker stop pmhq 2>/dev/null || true
                echo -e "${GREEN}✅ 服务已停止${NC}"
                ;;
            2)
                cd "$INSTALL_DIR" && docker-compose down 2>/dev/null || docker rm -f pmhq 2>/dev/null || true
                echo -e "${GREEN}✅ 容器已删除，数据已保留${NC}"
                ;;
            3)
                echo -e "${RED}⚠️  警告: 这将删除所有数据！${NC}"
                read -p "输入 'yes' 确认完全卸载: " confirm
                if [ "$confirm" = "yes" ]; then
                    cd "$INSTALL_DIR" && docker-compose down -v 2>/dev/null || true
                    rm -rf "$INSTALL_DIR"
                    echo -e "${GREEN}✅ PMHQ 已完全卸载${NC}"
                else
                    echo "已取消"
                fi
                ;;
            0)
                echo "已取消"
                ;;
        esac
    else
        echo -e "${YELLOW}未找到安装目录${NC}"
    fi
    read -p "按回车键继续..."
}

# 检测是否通过管道运行
is_pipe_mode() {
    # 方法1: 检测stdin是否是终端
    if ! test -t 0 2>/dev/null; then
        return 0
    fi
    # 方法2: 检测stdin是否是管道
    if [ -p /dev/stdin ] 2>/dev/null; then
        return 0
    fi
    return 1
}

# 主函数
main() {
    # 如果是管道运行且没有参数，默认执行安装
    if is_pipe_mode && [ $# -eq 0 ]; then
        echo ""
        echo -e "${YELLOW}⚠️  检测到通过管道运行 (curl ... | bash)${NC}"
        echo ""
        echo -e "${BLUE}正在自动安装最新版本...${NC}"
        echo ""
        do_install "$(get_latest_version)" false
        exit $?
    fi
    
    # 处理命令行参数（兼容非交互模式）
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            --check-only)
                check_update
                exit 0
                ;;
            -f|--force)
                # 强制安装指定版本或最新版本
                shift
                local force_version="${1:-$(get_latest_version)}"
                do_install "$force_version" true
                exit $?
                ;;
            -*)
                echo -e "${RED}❌ 未知选项: $1${NC}"
                show_usage
                exit 1
                ;;
            *)
                # 直接安装指定版本
                do_install "$1" false
                exit $?
                ;;
        esac
    done
    
    # 交互式菜单
    while true; do
        show_menu
        read -p "请选择操作 [0-8]: " choice
        
        case $choice in
            1)
                do_install "$(get_latest_version)" false
                ;;
            2)
                echo ""
                read -p "请输入要安装的版本号 (如 7.3.2-silk-v2): " input_version
                if [ -n "$input_version" ]; then
                    do_install "$input_version" false
                fi
                ;;
            3)
                local current=$(get_local_version)
                if [ "$current" != "none" ]; then
                    do_install "$current" true
                else
                    echo -e "${YELLOW}⚠️  未找到当前版本，请使用选项1或2${NC}"
                    read -p "按回车键继续..."
                fi
                ;;
            4)
                change_config
                ;;
            5)
                check_update
                read -p "按回车键继续..."
                ;;
            6)
                show_info
                ;;
            7)
                uninstall_service
                ;;
            8)
                show_usage
                read -p "按回车键继续..."
                ;;
            0)
                echo ""
                echo -e "${GREEN}再见！${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}❌ 无效选项: $choice${NC}"
                read -p "按回车键继续..."
                ;;
        esac
    done
}

# 运行主函数
main "$@"
