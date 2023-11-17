#!/bin/bash

# Function to print characters with delay
print_with_delay() {
    text="$1"
    delay="$2"
    for ((i = 0; i < ${#text}; i++)); do
        echo -n "${text:$i:1}"
        sleep $delay
    done
    echo
}

# Introduction animation
echo ""
echo ""
echo "--------sing-REALITY-box 一键安装脚本------" 
echo ""
# Check if jq is installed, and install it if not
if ! command -v jq &> /dev/null; then
    echo "安装jq"
    if [ -n "$(command -v apt)" ]; then
        apt update > /dev/null 2>&1
        apt install -y jq > /dev/null 2>&1
        wget https://github.com/xxf185/jq/releases/download/jq-1.7/jq-linux-amd64 > /dev/null 2>&1
        chmod a+x jq-linux-amd64 && mv jq-linux-amd64 /usr/bin/jq
    elif [ -n "$(command -v yum)" ]; then
        yum install -y epel-release
        yum install -y jq
    elif [ -n "$(command -v dnf)" ]; then
        dnf install -y jq
    else
        echo "jq安装失败."
        exit 1
    fi
fi

# Check if reality.json, sing-box, and sing-box.service already exist
if [ -f "/root/reality.json" ] && [ -f "/root/sing-box" ] && [ -f "/root/public.key.b64" ] && [ -f "/etc/systemd/system/sing-box.service" ]; then
    echo ""
    echo "检测脚本已经安装"
    echo ""
    echo ""
    echo "1. 重新安装"
    echo "2. 修改配置"
    echo "3. 查看配置"
    echo "4. 卸载脚本"
    echo ""
    read -p "选择 (1-4): " choice

    case $choice in
        1)         echo ""
                   echo "重新安装"
	            	# Uninstall previous installation
	            	systemctl stop sing-box
	            	systemctl disable sing-box > /dev/null 2>&1
	           	    rm /etc/systemd/system/sing-box.service
	            	rm /root/reality.json
	            	rm /root/sing-box
	
	            	# Proceed with installation
	            	;;
        2)
            		echo "修改配置"
                    echo ""
			# Get current listen port
			current_listen_port=$(jq -r '.inbounds[0].listen_port' /root/reality.json)

			# Ask for listen port
			read -p "输入监听端口(Current port is $current_listen_port): " listen_port
			listen_port=${listen_port:-$current_listen_port}
            echo ""

			# Get current server name
			current_server_name=$(jq -r '.inbounds[0].tls.server_name' /root/reality.json)
            echo ""

			# Ask for server name (sni)
			read -p "输入server name/SNI (Current value is $current_server_name): " server_name
			server_name=${server_name:-$current_server_name}

			# Modify reality.json with new settings
			jq --arg listen_port "$listen_port" --arg server_name "$server_name" '.inbounds[0].listen_port = ($listen_port | tonumber) | .inbounds[0].tls.server_name = $server_name | .inbounds[0].tls.reality.handshake.server = $server_name' /root/reality.json > /root/reality_modified.json
			mv /root/reality_modified.json /root/reality.json

			# Restart sing-box service
			systemctl restart sing-box
			echo ""
			echo ""
			echo "------链接------"
			echo ""
			echo ""
			# Get current listen port
			current_listen_port=$(jq -r '.inbounds[0].listen_port' /root/reality.json)

			# Get current server name
			current_server_name=$(jq -r '.inbounds[0].tls.server_name' /root/reality.json)

			# Get the UUID
			uuid=$(jq -r '.inbounds[0].users[0].uuid' /root/reality.json)

			# Get the public key from the file, decoding it from base64
			public_key=$(base64 --decode /root/public.key.b64)
			
			# Get the short ID
			short_id=$(jq -r '.inbounds[0].tls.reality.short_id[0]' /root/reality.json)
			
			# Retrieve the server IP address
			server_ip=$(curl -s https://api.ipify.org)
			
			# Generate the link
			server_link="vless://$uuid@$server_ip:$current_listen_port?encryption=none&flow=xtls-rprx-vision&security=reality&sni=$current_server_name&fp=chrome&pbk=$public_key&sid=$short_id&type=tcp&headerType=none#reality"
			
			echo "$server_link"
			echo ""
			echo ""
			exit 0
            		;;
	3)
            echo ""
			echo "------链接------"
			# Get current listen port
			current_listen_port=$(jq -r '.inbounds[0].listen_port' /root/reality.json)

			# Get current server name
			current_server_name=$(jq -r '.inbounds[0].tls.server_name' /root/reality.json)

			# Get the UUID
			uuid=$(jq -r '.inbounds[0].users[0].uuid' /root/reality.json)

			# Get the public key from the file, decoding it from base64
			public_key=$(base64 --decode /root/public.key.b64)
			
			# Get the short ID
			short_id=$(jq -r '.inbounds[0].tls.reality.short_id[0]' /root/reality.json)
			
			# Retrieve the server IP address
			server_ip=$(curl -s https://api.ipify.org)
			
			# Generate the link
			server_link="vless://$uuid@$server_ip:$current_listen_port?encryption=none&flow=xtls-rprx-vision&security=reality&sni=$current_server_name&fp=chrome&pbk=$public_key&sid=$short_id&type=tcp&headerType=none#reality"
			echo ""
			echo ""
			echo "$server_link"
			echo ""
			echo ""
			exit 0
			;;	
        4)
	            	echo ""
	            	# Stop and disable sing-box service
	            	systemctl stop sing-box
	            	systemctl disable sing-box > /dev/null 2>&1
	
	            	# Remove files
	            	rm /etc/systemd/system/sing-box.service
	            	rm /root/reality.json
	            	rm /root/sing-box
			rm /root/public.key.b64
		    	echo "卸载完成"
	            	exit 0
	            	;;
	        	*)
                   echo ""
	            	echo "选择错误.退出"
	            	exit 1
	            	;;
	    esac
	fi

