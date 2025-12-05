#!/usr/bin/env sh

# --- Configuration Variables ---
DOMAIN="${DOMAIN:-node68.lunes.host}"
PORT="${PORT:-10008}"
UUID="${UUID:-2584b733-9095-4bec-a7d5-62b473540f7a}"

# --- Xray Reality Setup ---

# Create directory and navigate into it
mkdir -p /home/container/xy
cd /home/container/xy

# Download and extract Xray core
echo "Downloading Xray v25.8.3..."
curl -sSL -o Xray-linux-64.zip https://github.com/XTLS/Xray-core/releases/download/v25.8.3/Xray-linux-64.zip
unzip Xray-linux-64.zip
rm Xray-linux-64.zip
mv xray xy
chmod +x xy

# Download Xray Reality configuration template
echo "Downloading Xray configuration..."
curl -sSL -o config.json https://raw.githubusercontent.com/vevc/one-node/refs/heads/main/lunes-host/xray-config.json

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

# Generate VLESS Reality share link
vlessUrl="vless://$UUID@$DOMAIN:$PORT?encryption=none&flow=xtls-rprx-vision&security=reality&sni=www.cloudflare.com&fp=chrome&pbk=$publicKey&sid=$shortId&spx=%2F&type=tcp&headerType=none#lunes-reality"

# Save the generated URL to node.txt
echo $vlessUrl > /home/container/node.txt

# --- Final Output ---
echo "============================================================"
echo "🚀 VLESS Reality Node Info"
echo "------------------------------------------------------------"
echo "$vlessUrl"
echo "============================================================"
