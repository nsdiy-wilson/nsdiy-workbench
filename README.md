# nsdiy-workbench

Go + Gin 后端 + Vue 3 前端的博客系统，打包为单个二进制文件部署。

## 快速开始

### 本地开发

```bash
# 启动后端（监听 :8888，自动建表+种子用户）
cd server
go run .

# 启动读者前台（另一个终端，监听 :5173）
cd web
npm install
npm run dev

# 启动管理后台（另一个终端，监听 :5174）
cd admin
npm install
npm run dev
```

默认管理员：`admin` / `admin123`

## 部署

### 方式一：一键安装（推荐）

```bash
# wget
wget -qO- https://raw.githubusercontent.com/nsdiy-wilson/nsdiy-workbench/main/deploy/install.sh | sudo bash

# curl
curl -fsSL https://raw.githubusercontent.com/nsdiy-wilson/nsdiy-workbench/main/deploy/install.sh | sudo bash
```

脚本会自动从 GitHub Release 下载最新版本，校验 SHA256，安装到 `/opt/nsdiy-workbench`，并启动 systemd 服务。

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

### 方式三：使用 systemd 管理

```bash
# 复制服务文件
sudo cp /opt/nsdiy-workbench/nsdiy-workbench.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now nsdiy-workbench

# 查看状态
sudo systemctl status nsdiy-workbench
sudo journalctl -u nsdiy-workbench -f
```

## 开发者：打包发布

```bash
# 1. 构建前端
cd web && npm run build && cd ..
cd admin && npm run build && cd ..

# 2. 拷贝前端产物
rm -rf server/packfile/web_dist server/packfile/admin_dist
cp -r web/dist server/packfile/web_dist
cp -r admin/dist server/packfile/admin_dist

# 3. 打包（Linux 二进制 + config.yaml + service）
./deploy/local_package.ps1

# 4. 发布到 GitHub Release
# - 修改 server/version/base_version.go 中的 AppVersion
# - 上传 deploy/output/ 下的 .tar.gz 和 checksums.txt
```
