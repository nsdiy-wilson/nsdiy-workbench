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

## 打包部署

### 方式一：一键打包（推荐）

```bash
# Linux/macOS
./deploy/local_package.sh

# Windows
.\deploy\local_package.ps1
```

产物：`deploy/output/nsdiy-workbench-linux-amd64-<版本>_build<日期>.tar.gz`（另有 `checksums.txt`、`version.json`），包含 Linux amd64 二进制 + `config.yaml` + systemd 单元文件。

> 打包脚本只编译 Go 二进制，**不构建前端**。前端有改动时，必须先执行下方「方式二」的前两步把产物拷进 `server/packfile/`，否则二进制里内嵌的仍是旧前端。

### 方式二：手动构建

前端产物需要更新时执行（也可单独执行，再回到方式一打包）：

```bash
# 1. 构建前端
cd web && npm run build && cd ..
cd admin && npm run build && cd ..

# 2. 拷贝产物
rm -rf server/packfile/web_dist server/packfile/admin_dist
cp -r web/dist server/packfile/web_dist
cp -r admin/dist server/packfile/admin_dist

# 3. 编译二进制（内嵌前端）
cd server
go build -trimpath -ldflags="-s -w" -o nsdiy-workbench .
```

### 部署

1. 上传二进制到服务器
2. 放置 `config.yaml`（修改 `jwt.signing-key` 和 `server.data-path`）
3. 运行：`./nsdiy-workbench`

详细部署说明见 [deploy/README.md](deploy/README.md)

### 发布到 GitHub Release

```bash
# 1. 修改版本号（仅需在发布前修改一次）
# 编辑 server/version/base_version.go 中的 AppVersion
# 例如：const AppVersion = "v1.0.0"

# 2. 打包（编译 Linux 二进制 + config.yaml + service，输出到 deploy/output/）
# Windows: .\deploy\local_package.ps1
.\deploy\local_package.ps1

# 3. 手动上传到 GitHub Release
# - 访问 https://github.com/zhouws-chn/nsdiy-workbench/releases/new
# - 选择/创建 tag（如 v1.0.0）
# - 填写 Release title 和描述
# - 上传 deploy/output/ 下的 .tar.gz，以及 checksums.txt（安装脚本强依赖，必须一起传）
# - 发布
```
