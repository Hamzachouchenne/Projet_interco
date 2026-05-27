#!/bin/sh
# ===================================================================
# dhcp-init.sh - Serveur DHCP du site secondaire AS13 (AS13-SRV-DHCP)
# Sert le LAN AS13 : 192.168.50.0/24
# ===================================================================

# --- 1. INTERFACE RÉSEAU ---
# eth1 = connecté au bridge LAN AS13
ip addr add 192.168.50.2/24 dev eth1
ip link set eth1 up

# Route par défaut via le firewall AS13
ip route add default via 192.168.50.1

# --- 2. INSTALLATION DE DNSMASQ ---
apk update
apk add --no-cache dnsmasq

# --- 3. CONFIGURATION DNSMASQ ---
cat > /etc/dnsmasq.conf << 'EOF'
no-resolv

# Écouter sur le LAN AS13
interface=eth1
except-interface=lo

# -------------------------------------------------------
# LAN AS13 - 192.168.50.0/24
# -------------------------------------------------------
dhcp-range=192.168.50.10,192.168.50.50,255.255.255.0,24h

# Passerelle = AS13-FIREWALL
dhcp-option=option:router,192.168.50.1

# DNS = AS13-FIREWALL (qui forward vers SRV-DNS AS10 via le tunnel VPN)
dhcp-option=option:dns-server,192.168.50.1

dhcp-leasefile=/tmp/dnsmasq.leases
log-dhcp
EOF

# --- 4. DÉMARRAGE ---
dnsmasq

echo "=== AS13-SRV-DHCP initialisé - LAN 192.168.50.0/24 ==="
