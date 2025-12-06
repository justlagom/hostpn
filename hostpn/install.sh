#!/usr/bin/env sh

# --- Configuration Variables ---
DOMAIN="${DOMAIN:-node68.lunes.host}"
# PORT 443 是外部端口，用于 VLESS 链接
PORT="${PORT:-443}" 
UUID="${UUID:-2584b733-9095-4bec-a7d5-62b473540f7a}"
# Xray 监听的内部端口，用于接收 Nginx 反代流量
XRAY_INBOUND_PORT="8080" 
# XHTTP 路径，必须与 Xray 配置 (xray-config.json) 中的 path 字段一致
XHTTP_PATH="/b3a053a4" 

# 假设脚本在 hostpn/ 目录下运行。
# 所有的配置文件都在当前目录 (./) 下。

# --- Xray Setup ---

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

# ------------------------------------------------------------
## 步骤 1: 复制和修改 Xray 配置文件 (config.json)
# ------------------------------------------------------------
echo "Copying local Xray configuration file (xray-config.json)..."
# 假设 xray-config.json 在父目录 hostpn/ 下
cp ../hostpn/xray-config.json config.json

# 替换 Xray 配置中的 UUID, 监听端口和 Path 
# 假设配置文件中占位符为 UUID, 8080, /b3a053a4
sed -i "s/UUID/$UUID/g" config.json
sed -i "s/8080/$XRAY_INBOUND_PORT/g" config.json
sed -i "s/\/b3a053a4/$XHTTP_PATH/g" config.json

# ------------------------------------------------------------
## 步骤 2: 生成 Nginx 配置 (由 app.js 使用)
# ------------------------------------------------------------
echo "Copying Nginx configuration template..."
# Nginx 配置模板位于父目录 hostpn/
cp ../hostpn/nginx.conf.template /home/container/xy/nginx.conf.template

# ------------------------------------------------------------
## 步骤 3: VLESS 链接生成和最终输出
# ------------------------------------------------------------

# Generate VLESS XHTTP share link
# VLESS 链接中的端口是外部端口 (443)
vlessUrl="vless://$UUID@$DOMAIN:$PORT?encryption=none&flow=xtls-rprx-vision&security=none&path=$XHTTP_PATH&type=xhttp#lunes-xhttp"

# Save the generated URL to node.txt
echo "$vlessUrl" > /home/container/node.txt

# --- Final Output ---
echo "============================================================"
echo "✅ Configuration Complete!"
echo "🚀 VLESS XHTTP Node Info"
echo "------------------------------------------------------------"
echo "$vlessUrl"
echo "------------------------------------------------------------"
echo "ℹ️ Xray 已配置，监听 127.0.0.1:$XRAY_INBOUND_PORT。"
echo "ℹ️ Nginx 配置模板已就绪。服务将由 app.js 启动和守护。"
echo "============================================================"
