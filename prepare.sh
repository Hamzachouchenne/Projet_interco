#!/bin/sh
# ===================================================================
# prepare.sh - Génération des clés cryptographiques avant le deploy
# À lancer UNE SEULE FOIS depuis la racine du projet :
#   sh prepare.sh && clab deploy -t topology.yml
#
# Utilise Docker, aucune dépendance locale requise.
# Idempotent : ne régénère rien si les clés existent déjà.
# ===================================================================

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PKI_DIR="$SCRIPT_DIR/site-primaire/firewall/pki"
PSK_PRI="$SCRIPT_DIR/site-primaire/firewall/keys/secret.key"
PSK_SEC="$SCRIPT_DIR/site-secondaire/firewall/keys/secret.key"

# --- 1. CLÉ PSK SITE-À-SITE ---
if [ -f "$PSK_PRI" ] && [ -f "$PSK_SEC" ]; then
    echo "[1/2] PSK déjà présente dans les deux sites, on passe."
else
    echo "[1/2] Génération de la clé PSK site-à-site..."
    mkdir -p "$SCRIPT_DIR/site-primaire-firewall/keys" \
             "$SCRIPT_DIR/site-secondaire-firewall/keys"
    docker run --rm \
        -v "$SCRIPT_DIR/site-primaire-firewall/keys:/pri" \
        -v "$SCRIPT_DIR/site-secondaire-firewall/keys:/sec" \
        alpine:latest \
        sh -c "apk add --no-cache openvpn -q \
               && openvpn --genkey secret /pri/secret.key \
               && cp /pri/secret.key /sec/secret.key \
               && chmod 600 /pri/secret.key /sec/secret.key"
    echo "      -> site-primaire-firewall/keys/secret.key"
    echo "      -> site-secondaire-firewall/keys/secret.key"
fi

# --- 2. PKI VPN NOMADE ---
# On vérifie la présence du ca.key (pas juste ca.crt) pour pouvoir
# générer des certificats clients avec add-client.sh
if [ -f "$PKI_DIR/easyrsa/private/ca.key" ]; then
    echo "[2/2] PKI déjà générée (avec ca.key), on passe."
else
    echo "[2/2] Génération de la PKI (~30s)..."
    mkdir -p "$PKI_DIR"
    docker run --rm \
        -v "$PKI_DIR:/pki-out" \
        alpine:latest \
        sh -c "
            set -e
            apk add --no-cache openvpn easy-rsa -q
            EASYRSA=\$(find /usr -name easyrsa | head -1)

            # PKI complet dans easyrsa/ (inclut ca.key pour signer les clients)
            \$EASYRSA --pki-dir=/pki-out/easyrsa init-pki
            \$EASYRSA --pki-dir=/pki-out/easyrsa --batch --req-cn=Site-Primaire-CA build-ca nopass
            \$EASYRSA --pki-dir=/pki-out/easyrsa --batch build-server-full server nopass
            \$EASYRSA --pki-dir=/pki-out/easyrsa gen-crl
            openvpn --genkey tls-auth /pki-out/easyrsa/ta.key

            # Fichiers utilisés directement par OpenVPN (à la racine de pki/)
            cp /pki-out/easyrsa/ca.crt              /pki-out/ca.crt
            cp /pki-out/easyrsa/issued/server.crt   /pki-out/server.crt
            cp /pki-out/easyrsa/private/server.key  /pki-out/server.key
            cp /pki-out/easyrsa/crl.pem             /pki-out/crl.pem
            cp /pki-out/easyrsa/ta.key              /pki-out/ta.key
            chmod 600 /pki-out/server.key /pki-out/ta.key
        "
    echo "      -> site-primaire-firewall/pki/"
fi

echo ""
echo "=== Prêt. Lance maintenant ==="
echo "    clab deploy -t topology.yml"
echo ""
echo "Pour créer un accès VPN nomade :"
echo "    sh add-client.sh <nom_utilisateur>"
