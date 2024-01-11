#!/bin/bash

# 引数チェック
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 [Service Name]"
    exit 1
fi

SERVICE_NAME=$1

# サービスの存在チェック
# if ! sudo systemctl --type=service --state=active,loaded | grep -q "^$SERVICE_NAME.service"; then
#     echo "Error: Service '$SERVICE_NAME' does not exist."
#     exit 1
# fi

# NTP Sync Scriptの生成
cat <<EOF > /usr/local/bin/ntp-sync-restart.sh
#!/bin/bash

# Check for synchronization with the NTP server
while true; do
    if ntpq -p | grep -q '^*'; then
        echo "Synchronization with the NTP server is complete."
        break
    else
        echo "Waiting for synchronization with the NTP server..."
        sleep 5
    fi
done

# Restart the specified service
echo "Restarting $SERVICE_NAME."
systemctl restart $SERVICE_NAME
echo "Service has been restarted successfully."
EOF

# スクリプトの実行権限を設定
chmod +x /usr/local/bin/ntp-sync-restart.sh

# Systemdサービスファイルの生成
cat <<EOF > /etc/systemd/system/ntp-sync-restart.service
[Unit]
Description=NTP Sync and Restart Specific Service
After=network.target ntpd.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/ntp-sync-restart.sh
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
EOF

# Systemdサービスのリロードと有効化
systemctl daemon-reload
systemctl enable ntp-sync-restart.service
systemctl start ntp-sync-restart.service

echo "Setup complete."
