#!/usr/bin/env sh

# --- Configuration Variables ---
DOMAIN="${DOMAIN:-node68.lunes.host}"
PORT="${PORT:-10008}"
UUID="${UUID:-2584b733-9095-4bec-a7d5-62b473540f7a}"
CADDY_PORT="8080" # Caddy 监听的回落端口

# --- Xray Reality Setup ---

# Create directory and navigate into it
mkdir -p /home/container/xy
cd /home/container/xy 

# Download and extract Xray core
echo "Downloading Xray v25.10.15..."
curl -sSL -o Xray-linux-64.zip https://github.com/XTLS/Xray-core/releases/download/v25.10.15/Xray-linux-64.zip
unzip Xray-linux-64.zip
rm Xray-linux-64.zip
mv xray xy
chmod +x xy

# Download Xray Reality configuration template
echo "Downloading Xray configuration..."
curl -sSL -o config.json https://raw.githubusercontent.com/justlagom/hostpn/refs/heads/main/hostpn/xray-config.json

# Replace PORT and UUID in the config file
sed -i "s/10008/$PORT/g" config.json
sed -i "s/YOUR_UUID/$UUID/g" config.json

# Generate X25519 key pair for Reality
echo "Generating Reality key pair..."
keyPair=$(./xy x25519)
privateKey=$(echo "$keyPair" | grep "Private key" | awk '{print $3}')
publicKey=$(echo "$keyPair" | grep "Public key" | awk '{print $3}')
shortId=$(openssl rand -hex 4)

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

# 从父目录 (..) 复制文件到当前目录 (./)
echo "Copying Caddyfile.template and index.html from project root..."
cp ../index.html www/index.html
cp ../Caddyfile.template Caddyfile

# 替换 Caddyfile 模板中的端口占位符
sed -i "s/CADDY_PORT_PLACEHOLDER/$CADDY_PORT/g" Caddyfile

# ------------------------------------------------------------
## 🎯 步骤三：VLESS 链接生成和最终输出
# ------------------------------------------------------------

# Generate VLESS Reality share link
vlessUrl="vless://$UUID@$DOMAIN:$PORT?encryption=none&flow=xtls-rprx-vision&security=reality&sni=www.cloudflare.com&fp=chrome&pbk=$publicKey&sid=$shortId&spx=%2F&type=tcp&headerType=none#lunes-reality"

# Save the generated URL to node.txt
echo $vlessUrl > /home/container/node.txt

# --- Final Output ---
echo "============================================================"
echo "✅ Configuration Complete!"
echo "🚀 VLESS Reality Node Info"
echo "------------------------------------------------------------"
echo "$vlessUrl"
echo "------------------------------------------------------------"
echo "ℹ️ Xray 和 Caddy 已配置完成。它们将由您的 app.js 启动和守护。"
echo "============================================================"
