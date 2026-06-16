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
echo "-----------sing-REALITY-box----------"
echo ""


# Check if jq is installed, and install it if not
if ! command -v jq &> /dev/null; then
    echo "jq安装中..."
    if [ -n "$(command -v apt)" ]; then
        apt update > /dev/null 2>&1
        apt install -y jq > /dev/null 2>&1
    elif [ -n "$(command -v yum)" ]; then
        yum install -y epel-release
        yum install -y jq
    elif [ -n "$(command -v dnf)" ]; then
        dnf install -y jq
    else
        echo "无法安装jq"
        exit 1
    fi
fi

# Check if reality.json, sing-box, and sing-box.service already exist
if [ -f "/root/reality.json" ] && [ -f "/root/sing-box" ] && [ -f "/root/public.key.b64" ] && [ -f "/etc/systemd/system/sing-box.service" ]; then

    echo "Reality已经安装"
    echo ""
    echo "1. 重新安装"
    echo "2. 修改配置"
    echo "3. 查看配置"
    echo "4. 切换版本 (Stable/Alpha)"
    echo "5. 卸载"
    echo ""
    read -p "请选择 (1-5): " choice

    case $choice in
        1)
	            	echo "重新安装..."
	            	# Uninstall previous installation
	            	systemctl stop sing-box
	            	systemctl disable sing-box > /dev/null 2>&1
	           	rm /etc/systemd/system/sing-box.service
	            	rm /root/reality.json
	            	rm /root/sing-box
	
	            	# Proceed with installation
	            	;;
        2)
            		echo "修改配置..."
			# Get current listen port
			current_listen_port=$(jq -r '.inbounds[0].listen_port' /root/reality.json)

			# Ask for listen port
			read -p "Enter desired listen port (Current port is $current_listen_port): " listen_port
			listen_port=${listen_port:-$current_listen_port}

			# Get current server name
			current_server_name=$(jq -r '.inbounds[0].tls.server_name' /root/reality.json)

			# Ask for server name (sni)
			read -p "Enter server name/SNI (Current value is $current_server_name): " server_name
			server_name=${server_name:-$current_server_name}

			# Modify reality.json with new settings
			jq --arg listen_port "$listen_port" --arg server_name "$server_name" '.inbounds[0].listen_port = ($listen_port | tonumber) | .inbounds[0].tls.server_name = $server_name | .inbounds[0].tls.reality.handshake.server = $server_name' /root/reality.json > /root/reality_modified.json
			mv /root/reality_modified.json /root/reality.json

			# Restart sing-box service
			systemctl restart sing-box
			echo ""
			echo ""
			echo "----------链接----------"
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
			server_ip=$(curl -s4 https://api.ipify.org)
			if [ -z "$server_ip" ]; then server_ip=$(curl -s4 https://ifconfig.me); fi
			
			# Generate the link
			server_link="vless://$uuid@$server_ip:$current_listen_port?encryption=none&flow=xtls-rprx-vision&security=reality&sni=$current_server_name&fp=chrome&pbk=$public_key&sid=$short_id&type=tcp&headerType=none#reality"
			
			echo "$server_link"
			echo ""
			echo ""
			exit 0
            		;;
	3)
			echo "----------链接----------"
			
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
			server_ip=$(curl -s4 https://api.ipify.org)
			if [ -z "$server_ip" ]; then server_ip=$(curl -s4 https://ifconfig.me); fi
			
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
   			echo "切换版本..."
			echo ""
			# Extract the current version
			current_version_tag=$(/root/sing-box version | grep 'sing-box version' | awk '{print $3}')

			# Fetch the latest stable and alpha version tags
			latest_stable_version=$(curl -s "https://api.github.com/repos/xxf185/sing-box/releases" | jq -r '[.[] | select(.prerelease==false)][0].tag_name' 2>/dev/null)
			if [ -z "$latest_stable_version" ] || [ "$latest_stable_version" == "null" ]; then latest_stable_version="v1.13.12"; fi
			latest_alpha_version=$(curl -s "https://api.github.com/repos/xxf185/sing-box/releases" | jq -r '[.[] | select(.prerelease==true)][0].tag_name' 2>/dev/null)
			if [ -z "$latest_alpha_version" ] || [ "$latest_alpha_version" == "null" ]; then latest_alpha_version="v1.14.0-alpha.27"; fi

			# Determine current version type (stable or alpha)
			if [[ $current_version_tag == *"-alpha"* ]]; then
				echo "目前在 Alpha. 切换到稳定版..."
				echo ""
				new_version_tag=$latest_stable_version
			else
				echo "目前使用的是稳定版。即将切换到 Alpha 版……"
				echo ""
				new_version_tag=$latest_alpha_version
			fi

			# Stop the service before updating
			systemctl stop sing-box

			# Download and replace the binary
			arch=$(uname -m)
			case $arch in
				x86_64) arch="amd64" ;;
				aarch64) arch="arm64" ;;
				armv7l) arch="armv7" ;;
			esac

			package_name="sing-box-${new_version_tag#v}-linux-${arch}"
			url="https://github.com/xxf185/sing-box/releases/download/${new_version_tag}/${package_name}.tar.gz"

			curl -sLo "/root/${package_name}.tar.gz" "$url"
			tar -xzf "/root/${package_name}.tar.gz" -C /root
			if [ $? -ne 0 ]; then
				echo "提取软件包失败，中止操作。"
				exit 1
			fi
			mv "/root/${package_name}/sing-box" /root/sing-box

			# Cleanup the package
			rm -r "/root/${package_name}.tar.gz" "/root/${package_name}"

			# Set the permissions
			chown root:root /root/sing-box
			chmod +x /root/sing-box

			# Restart the service with the new binary
			systemctl daemon-reload
			systemctl start sing-box

			echo "版本已切换."
			echo ""
			exit 0
			;;

    5)
	            	echo "卸载中..."
	            	# Stop and disable sing-box service
	            	systemctl stop sing-box
	            	systemctl disable sing-box > /dev/null 2>&1
	
	            	# Remove files
	            	rm /etc/systemd/system/sing-box.service
	            	rm /root/reality.json
	            	rm /root/sing-box
			rm /root/public.key.b64
		    	echo "卸载完成!"
	            	exit 0
	            	;;
	        	*)
	            	echo "选择错误"
	            	exit 1
	            	;;
	    esac
	fi

		echo ""
  		echo "请选择要安装的版本:"
  		echo ""
		echo "1. 稳定版"
		echo "2. Alpha"
  		echo ""
		read -p "选项: " version_choice
  		echo ""
		version_choice=${version_choice:-1}

		# Set the tag based on user choice
		if [ "$version_choice" -eq 2 ]; then
			echo "安装 Alpha 版本..."
   			echo ""
			latest_version_tag=$(curl -s "https://api.github.com/repos/xxf185/sing-box/releases" | jq -r '[.[] | select(.prerelease==true)][0].tag_name' 2>/dev/null)
			if [ -z "$latest_version_tag" ] || [ "$latest_version_tag" == "null" ]; then latest_version_tag="v1.14.0-alpha.27"; fi
		else
			echo "安装Stable 版本..."
   			echo ""
			latest_version_tag=$(curl -s "https://api.github.com/repos/xxf185/sing-box/releases" | jq -r '[.[] | select(.prerelease==false)][0].tag_name' 2>/dev/null)
			if [ -z "$latest_version_tag" ] || [ "$latest_version_tag" == "null" ]; then latest_version_tag="v1.13.13"; fi
		fi

		# No need to fetch the latest version tag again, it's already set based on user choice
		latest_version=${latest_version_tag#v}  # Remove 'v' prefix from version number
		echo "最新版本: $latest_version"
  		echo ""

		# Detect server architecture
		arch=$(uname -m)
		echo "Arch: $arch"
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
if [ $? -ne 0 ]; then
    echo "提取软件包失败"
    exit 1
fi
mv "/root/${package_name}/sing-box" /root/

# Cleanup the package
rm -r "/root/${package_name}.tar.gz" "/root/${package_name}"

# Set the permissions
chown root:root /root/sing-box
chmod +x /root/sing-box


# Generate key pair
echo "生成密钥..."
echo ""
key_pair=$(/root/sing-box generate reality-keypair)
echo "密钥生成完成。"
echo ""

# Extract private key and public key
private_key=$(echo "$key_pair" | awk '/PrivateKey/ {print $2}' | tr -d '"')
public_key=$(echo "$key_pair" | awk '/PublicKey/ {print $2}' | tr -d '"')

# Save the public key in a file using base64 encoding
echo "$public_key" | base64 > /root/public.key.b64

# Generate necessary values
uuid=$(/root/sing-box generate uuid)
short_id=$(/root/sing-box generate rand --hex 8)

# Ask for listen port
read -p "请输入端口(default: 443): " listen_port
listen_port=${listen_port:-443}
echo ""
# Ask for server name (sni)
read -p "请输入 name/SNI (default: www.ebay.com): " server_name
echo ""
server_name=${server_name:-www.ebay.com}

# Retrieve the server IP address
server_ip=$(curl -s4 https://api.ipify.org)
if [ -z "$server_ip" ]; then
    server_ip=$(curl -s4 https://ifconfig.me)
fi

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
  ],
  "route": {
    "rules": [
      {
        "inbound": "vless-in",
        "action": "sniff"
      },
      {
        "inbound": "vless-in",
        "action": "resolve",
        "strategy": "ipv4_only"
      }
    ],
    "auto_detect_interface": true
  }
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
    echo "配置成功.正在启动 sing-box 服务..."
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
    echo "----------链接----------"
    echo ""
    echo ""
    echo "$server_link"
    echo ""
    echo ""
else
    echo "配置错误"
fi

