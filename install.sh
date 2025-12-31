#!/bin/bash
set -eux

echo "step 1/10: setting ownership of the primary Debian user"
sudo chown -R debian13:debian13 /home/debian13

echo "step 2/10: installing required dependencies"
sudo apt-get update
sudo apt-get install -y keyboard-configuration console-setup console-data kbd ca-certificates iptables iptables-persistent

echo "step 3/10: configuring keyboard layout to EN (US)"
sudo tee /etc/default/keyboard > /dev/null <<EOF
XKBMODEL="pc105"
XKBLAYOUT="us"
XKBVARIANT=""
XKBOPTIONS=""
EOF
sudo setupcon
sudo systemctl restart keyboard-setup.service
sudo sed -i 's/^#*KEYMAP=.*/KEYMAP=y/' /etc/initramfs-tools/initramfs.conf
sudo update-initramfs -u

echo "step 4/10: locking the root account (disabling root login)"
sudo passwd -l root

echo "step 5/10: removing unnecessary packages"
sudo apt-get autoremove -y
sudo apt-get clean

echo "step 6/10: cleaning APT cache and log files"
sudo rm -rf /var/lib/apt/lists/*
sudo find /var/log -type f -exec truncate -s 0 {} \; || true

echo "step 7/10: securing VM | applying iptables rules"
sudo mkdir -p /etc/iptables
sudo tee /etc/iptables/rules.v4 > /dev/null <<EOF
*filter
:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT DROP [0:0]
-A INPUT -i lo -j ACCEPT
-A OUTPUT -o lo -j ACCEPT
-A INPUT -p tcp -m tcp --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
-A OUTPUT -p tcp -m tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT
-A OUTPUT -m state --state ESTABLISHED -j ACCEPT
-A INPUT -p icmp --icmp-type 13 -j DROP
-A INPUT -p icmp --icmp-type 14 -j DROP
-A INPUT -p icmp --icmp-type echo-request -j DROP
COMMIT
EOF
sudo systemctl enable netfilter-persistent

echo "step 8/10: securing VM | disabling TCP timestamps to prevent information disclosure"
echo "net.ipv4.tcp_timestamps = 0" | sudo tee -a /etc/sysctl.conf

echo "step 9/10: applying sysctl configuration at startup"
sudo tee /etc/systemd/system/sysctl-persist.service > /dev/null <<EOF
[Unit]
Description=Apply sysctl settings
After=network.target

[Service]
Type=oneshot
ExecStart=/sbin/sysctl -p

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable sysctl-persist.service
sudo sysctl -p

echo "step 10/10: script completed successfully"
exit 0