# Fetch the latest (including pre-releases) release version number from GitHub API
latest_version_tag=$(curl -s "https://api.github.com/repos/xxf185/sing-box/releases" | grep -Po '"tag_name": "\K.*?(?=")' | head -n 1)
latest_version=${latest_version_tag#v}  # Remove 'v' prefix from version number
echo ""
echo "sing-box内核最新版本: $latest_version"
echo ""

# Detect server architecture
arch=$(uname -m)
echo "cpu架构: $arch"
echo ""

# Map architecture names
case ${arch} in
    x86_64)
        arch="amd64"
        ;;
    aarch64)
        arch="arm64"
        ;;
    armv7l)
        arch="armv7"
        ;;
esac

# Prepare package names
package_name="sing-box-${latest_version}-linux-${arch}"

# Prepare download URL
url="https://github.com/xxf185/sing-box/releases/download/${latest_version_tag}/${package_name}.tar.gz"

# Download the latest release package (.tar.gz) from GitHub
curl -sLo "/root/${package_name}.tar.gz" "$url"


# Extract the package and move the binary to /root
tar -xzf "/root/${package_name}.tar.gz" -C /root
mv "/root/${package_name}/sing-box" /root/

# Cleanup the package
rm -r "/root/${package_name}.tar.gz" "/root/${package_name}"

# Set the permissions
chown root:root /root/sing-box
chmod +x /root/sing-box


# Generate key pair
echo "正在获取密匙..."
key_pair=$(/root/sing-box generate reality-keypair)
echo ""
echo "获取密匙完成."
echo

# Extract private key and public key
private_key=$(echo "$key_pair" | awk '/PrivateKey/ {print $2}' | tr -d '"')
public_key=$(echo "$key_pair" | awk '/PublicKey/ {print $2}' | tr -d '"')

# Save the public key in a file using base64 encoding
echo "$public_key" | base64 > /root/public.key.b64

# Generate necessary values
uuid=$(/root/sing-box generate uuid)
short_id=$(/root/sing-box generate rand --hex 8)

# Ask for listen port
read -p "输入监听端口 (默认: 443): " listen_port
listen_port=${listen_port:-443}
echo ""
# Ask for server name (sni)
read -p "输入server/SNI (默认: telewebion.com): " server_name
server_name=${server_name:-telewebion.com}

# Retrieve the server IP address
server_ip=$(curl -s https://api.ipify.org)

# Create reality.json using jq
jq -n --arg listen_port "$listen_port" --arg server_name "$server_name" --arg private_key "$private_key" --arg short_id "$short_id" --arg uuid "$uuid" --arg server_ip "$server_ip" '{
  "log": {
    "level": "info",
    "timestamp": true
  },
  "inbounds": [
    {
      "type": "vless",
      "tag": "vless-in",
      "listen": "::",
      "listen_port": ($listen_port | tonumber),
      "sniff": true,
      "sniff_override_destination": true,
      "domain_strategy": "ipv4_only",
      "users": [
        {
          "uuid": $uuid,
          "flow": "xtls-rprx-vision"
        }
      ],
      "tls": {
        "enabled": true,
        "server_name": $server_name,
          "reality": {
          "enabled": true,
          "handshake": {
            "server": $server_name,
            "server_port": 443
          },
          "private_key": $private_key,
          "short_id": [$short_id]
        }
      }
    }
  ],
  "outbounds": [
    {
      "type": "direct",
      "tag": "direct"
    },
    {
      "type": "block",
      "tag": "block"
    }
  ]
}' > /root/reality.json

# Create sing-box.service
cat > /etc/systemd/system/sing-box.service <<EOF
[Unit]
After=network.target nss-lookup.target

[Service]
User=root
WorkingDirectory=/root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
ExecStart=/root/sing-box run -c /root/reality.json
ExecReload=/bin/kill -HUP \$MAINPID
Restart=on-failure
RestartSec=10
LimitNOFILE=infinity

[Install]
WantedBy=multi-user.target
EOF

# Check configuration and start the service
if /root/sing-box check -c /root/reality.json; then
    echo ""
    echo "配置完成.正在启动sing-box服务"
    systemctl daemon-reload
    systemctl enable sing-box > /dev/null 2>&1
    systemctl start sing-box
    systemctl restart sing-box

# Generate the link

    server_link="vless://$uuid@$server_ip:$listen_port?encryption=none&flow=xtls-rprx-vision&security=reality&sni=$server_name&fp=chrome&pbk=$public_key&sid=$short_id&type=tcp&headerType=none#reality"

    # Print the server details
    echo
    echo "Server IP: $server_ip"
    echo "Listen Port: $listen_port"
    echo "Server Name: $server_name"
    echo "Public Key: $public_key"
    echo "Short ID: $short_id"
    echo "UUID: $uuid"
    echo ""
    echo ""
    echo "------链接------"
    echo ""
    echo ""
    echo "$server_link"
    echo ""
    echo ""
else
    echo "错误"
fi

