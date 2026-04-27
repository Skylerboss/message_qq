# PMHQ Docker 一键安装脚本

[![Docker Image](https://img.shields.io/badge/Docker-阿里云镜像-blue)](https://cr.console.aliyun.com/)
[![Version](https://img.shields.io/badge/Version-7.3.2--silk--v2-green)]()

> PMHQ (QQ Message Gateway) Docker 容器化部署方案，支持自动 Silk 语音编码

## 特性

- ✅ 一键安装/更新 PMHQ 服务
- ✅ 支持自定义镜像源（阿里云、Docker Hub 等）
- ✅ 交互式菜单操作
- ✅ 自动检测版本更新
- ✅ 完整的安装/卸载功能
- ✅ 内置 Silk 语音编码支持（无需本地依赖）
- ✅ 自动生成 Access Token，支持 API 认证

## 快速开始

### 一键安装

```bash
curl -fsSL https://raw.githubusercontent.com/Skylerboss/message_qq/main/install.sh | bash
```

### 手动下载安装

```bash
wget https://raw.githubusercontent.com/Skylerboss/message_qq/main/install.sh
bash install.sh
```

## 使用方法

### 交互式菜单（推荐）

直接运行脚本进入交互菜单：

```bash
bash install.sh
```

菜单选项：
| 选项 | 功能 |
|-----|------|
| 1 | 安装/更新到最新版本 |
| 2 | 安装指定版本 |
| 3 | 强制重新安装当前版本 |
| 4 | 修改配置（镜像源/目录/Token） |
| 5 | 仅检查更新 |
| 6 | 查看本地安装信息 |
| 7 | 停止/卸载服务 |
| 8 | 查看帮助 |
| 0 | 退出 |

**安装完成后会显示：**
- Gateway 地址：`http://localhost:13010`
- Access Token：安装时自动生成（默认 `sky2025`）
- Message Bot 配置参考：Runtime 地址、媒体桥接地址、Token

### 命令行参数

```bash
# 安装最新版本
bash install.sh

# 安装指定版本
bash install.sh 7.3.2-silk-v2

# 强制重新安装
bash install.sh -f

# 查看帮助
bash install.sh -h
```

### 自定义镜像源

```bash
# 使用 Docker Hub 镜像
PMHQ_REGISTRY=docker.io PMHQ_NAMESPACE=username bash install.sh

# 或使用完整镜像名
PMHQ_IMAGE=docker.io/username/pmhq bash install.sh
```

## 环境变量

| 变量 | 说明 | 默认值 |
|-----|------|--------|
| `PMHQ_IMAGE` | 完整镜像名称 | - |
| `PMHQ_REGISTRY` | 镜像仓库地址 | `registry.cn-hangzhou.aliyuncs.com` |
| `PMHQ_NAMESPACE` | 命名空间 | `docker_git_aliyun` |
| `PMHQ_REPO` | 仓库名称 | `pmhq` |
| `PMHQ_INSTALL_DIR` | 安装目录 | `/root/dev_pmh` |
| `PMHQ_ACCESS_TOKEN` | API 访问 Token | `sky2025` |

### 自定义 Access Token

```bash
# 安装时指定自定义 Token
PMHQ_ACCESS_TOKEN=mysecret2025 bash install.sh

# 或安装后通过菜单修改（选项4）
bash install.sh
# 选择 4. 修改配置（镜像源/目录/Token）
# 选择 4. 修改 Access Token
```

## 目录结构

安装完成后生成以下目录结构：

```
/root/dev_pmh/
├── docker-compose.yml      # Docker Compose 配置
├── .version               # 当前版本记录
├── config/
│   ├── pmhq_config.json   # PMHQ 配置文件
│   └── .access_token      # Access Token（仅所有者可读写）
├── qq_data/               # QQ 数据持久化
└── plugins/               # 插件目录
```

## 服务端口与配置

| 端口 | 服务 | 说明 |
|-----|------|------|
| 13000 | Probe Proxy | QQ 协议代理 |
| 13010 | Gateway | API 网关 |

### Message Bot 对接配置

安装完成后，在 Message Bot 后台配置：

| 配置项 | 值 |
|-----|------|
| Message_QQ 协议 | 内置容器 |
| Runtime 地址 | `http://服务器IP:13010` |
| 统一访问 Token | `sky2025`（或自定义的 Token） |
| 媒体桥接地址 | `http://服务器IP:13010/fetch` |
| 媒体桥接 Token | 与统一访问 Token 相同 |

**查看 Token：**
```bash
cat /root/dev_pmh/config/.access_token
```

## 常用命令

```bash
cd /root/dev_pmh

# 查看日志
docker logs -f pmhq

# 停止服务
docker-compose down

# 重启服务
docker-compose restart

# 更新到最新版本
bash install.sh
```

## 镜像构建

如需自行构建镜像：

```bash
cd docker/pmhq
docker build -t pmhq:custom .
```

## 注意事项

1. 确保服务器已安装 Docker 和 Docker Compose
2. 阿里云镜像可能需要登录，Docker Hub 镜像可直接拉取
3. 首次启动可能需要 60 秒左右初始化
4. QQ 数据保存在 `qq_data` 目录，删除容器不会丢失

## 相关项目

- [PMHQ 官方仓库](https://github.com/linyuchen/PMHQ)

## License

MIT License
