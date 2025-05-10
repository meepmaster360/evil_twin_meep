# evil_twin_meep

How It Works
Scans for Wi-Fi networks (Option 1) using bettercap.

Creates a fake AP (Option 2) with:

hostapd (to mimic the real AP)

dnsmasq (to assign IPs)

Optional captive portal (phishing page)

Deauthenticates real clients using bettercap to force them onto your fake AP.

Requirements
✔ Wi-Fi adapter supporting AP mode (e.g., Alfa AWUS036ACH)
✔ Kali Linux/Raspberry Pi
✔ Run as root (sudo ./evil_twin_attacker.sh)

Legal Warning
🚨 Only use on networks you own or have explicit permission to test. Unauthorized attacks are illegal.
