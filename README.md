# nsdiy-workbench

**wilson-blog** 的 GitHub 发布仓库。源码维护在 [Gitee](https://gitee.com/zhouws-chn/wilson-blog)，本仓库仅用于版本发布和一键部署。

wilson-blog 是一个轻量级博客系统，基于 Go + Gin 后端和 Vue 3 前端，打包为单个二进制文件部署，内置 SQLite（WAL 模式），无需额外数据库服务。

## 特性

- 单二进制部署：前端产物内嵌，无需 Nginx
- SQLite WAL 模式：零外部依赖，2G 内存即可运行
- 一键安装：`install.sh` 自动下载、校验、配置 systemd
- 首次安装自动生成 JWT 密钥，升级时保留已有配置和数据

## 快速安装

需要 Linux amd64 服务器，root 权限。

```bash
wget -O install.sh https://raw.githubusercontent.com/nsdiy-wilson/nsdiy-workbench/master/deploy/install.sh
sudo bash install.sh
```

脚本自动完成：

1. 查询 GitHub 最新 Release
2. 下载压缩包
3. SHA256 校验
4. 解压到 `/opt/wilson-blog/`
5. 首次安装生成 JWT 签名密钥
6. 安装并启动 systemd 服务

安装完成后访问 `http://<服务器IP>:8888`。

默认管理员账号：`admin` / `admin123`

## 目录结构

部署后的目录布局：

```
/opt/wilson-blog/
├── wilson-blog          # 可执行文件
├── config.yaml          # 运行配置
├── wilson-blog.service  # systemd 服务文件
└── data/                # 需要备份的数据目录
    ├── wilson.db         # SQLite 数据库（WAL 模式）
    └── uploads/          # 用户上传文件
```

## 配置说明

编辑 `/opt/wilson-blog/config.yaml`：

| 配置项 | 说明 | 默认值 |
|--------|------|--------|
| `server.addr` | 监听地址 | `:8888` |
| `server.data-path` | 数据目录 | `./data` |
| `jwt.signing-key` | JWT 签名密钥（首次安装自动生成） | — |
| `jwt.expires-time` | Token 有效期 | `168h`（7天） |
| `upload.max-file-size` | 上传文件大小限制 | `10485760`（10MB） |
| `cors.allowed-origins` | 允许的跨域来源 | `[]` |
| `log.level` | 日志级别 | `info` |

修改配置后重启服务生效：

```bash
systemctl restart wilson-blog
```

## 常用命令

```bash
# 查看状态
systemctl status wilson-blog

# 重启服务
systemctl restart wilson-blog

# 查看实时日志
journalctl -u wilson-blog -f

# 查看最近日志
journalctl -u wilson-blog -n 100
```

## 备份与恢复

`data/` 目录包含所有业务数据，定期备份即可：

```bash
# 备份
tar -czf backup-$(date +%Y%m%d).tar.gz /opt/wilson-blog/data

# 恢复：将备份解压回 data/ 目录，重启服务
systemctl restart wilson-blog
```

## 资源占用

- 常驻内存：约 30–60MB
- 磁盘：二进制约 20MB，数据随使用增长
- 适用配置：2 核 2G 即可稳定运行

## 版本发布说明

### v1.0.0

首个正式版本。

- Go + Gin 后端 + Vue 3 前端，单二进制部署
- SQLite WAL 模式，内置博客核心功能
- 管理后台 + 读者前台
- 一键安装脚本，systemd 服务管理
- 上传图片限制与 CORS 配置

## 源码

源码仓库：https://gitee.com/zhouws-chn/wilson-blog

## License

See [Gitee repository](https://gitee.com/zhouws-chn/wilson-blog) for license information.
