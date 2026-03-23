#!/usr/bin/env bash
set -euo pipefail

# ===============================
# 设置 sagernet APT 源
# ===============================
echo "✅ 创建 APT keyrings 目录..."
sudo mkdir -p /etc/apt/keyrings

echo "✅ 下载 sagernet GPG key..."
sudo curl -fsSL https://sing-box.app/gpg.key -o /etc/apt/keyrings/sagernet.asc

echo "✅ 设置 GPG key 权限..."
sudo chmod a+r /etc/apt/keyrings/sagernet.asc

echo "✅ 添加 sagernet APT 源..."
sudo tee /etc/apt/sources.list.d/sagernet.sources > /dev/null << 'EOF'
Types: deb
URIs: https://deb.sagernet.org/
Suites: *
Components: *
Enabled: yes
Signed-By: /etc/apt/keyrings/sagernet.asc
EOF

echo "✅ 更新 APT 软件包列表..."
sudo apt-get update

# ===============================
# 选择安装 sing-box 还是 sing-box-beta
# ===============================
read -rp "请选择安装版本 (1) sing-box (默认) (2) sing-box-beta: " choice
case "$choice" in
    2) PACKAGE_NAME="sing-box-beta";;
    *) PACKAGE_NAME="sing-box";;
esac
echo "ℹ️ 你选择安装: $PACKAGE_NAME"

# ===============================
# 查询可用版本并选择
# ===============================
echo "ℹ️ 查询可用版本..."
AVAILABLE_VERSIONS=$(apt policy "$PACKAGE_NAME" | grep -E 'Version table' -A500 | grep -oP '([0-9]+\.[0-9]+\.[0-9]+[^ ]*)')

echo "可用版本列表:"
echo "$AVAILABLE_VERSIONS"

read -rp "请选择安装版本（直接回车默认最新版）: " VERSION

if [[ -z "$VERSION" ]]; then
    echo "ℹ️ 安装默认最新版..."
    sudo apt-get install -y "$PACKAGE_NAME"
else
    if echo "$AVAILABLE_VERSIONS" | grep -qx "$VERSION"; then
        echo "ℹ️ 安装版本 $VERSION ..."
        sudo apt-get install -y "$PACKAGE_NAME=$VERSION"
    else
        echo "⚠️ 输入版本不存在，安装默认最新版..."
        sudo apt-get install -y "$PACKAGE_NAME"
    fi
fi

# ===============================
# 下载 config.json 覆盖写入
# ===============================
CONFIG_URL="https://github.com/dawnineyes/sing-box-reality/raw/refs/heads/main/config/1.13.-.json"
CONFIG_PATH="/etc/sing-box/config.json"

echo "✅ 下载最新 config.json 并覆盖写入 $CONFIG_PATH ..."
sudo curl -fsSL "$CONFIG_URL" -o "$CONFIG_PATH"

# ===============================
# 启用并启动服务
# ===============================
echo "✅ 启用 $PACKAGE_NAME 服务..."
sudo systemctl enable sing-box

echo "🎉 安装与配置完成！"
echo "请修改配置文件 nano /etc/sing-box/config.json"
echo "启动 systemctl daemon-reload && systemctl restart sing-box &&  systemctl status sing-box"
