# nsdiy-workbench

Go + Gin 后端 + Vue 3 前端的博客系统，打包为单个二进制文件部署。

## 部署

### 方式一：一键安装（推荐）

```bash
# wget
wget -qO- https://raw.githubusercontent.com/nsdiy-wilson/nsdiy-workbench/main/deploy/install.sh | sudo bash

# curl
curl -fsSL https://raw.githubusercontent.com/nsdiy-wilson/nsdiy-workbench/main/deploy/install.sh | sudo bash
```

脚本会自动从 GitHub Release 下载最新版本，校验 SHA256，安装到 `/opt/nsdiy-workbench`，并启动 systemd 服务。

- 程序目录：`/opt/nsdiy-workbench/`
- 数据目录：`/opt/nsdiy-workbench/data/`（数据库和上传文件）
- 配置文件：`/opt/nsdiy-workbench/config.yaml`
- 查看日志：`sudo journalctl -u nsdiy-workbench -f`

### 方式二：手动部署

1. 从 [GitHub Releases](https://github.com/nsdiy-wilson/nsdiy-workbench/releases) 下载最新 `linux-amd64` 压缩包
2. 解压到目标目录：
   ```bash
   mkdir -p /opt/nsdiy-workbench
   tar -xzf nsdiy-workbench-linux-amd64-*.tar.gz -C /opt/nsdiy-workbench
   ```
3. 编辑 `config.yaml`，修改以下配置：
   - `jwt.signing-key`：替换为随机密钥（首次安装会自动生成）
   - `server.data-path`：数据存储路径（如 `/opt/nsdiy-workbench/data`）
4. 启动服务：
   ```bash
   /opt/nsdiy-workbench/nsdiy-workbench
   ```

如需使用 systemd 管理：

```bash
sudo cp /opt/nsdiy-workbench/nsdiy-workbench.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now nsdiy-workbench

# 查看状态
sudo systemctl status nsdiy-workbench
```

## 日志

```bash
# 实时查看日志
sudo journalctl -u nsdiy-workbench -f

# 查看最近 100 行日志
sudo journalctl -u nsdiy-workbench -n 100

# 查看今天日志
sudo journalctl -u nsdiy-workbench --since today
```
