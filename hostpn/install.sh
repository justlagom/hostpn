#!/usr/bin/env sh

# --- Configuration Variables ---
DOMAIN="${DOMAIN:-node68.lunes.host}"
PORT="${PORT:-443}" 
UUID="${UUID:-2584b733-9095-4bec-a7d5-62b473540f7a}"
XRAY_INBOUND_PORT="8080" 
XHTTP_PATH="/b3a053a4" 

# ----------------------------------------------------------------------
# 🎯 关键修改 1: 脚本启动目录和文件存放目录一致。
# ----------------------------------------------------------------------
# 假设脚本在 /home/container/hostpn/ 目录下运行。

# --- Xray Setup ---

# Create directory and navigate into it
# ‼️ Xray 核心文件放在 /home/container/xy/，配置文件放在 /home/container/xy/config.json
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
## 步骤 1: 复制和修改 Xray 配置文件 (xray-config.json)
# ------------------------------------------------------------
echo "Copying local Xray configuration file (xray-config.json)..."
# ⚠️ 关键修改 2: 配置文件现在在脚本执行时的父目录 (hostpn/)
# 假设 install.sh 运行在 /home/container/hostpn/
# 那么 xray-config.json 也在 /home/container/hostpn/
# 但脚本已经 cd 到 /home/container/xy/，因此需要回到上一级目录找到文件。
# 为了保持脚本的鲁棒性，我们使用一个相对路径：
cp "../hostpn/xray-config.json" config.json

# ❗ 检查点：config.json 应该已在当前目录 (/home/container/xy)
if [ ! -f config.json ]; then
    echo "============================================================"
    echo "❌ 错误: 配置文件 config.json 复制失败，请检查文件是否存在于脚本运行的目录。"
    echo "============================================================"
    exit 1
fi

# 替换 Xray 配置中的 UUID, 监听端口和 Path 
sed -i "s/UUID/$UUID/g" config.json
sed -i "s/8080/$XRAY_INBOUND_PORT/g" config.json
sed -i "s/\/b3a053a4/$XHTTP_PATH/g" config.json

# ------------------------------------------------------------
## 步骤 2: 复制 Nginx 配置 (模板)
# ------------------------------------------------------------
echo "Copying Nginx configuration file (nginx.conf)..."
# ⚠️ 关键修改 3: Nginx 配置文件名现在是 nginx.conf
# 同样使用相对路径找到它，并复制到 /home/container/xy/
cp "../hostpn/nginx.conf" /home/container/xy/nginx.conf

# ------------------------------------------------------------
## 步骤 3: VLESS 链接生成和最终输出
# ------------------------------------------------------------

# Generate VLESS XHTTP share link
vlessUrl="vless://$UUID@$DOMAIN:$PORT?encryption=none&flow=xtls-rprx-vision&security=none&path=$XHTTP_PATH&type=xhttp#Wispbyte-xhttp"

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
echo "ℹ️ Nginx 配置已复制。服务将由 app.js 启动和守护。"
echo "============================================================"
