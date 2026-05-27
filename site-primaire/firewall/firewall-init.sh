#!/bin/sh
# ===================================================================
# firewall-init.sh - Site Primaire : ENT-FIREWALL
# Les clés doivent être générées à l'avance via prepare.sh
# ===================================================================

# --- 1. ROUTAGE IP ---
sysctl -w net.ipv4.ip_forward=1

# --- 2. INSTALLATION DES PAQUETS ---
apk update
apk add --no-cache iptables openvpn openvpn-auth-ldap

# --- 3. INTERFACES RÉSEAU ---
ip addr add 192.168.0.1/30 dev eth1   # LAN -> Switch Arista ENT-COR-01
ip link set eth1 up
ip addr add 192.168.5.1/30 dev eth2   # WAN -> CE Router (ENT-RTR-01)
ip link set eth2 up

# --- 4. ROUTES ---
ip route add 192.168.10.0/24 via 192.168.0.2   # Serveurs
ip route add 192.168.20.0/24 via 192.168.0.2   # Clients
ip route add 192.168.30.0/24 via 192.168.0.2   # VoIP
ip route add 120.0.0.0/16 via 192.168.5.2       # AS network via CE Router

# --- 5. RÈGLES IPTABLES ---
iptables -P INPUT   DROP
iptables -P FORWARD DROP
iptables -P OUTPUT  ACCEPT

iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT   -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

iptables -t nat -A POSTROUTING -o eth2 -j MASQUERADE

iptables -A FORWARD -i eth1 -o eth2 -j ACCEPT

iptables -A FORWARD -i eth2 -o eth1 -p tcp --dport 80   -j ACCEPT
iptables -A FORWARD -i eth2 -o eth1 -p tcp --dport 443  -j ACCEPT
iptables -A FORWARD -i eth2 -o eth1 -p tcp --dport 53   -j ACCEPT
iptables -A FORWARD -i eth2 -o eth1 -p udp --dport 53   -j ACCEPT
iptables -A FORWARD -i eth2 -o eth1 -p tcp --dport 5060 -j ACCEPT
iptables -A FORWARD -i eth2 -o eth1 -p udp --dport 5060 -j ACCEPT
iptables -A FORWARD -i eth2 -o eth1 -p tcp --dport 5061 -j ACCEPT
iptables -A FORWARD -i eth2 -o eth1 -p udp --dport 5061 -j ACCEPT
iptables -A FORWARD -i eth2 -o eth1 -p udp --dport 16384:32767 -j ACCEPT

iptables -A INPUT -i eth2 -p udp --dport 1194 -j ACCEPT   # VPN Nomade
iptables -A INPUT -i eth2 -p udp --dport 1195 -j ACCEPT   # VPN Site-à-Site

iptables -A FORWARD -i tun0 -j ACCEPT
iptables -A FORWARD -o tun0 -j ACCEPT
iptables -A FORWARD -i tun1 -j ACCEPT
iptables -A FORWARD -o tun1 -j ACCEPT

# --- 6. DÉMARRAGE OPENVPN ---
mkdir -p /var/log/openvpn /var/run/openvpn

openvpn --config /etc/openvpn/server-nomade.conf \
        --daemon ovpn-nomade \
        --log /var/log/openvpn/nomade.log

openvpn --config /etc/openvpn/site-to-site.conf \
        --daemon ovpn-s2s \
        --log /var/log/openvpn/site-to-site.log

echo "=== ENT-FIREWALL (Site Primaire) initialisé ==="
