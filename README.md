# Message_QQ PMHQ Docker 一键安装脚本

[![Docker Image](https://img.shields.io/badge/Docker-阿里云镜像-blue)](https://cr.console.aliyun.com/)
[![Version](https://img.shields.io/badge/Version-7.3.4--message--qq--transfer--v2-green)]()

> 面向 `Message_QQ` 的 PMHQ Docker 容器化部署方案，支持交互式安装、版本升级、媒体桥接与自动 Silk 语音编码。

## 特性

- ✅ 一键安装/更新 PMHQ 服务
- ✅ 支持自定义镜像源（阿里云、Docker Hub 等）
- ✅ 交互式菜单操作
- ✅ 自动检测版本更新
- ✅ 完整的安装/卸载功能
- ✅ 内置 Silk 语音编码支持（无需本地依赖）
- ✅ 自动生成 Access Token，支持 API 认证
- ✅ 自动处理同名旧容器冲突（`pmhq`）

## 当前推荐脚本

当前仓库中推荐用于 GitHub 发布和用户安装的脚本是：

```text
用户安装/install_message_qq.sh
```

默认安装版本：

```text
7.3.4-message-qq-transfer-v2
```

默认镜像地址：

```text
registry.cn-hangzhou.aliyuncs.com/docker_git_aliyun/pmhq:7.3.4-message-qq-transfer-v2
```

说明：

1. 该版本已包含 `Message_QQ` 当前可发布的主链修复与安装脚本冲突兜底。
2. 私聊图片/视频转发测试链已验证通过。
3. QQ 内部图 OCR 仍在继续优化中，当前版本不承诺“内部图 OCR 完全稳定”。

## 旧脚本说明

以下脚本属于旧的 `PMHQ + LLBot` 安装方案，不再作为当前 `Message_QQ` 推荐安装入口：

```text
用户安装/一键PMHQ + LLBot旧版QQ安装Pinstall_qq_bot.sh
```

如果你的目标是部署当前 `Message_QQ` 方案，请优先使用 `install_message_qq.sh`。

## 快速开始

### 一键安装

```bash
curl -fsSL https://raw.githubusercontent.com/Skylerboss/message_qq/main/用户安装/install_message_qq.sh | bash
```

### 手动下载安装

```bash
wget https://raw.githubusercontent.com/Skylerboss/message_qq/main/用户安装/install_message_qq.sh
bash install_message_qq.sh
```

## 使用方法

### 交互式菜单（推荐）

直接运行脚本进入交互菜单：

```bash
bash install_message_qq.sh
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
bash install_message_qq.sh

# 安装指定版本
bash install_message_qq.sh 7.3.4-message-qq-transfer-v2

# 强制重新安装
bash install_message_qq.sh -f

# 查看帮助
bash install_message_qq.sh -h
```

### 自定义镜像源

```bash
# 使用 Docker Hub 镜像
PMHQ_REGISTRY=docker.io PMHQ_NAMESPACE=username bash install_message_qq.sh

# 或使用完整镜像名
PMHQ_IMAGE=docker.io/username/pmhq bash install_message_qq.sh
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
PMHQ_ACCESS_TOKEN=mysecret2025 bash install_message_qq.sh

# 或安装后通过菜单修改（选项4）
bash install_message_qq.sh
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
| 13000 | Probe Proxy | PMHQ 协议代理层 |
| 13010 | Gateway | Message_QQ 主网关 |

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
bash install_message_qq.sh
```

## 镜像构建

如需自行构建镜像：

```bash
cd docker/pmhq
docker build -t pmhq:custom .
```

## 注意事项

1. 确保服务器已安装 Docker 和 Docker Compose
2. 默认使用阿里云公开镜像仓库，一般无需手动登录
3. 首次启动可能需要 60 秒左右初始化
4. QQ 数据保存在 `qq_data` 目录，删除容器不会丢失
5. 如果系统中已存在旧的 `pmhq` 同名容器，脚本会提示是否自动清理冲突容器

## 相关项目

- [PMHQ 官方仓库](https://github.com/linyuchen/PMHQ)

## License

MIT License
