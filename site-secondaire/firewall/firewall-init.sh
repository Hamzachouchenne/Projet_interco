#!/bin/sh
# ===================================================================
# firewall-init.sh - Site Secondaire : ENT-SITE-SECO-FIREWALL
# Les clés doivent être copiées depuis le site primaire via prepare.sh
# ===================================================================

# --- 1. ROUTAGE IP ---
sysctl -w net.ipv4.ip_forward=1

# --- 2. INTERFACES RÉSEAU ---
ip addr add 192.168.40.1/30 dev eth1   # LAN -> COR-01
ip link set eth1 up
ip addr add 120.0.1.6/30 dev eth2      # WAN -> AS-R1 eth4
ip link set eth2 up

# --- 4. ROUTES ---
ip route add 192.168.60.0/24 via 192.168.40.2   # Clients
ip route add 192.168.70.0/24 via 192.168.40.2   # VoIP
ip route del default
ip route add default via 120.0.1.5              # Défaut -> AS-R1

# --- 5. RÈGLES IPTABLES ---
iptables -P INPUT   DROP
iptables -P FORWARD DROP
iptables -P OUTPUT  ACCEPT

# INPUT : trafic à destination du firewall lui-même
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -i eth2 -p icmp            -j ACCEPT
iptables -A INPUT -i eth2 -p udp --dport 1195 -j ACCEPT  # VPN Site-à-Site

# NAT sortant
iptables -t nat -A POSTROUTING -o eth2 -j MASQUERADE

# FORWARD
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

# LAN → Internet : tout le trafic sortant est autorisé
iptables -A FORWARD -i eth1 -o eth2 -j ACCEPT

# Internet → LAN : ICMP uniquement (aucun service exposé depuis ce site)
iptables -A FORWARD -i eth2 -o eth1 -p icmp -j ACCEPT

# VPN Site-à-Site (tun0) ↔ LAN : accès complet inter-sites
iptables -A FORWARD -i tun0 -o eth1 -j ACCEPT
iptables -A FORWARD -i eth1 -o tun0 -j ACCEPT

# --- 6. DÉMARRAGE OPENVPN ---
mkdir -p /var/log/openvpn /var/run/openvpn

openvpn --config /etc/openvpn/site-to-site.conf \
        --daemon ovpn-s2s \
        --log /var/log/openvpn/site-to-site.log

echo "=== ENT-FIREWALL (Site Secondaire) initialisé ==="
