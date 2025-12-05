#!/usr/bin/env sh

# --- Configuration Variables ---
DOMAIN="${DOMAIN:-node68.lunes.host}"
PORT="${PORT:-10008}"
UUID="${UUID:-2584b733-9095-4bec-a7d5-62b473540f7a}"
CADDY_PORT="8080" # Caddy 监听的回落端口

# 假设脚本在 hostpn/ 目录下运行。
# 所有的配置文件都在当前目录 (./) 下。

# --- Xray Reality Setup ---

# Create directory and navigate into it
mkdir -p /home/container/xy
cd /home/container/xy 
# ‼️ 当前工作目录为 /home/container/xy，项目文件在脚本执行时的父目录

# Download and extract Xray core
echo "Downloading Xray v25.10.15..."
curl -sSL -o Xray-linux-64.zip https://github.com/XTLS/Xray-core/releases/download/v25.10.15/Xray-linux-64.zip
unzip Xray-linux-64.zip
rm Xray-linux-64.zip
mv xray xy
chmod +x xy

# ------------------------------------------------------------
## ✅ 修改点 1: 复制本地 Xray 配置文件
# ------------------------------------------------------------
echo "Copying local Xray configuration file (xray-config.json)..."
# 注意：假设脚本运行目录是 /home/container/hostpn，cd /home/container/xy 后，
# 配置文件在父目录的 hostpn/ 下。这里使用 ../hostpn/ 来引用文件。
cp ../hostpn/xray-config.json config.json

# Replace PORT and UUID in the config file
sed -i "s/10008/$PORT/g" config.json
sed -i "s/YOUR_UUID/$UUID/g" config.json

# Generate X25519 key pair for Reality
echo "Generating Reality key pair..."
keyPair=$(./xy x25519)
privateKey=$(echo "$keyPair" | grep "Private key" | awk '{print $3}')
publicKey=$(echo "$keyPair" | grep "Public key" | awk '{print $3}')
shortId=$(openssl rand -hex 4)

# ❗️ 密钥生成失败检查：如果 publicKey 为空，则退出并打印日志
if [ -z "$publicKey" ]; then
    echo "============================================================"
    echo "❌ 错误: Reality 公钥捕获失败！请检查 Xray 二进制文件是否正常运行。"
    echo "============================================================"
    exit 1
fi

# Replace keys and short ID in the config file
sed -i "s/YOUR_PRIVATE_KEY/$privateKey/g" config.json
sed -i "s/YOUR_SHORT_ID/$shortId/g" config.json


# ------------------------------------------------------------
## 🎯 步骤一：在 Xray 配置中加入 Caddy 的回落设置 (Fallbacks)
# ------------------------------------------------------------
echo "Configuring Xray fallbacks to Caddy port $CADDY_PORT..."

# 在 Reality Settings 的 dest 字段后插入 fallbacks 配置，指向 Caddy 监听的 8080 端口。
sed -i '/"dest": "/a \        "fallbacks": [ \n          { \n            "dest": "127.0.0.1:'"$CADDY_PORT"'" \n          } \n        ],' config.json


# ------------------------------------------------------------
## 🎯 步骤二：下载和配置 Caddy Web 服务器 (静态网页伪装)
# ------------------------------------------------------------
echo "Downloading Caddy and copying local configuration files..."

# 下载 Caddy Core (v2.7.6 稳定版)
curl -sSL -o caddy https://github.com/caddyserver/caddy/releases/download/v2.7.6/caddy_2.7.6_linux_amd64
chmod +x caddy

# 创建静态网页目录
mkdir -p www

# ✅ 修改点 2: 从父目录的 hostpn/ 子目录中复制文件
echo "Copying Caddyfile.template and index.html from project subdirectory..."
cp ../hostpn/index.html www/index.html
cp ../hostpn/Caddyfile.template Caddyfile

# 替换 Caddyfile 模板中的端口占位符
sed -i "s/CADDY_PORT_PLACEHOLDER/$CADDY_PORT/g" Caddyfile

# ------------------------------------------------------------
## 🎯 步骤三：VLESS 链接生成和最终输出
# ------------------------------------------------------------

# Generate VLESS Reality share link
vlessUrl="vless://$UUID@$DOMAIN:$PORT?encryption=none&flow=xtls-rprx-vision&security=reality&sni=www.cloudflare.com&fp=chrome&pbk=$publicKey&sid=$shortId&spx=%2F&type=tcp&headerType=none#lunes-reality"

# Save the generated URL to node.txt
echo "$vlessUrl" > /home/container/node.txt

# --- Final Output ---
echo "============================================================"
echo "✅ Configuration Complete!"
echo "🚀 VLESS Reality Node Info"
echo "------------------------------------------------------------"
echo "$vlessUrl"
echo "------------------------------------------------------------"
echo "ℹ️ Xray 和 Caddy 已配置完成。它们将由您的 app.js 启动和守护。"
echo "============================================================"
