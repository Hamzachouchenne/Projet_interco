#!/bin/sh
# ===================================================================
# firewall-init.sh - Site Secondaire : AS13-FIREWALL
# Les clés doivent être générées à l'avance via prepare.sh
# ===================================================================

# --- 1. ROUTAGE IP ---
sysctl -w net.ipv4.ip_forward=1

# --- 2. INSTALLATION DES PAQUETS ---
apk update
apk add --no-cache iptables openvpn dnsmasq

# --- 3. INTERFACES RÉSEAU ---
ip addr add 203.0.113.2/30 dev eth1   # WAN -> Site Primaire
ip link set eth1 up
ip addr add 192.168.50.1/24 dev eth2  # LAN -> Bridge Site Secondaire
ip link set eth2 up

# --- 4. RÈGLES IPTABLES ---
iptables -P INPUT   DROP
iptables -P FORWARD DROP
iptables -P OUTPUT  ACCEPT

iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT   -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

iptables -t nat -A POSTROUTING -o eth1 -j MASQUERADE

iptables -A FORWARD -i eth2 -o eth1 -j ACCEPT
iptables -A INPUT   -i eth1 -p udp --dport 1195 -j ACCEPT
iptables -A FORWARD -i tun0 -j ACCEPT
iptables -A FORWARD -o tun0 -j ACCEPT

iptables -A INPUT -i eth2 -p udp --dport 53 -j ACCEPT
iptables -A INPUT -i eth2 -p tcp --dport 53 -j ACCEPT

# --- 5. DÉMARRAGE DU TUNNEL VPN VERS LE SITE PRIMAIRE ---
mkdir -p /var/log/openvpn

openvpn --config /etc/openvpn/site-to-site.conf \
        --daemon ovpn-s2s \
        --log /var/log/openvpn/s2s.log

# Laisser le tunnel s'établir avant de démarrer le DNS forwarder
sleep 3

# --- 6. FORWARDER DNS ---
# Transmet les requêtes DNS des clients vers SRV-DNS du site primaire via le tunnel
cat > /etc/dnsmasq.conf << 'EOF'
no-resolv
server=192.168.10.11
interface=eth2
listen-address=192.168.50.1
except-interface=lo
except-interface=eth1
except-interface=tun0
log-queries
EOF

dnsmasq

echo "=== AS13-FIREWALL (Site Secondaire) initialisé ==="
