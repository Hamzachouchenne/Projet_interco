#!/bin/sh
# ===================================================================
# dhcp-init.sh - Serveur DHCP du site secondaire (ENT-SITE-SECO-SRV-DHCP)
# Sert VLAN 20 (Clients 192.168.60.0/24) et VLAN 30 (VoIP 192.168.70.0/24)
# DNS résolu via le site primaire par le tunnel VPN
# ===================================================================

# --- 1. INTERFACES RÉSEAU ---
# eth1 = connecté au switch sur le subnet Clients (VLAN 20)
ip addr add 192.168.60.252/24 dev eth1
ip link set eth1 up

# eth2 = connecté au switch sur le subnet VoIP (VLAN 30)
ip addr add 192.168.70.252/24 dev eth2
ip link set eth2 up

# Route par défaut via le COR-01 (SVI VLAN 20)
ip route add default via 192.168.60.254

# --- 2. INSTALLATION DE DNSMASQ ---
apk update
apk add --no-cache dnsmasq

# --- 3. CONFIGURATION DNSMASQ ---
cat > /etc/dnsmasq.conf << 'EOF'
no-resolv

interface=eth1
interface=eth2
except-interface=lo

# -------------------------------------------------------
# VLAN 20 - Réseau Clients (192.168.60.0/24)
# -------------------------------------------------------
dhcp-range=set:vlan20,192.168.60.10,192.168.60.50,255.255.255.0,24h
dhcp-option=tag:vlan20,option:router,192.168.60.254
# DNS = SRV-DNS du site primaire, accessible via tunnel VPN
dhcp-option=tag:vlan20,option:dns-server,192.168.10.11

# -------------------------------------------------------
# VLAN 30 - Réseau VoIP (192.168.70.0/24)
# -------------------------------------------------------
dhcp-range=set:vlan30,192.168.70.10,192.168.70.50,255.255.255.0,24h
dhcp-option=tag:vlan30,option:router,192.168.70.254
dhcp-option=tag:vlan30,option:dns-server,192.168.10.11

dhcp-leasefile=/tmp/dnsmasq.leases
log-dhcp
EOF

# --- 4. DÉMARRAGE ---
dnsmasq

echo "=== SRV-DHCP (Site Secondaire) initialisé - VLAN20 + VLAN30 ==="
