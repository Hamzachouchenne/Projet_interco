#!/bin/sh
# ===================================================================
# dhcp-init.sh - Serveur DHCP de l'AS10 (AS-SRV-DHCP)
# Sert le réseau Public Access (120.0.2.0/24)
# ===================================================================

# --- 1. INSTALLATION DE DNSMASQ (avant de toucher aux routes) ---
apk update
apk add --no-cache dnsmasq

# --- 2. INTERFACES RÉSEAU ---
# eth1 = réseau serveurs AS (120.0.14.0/24) via AS-SW-SERVERS
ip addr add 120.0.14.3/24 dev eth1
ip link set eth1 up

# Route par défaut via AS-R3
ip route del default
ip route add default via 120.0.14.1

# --- 3. CONFIGURATION DNSMASQ ---
cat > /etc/dnsmasq.conf << 'EOF'
no-resolv

interface=eth1
except-interface=lo

# Pool Public Access AS10 (120.0.2.0/24)
dhcp-range=120.0.2.10,120.0.2.50,255.255.255.0,24h

# Passerelle = eth3 de AS-R2
dhcp-option=option:router,120.0.2.1

# DNS = AS-SRV-DNS
dhcp-option=option:dns-server,120.0.14.2

dhcp-leasefile=/tmp/dnsmasq.leases
log-dhcp
EOF

# --- 4. DÉMARRAGE ---
dnsmasq

echo "=== AS-SRV-DHCP initialisé - Public Access 120.0.2.0/24 ==="
