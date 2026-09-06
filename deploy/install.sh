#!/usr/bin/env bash
# wilson-blog 一键安装 / 升级脚本
# 用法: sudo bash install.sh
set -euo pipefail

REPO="nsdiy-wilson/nsdiy-workbench"
SVC="wilson-blog"
DIR="/opt/wilson-blog"
CFG="$DIR/config.yaml"

info()  { echo "[INFO] $*"; }
error() { echo "[ERROR] $*" >&2; exit 1; }

[[ $EUID -eq 0 ]] || error "请使用 root 或 sudo 执行"
command -v wget &>/dev/null || error "缺少 wget"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# 最新版本
info "查询最新版本..."
RESP=$(wget -qO- --timeout=15 "https://api.github.com/repos/$REPO/releases/latest" || true)
TAG=$(echo "$RESP" | grep -o '"tag_name": *"[^"]*"' | head -1 | cut -d'"' -f4)
[[ -n "$TAG" ]] || error "获取最新版本失败"
FILE=$(echo "$RESP" | grep -o '"name": "[^"]*\.tar\.gz"' | head -1 | cut -d'"' -f4)
BASE="https://github.com/$REPO/releases/download/$TAG"

# 下载
info "下载 $TAG ..."
wget -q --show-progress --timeout=60 -O "$TMP/pkg.tar.gz" "$BASE/${FILE:-wilson-blog-linux-amd64-$TAG.tar.gz}" || error "下载失败"

# SHA256 校验
wget -q --timeout=10 -O "$TMP/checksums.txt" "$BASE/checksums.txt" || error "checksums.txt 下载失败"
EXPECT=$(grep -m1 'linux-amd64.*\.tar\.gz' "$TMP/checksums.txt" | awk '{print $1}')
[[ -n "$EXPECT" ]] || error "checksums.txt 中没有压缩包记录"
[[ "$EXPECT" == "$(sha256sum "$TMP/pkg.tar.gz" | awk '{print $1}')" ]] || error "SHA256 校验失败"
info "校验通过"

# 停服并解压（已有 config.yaml 原样保留）
systemctl is-active --quiet "$SVC" 2>/dev/null && systemctl stop "$SVC"
mkdir -p "$DIR"
[[ -f "$CFG" ]] && cp "$CFG" "$TMP/config.bak"
tar -xzf "$TMP/pkg.tar.gz" -C "$DIR"
[[ -f "$TMP/config.bak" ]] && mv -f "$TMP/config.bak" "$CFG"
chmod +x "$DIR/wilson-blog"

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
