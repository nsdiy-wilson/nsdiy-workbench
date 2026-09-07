#!/usr/bin/env bash
# nsdiy-workbench 首次安装脚本（重复执行会自动拒绝，升级请手动替换二进制）
# 用法: sudo bash install.sh
set -euo pipefail

REPO="nsdiy-wilson/nsdiy-workbench"
SVC="nsdiy-workbench"
DIR="/opt/nsdiy-workbench"
CFG="$DIR/config.yaml"

info()  { echo "[INFO] $*"; }
error() { echo "[ERROR] $*" >&2; exit 1; }

[[ $EUID -eq 0 ]] || error "请使用 root 或 sudo 执行"
for cmd in wget tar sha256sum systemctl; do
    command -v "$cmd" &>/dev/null || error "缺少 $cmd"
done

# 检测是否已安装，禁止重复执行
if [[ -f "$DIR/nsdiy-workbench" ]] || systemctl list-unit-files --quiet "$SVC.service" 2>/dev/null; then
    error "检测到已安装 nsdiy-workbench，本脚本仅用于首次安装。升级请手动下载新版本压缩包并替换二进制。"
fi

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# 最新版本
info "查询最新版本..."
RESP=$(wget -qO- --timeout=15 "https://api.github.com/repos/$REPO/releases/latest" || true)
TAG=$(echo "$RESP" | grep -o '"tag_name": *"[^"]*"' | head -1 | cut -d'"' -f4)
[[ -n "$TAG" ]] || error "获取最新版本失败"
BASE="https://github.com/$REPO/releases/download/$TAG"

# 先取校验清单：文件名带 _build<日期> 后缀，本地拼不出来，一律以清单为准
info "下载校验清单..."
wget -q --timeout=10 -O "$TMP/checksums.raw" "$BASE/checksums.txt" || error "checksums.txt 下载失败"
# Windows 侧打包可能写入 CRLF，统一清理后再解析
tr -d '\r' < "$TMP/checksums.raw" > "$TMP/checksums.txt"
FILE=$(grep -m1 -o '[^ ]*linux-amd64[^ ]*\.tar\.gz' "$TMP/checksums.txt")
[[ -n "$FILE" ]] || error "checksums.txt 中没有 linux-amd64 压缩包记录"

# 下载
info "下载 $TAG ($FILE) ..."
wget -q --show-progress --timeout=60 -O "$TMP/pkg.tar.gz" "$BASE/$FILE" || error "下载失败"

# SHA256 校验（只保留十六进制字符，避免 BOM 干扰比对）
EXPECT=$(awk -v f="$FILE" '$2==f {print $1; exit}' "$TMP/checksums.txt" | tr -cd '0-9a-fA-F')
[[ -n "$EXPECT" ]] || error "checksums.txt 中没有 $FILE 的校验和"
[[ "$EXPECT" == "$(sha256sum "$TMP/pkg.tar.gz" | awk '{print $1}')" ]] || error "SHA256 校验失败"
info "校验通过"

# 解压（已有 config.yaml 原样保留，避免覆盖 JWT 密钥）
mkdir -p "$DIR"
if [[ -f "$CFG" ]]; then
    cp "$CFG" "$TMP/config.bak"
fi
tar -xzf "$TMP/pkg.tar.gz" -C "$DIR"
if [[ -f "$TMP/config.bak" ]]; then
    mv -f "$TMP/config.bak" "$CFG"
fi
chmod +x "$DIR/nsdiy-workbench"

# 首次安装生成 JWT 密钥
if [[ -f "$CFG" ]] && grep -q 'REPLACE_ME_WITH_RANDOM_KEY' "$CFG"; then
    sed -i "s|REPLACE_ME_WITH_RANDOM_KEY|$(head -c 32 /dev/urandom | base64 | tr -d '\n')|" "$CFG"
    info "已生成 JWT 签名密钥"
fi

# 安装服务并启动
cp "$DIR/$SVC.service" "/etc/systemd/system/$SVC.service"
systemctl daemon-reload
systemctl enable --now "$SVC"
sleep 3
systemctl is-active --quiet "$SVC" || error "启动失败: journalctl -u $SVC -n 50"
info "安装完成 $TAG -> $DIR"
