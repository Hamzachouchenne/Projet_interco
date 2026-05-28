#!/bin/sh
# ===================================================================
# firewall-init.sh - Site Primaire : ENT-FIREWALL
# Les clés doivent être générées à l'avance via prepare.sh
# ===================================================================

# --- 1. ROUTAGE IP ---
sysctl -w net.ipv4.ip_forward=1

# --- 2. INSTALLATION DES PAQUETS ---
apk update
apk add --no-cache iptables openvpn openvpn-auth-ldap tcpdump

# --- 3. INTERFACES RÉSEAU ---
ip addr add 192.168.0.1/30 dev eth1   # LAN -> COR-01
ip link set eth1 up
ip addr add 120.0.1.2/30 dev eth2     # WAN -> AS-R1
ip link set eth2 up

# --- 4. ROUTES ---
ip route add 192.168.10.0/24 via 192.168.0.2   # Serveurs
ip route add 192.168.20.0/24 via 192.168.0.2   # Clients
ip route add 192.168.30.0/24 via 192.168.0.2   # VoIP
ip route del default
ip route add default via 120.0.1.1              # Défaut -> AS-R1

# --- 5. RÈGLES IPTABLES ---
iptables -P INPUT   DROP
iptables -P FORWARD DROP
iptables -P OUTPUT  ACCEPT

# INPUT : trafic à destination du firewall lui-même
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -i eth2 -p icmp            -j ACCEPT
iptables -A INPUT -i eth2 -p udp --dport 1194 -j ACCEPT  # VPN Nomade
iptables -A INPUT -i eth2 -p udp --dport 1195 -j ACCEPT  # VPN Site-à-Site

# NAT sortant + exposition du serveur web
iptables -t nat -A POSTROUTING -o eth2 -j MASQUERADE
iptables -t nat -A PREROUTING -i eth2 -p tcp --dport 80  -j DNAT --to-destination 192.168.10.10:80
iptables -t nat -A PREROUTING -i eth2 -p tcp --dport 443 -j DNAT --to-destination 192.168.10.10:443

# FORWARD
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

# LAN → Internet : tout le trafic sortant est autorisé
iptables -A FORWARD -i eth1 -o eth2 -j ACCEPT

# Internet → LAN : uniquement HTTP/HTTPS (DNAT web server) + ICMP
iptables -A FORWARD -i eth2 -o eth1 -p tcp --dport 80  -j ACCEPT
iptables -A FORWARD -i eth2 -o eth1 -p tcp --dport 443 -j ACCEPT
iptables -A FORWARD -i eth2 -o eth1 -p icmp            -j ACCEPT

# VPN Nomade (tun0) ↔ LAN : accès complet pour les utilisateurs nomades
iptables -A FORWARD -i tun0 -o eth1 -j ACCEPT
iptables -A FORWARD -i eth1 -o tun0 -j ACCEPT

# VPN Site-à-Site (tun1) ↔ LAN : accès complet depuis/vers le site secondaire
iptables -A FORWARD -i tun1 -o eth1 -j ACCEPT
iptables -A FORWARD -i eth1 -o tun1 -j ACCEPT

# --- 6. DÉMARRAGE OPENVPN ---
mkdir -p /var/log/openvpn /var/run/openvpn

# On force l'interface tun0 pour les nomades
openvpn --config /etc/openvpn/server-nomade.conf \
        --dev tun0 \
        --daemon ovpn-nomade \
        --log /var/log/openvpn/nomade.log

# On force l'interface tun1 pour le site-à-site
openvpn --config /etc/openvpn/site-to-site.conf \
        --dev tun1 \
        --daemon ovpn-s2s \
        --log /var/log/openvpn/site-to-site.log

# --- 7. ROUTES DE RETOUR (VERS SITE SECONDAIRE) ---
# On attend 2 secondes pour être sûr que l'interface tun1 a eu le temps de se créer
sleep 2

# On indique au routeur que le LAN (60.0) et la VoIP (70.0) du site secondaire sont derrière le VPN
ip route add 192.168.60.0/24 dev tun1
ip route add 192.168.70.0/24 dev tun1

echo "=== ENT-FIREWALL (Site Primaire) initialisé ==="