#!/bin/sh
# ===================================================================
# dhcp-init.sh - Serveur DHCP du site primaire AS10 (SRV-DHCP)
# Sert uniquement VLAN 20 (Clients) et VLAN 30 (VoIP)
# Les serveurs (VLAN 10) conservent leurs IPs statiques
# ===================================================================

# --- 1. INTERFACES RÉSEAU ---
# eth1 = connecté au switch Arista sur le subnet Clients (192.168.20.x)
ip addr add 192.168.20.200/24 dev eth1
ip link set eth1 up

# eth2 = connecté au switch Arista sur le subnet VoIP (192.168.30.x)
ip addr add 192.168.30.200/24 dev eth2
ip link set eth2 up

# Route par défaut via le switch (SVI VLAN 20)
ip route del default dev eth0
ip route add default via 192.168.20.254

# --- 3. CONFIGURATION DNSMASQ ---
cat > /etc/dnsmasq.conf << 'EOF'
# Ne pas utiliser /etc/resolv.conf (Docker DNS) comme upstream
no-resolv

# Écouter uniquement sur les interfaces LAN clients/VoIP
interface=eth1
interface=eth2
except-interface=lo

# -------------------------------------------------------
# VLAN 20 - Réseau Clients (192.168.20.0/24)
# -------------------------------------------------------
# Tag "vlan20" attribué à toute IP dans cette plage
dhcp-range=set:vlan20,192.168.20.10,192.168.20.50,255.255.255.0,24h
# Passerelle = SVI du switch Arista pour ce VLAN
dhcp-option=tag:vlan20,option:router,192.168.20.254
# DNS = SRV-DNS de l'AS10
dhcp-option=tag:vlan20,option:dns-server,192.168.10.11

# -------------------------------------------------------
# VLAN 30 - Réseau VoIP (192.168.30.0/24)
# -------------------------------------------------------
dhcp-range=set:vlan30,192.168.30.10,192.168.30.50,255.255.255.0,24h
dhcp-option=tag:vlan30,option:router,192.168.30.254
dhcp-option=tag:vlan30,option:dns-server,192.168.10.11

# Fichier de baux DHCP
dhcp-leasefile=/tmp/dnsmasq.leases

# Log pour debug
log-dhcp
EOF

# --- 4. DÉMARRAGE ---
dnsmasq

echo "=== SRV-DHCP (AS10) initialisé - VLAN20 + VLAN30 ==="
