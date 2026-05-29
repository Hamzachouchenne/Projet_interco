# Mise en production — Guide de déploiement

## Prérequis

| Outil | Version minimale | Installation |
|---|---|---|
| Git | toute | `apt install git` / `brew install git` |
| Docker | 24+ | [docs.docker.com/get-docker](https://docs.docker.com/get-docker/) |
| containerlab | 0.54+ | voir ci-dessous |

### Installer containerlab

```bash
bash -c "$(curl -sL https://get.containerlab.dev)"
```

> Sur macOS avec Docker Desktop, containerlab s'installe dans WSL2 ou via Docker Engine natif. Sur Windows, utiliser WSL2.

---

## 1. Cloner le dépôt

```bash
git clone https://github.com/Hamzachouchenne/Projet_interco
cd Projet_interco
```

---

## 2. Importer l'image cEOS

L'image Arista cEOS-lab nécessite un compte sur [arista.com](https://www.arista.com).

1. Se connecter sur [arista.com/en/support/software-download](https://www.arista.com/en/support/software-download)
2. Télécharger **cEOS64-lab-4.30.2F.tar.xz** (section *EOS > cEOS-lab*)
3. Importer dans Docker :

```bash
docker import cEOS64-lab-4.30.2F.tar.xz ceos:4.30.2
```

Vérifier l'import :

```bash
docker images | grep ceos
# ceos   4.30.2   ...
```

---

## 3. Builder les images locales

Les images Docker du lab sont pré-packagées avec tous les outils nécessaires (pas de téléchargement au démarrage).

```bash
./build.sh
```

> À relancer uniquement si un Dockerfile dans `docker/` est modifié.

Vérifier les images construites :

```bash
docker images | grep ':local'
```

Les images produites :

| Image | Utilisée par |
|---|---|
| `alpine-base:local` | COR-01, switches |
| `alpine-dhcp:local` | Serveurs DHCP |
| `alpine-web:local` | SRV-WEB |
| `alpine-vpn-server:local` | Firewall site primaire |
| `alpine-client:local` | Clients PC, PARTICULIER-ENT, firewall site secondaire |
| `alpine-phone:local` | Téléphones IP |
| `bind9-tools:local` | Serveurs DNS |
| `asterisk-tools:local` | Serveur VoIP |
| `openldap-tools:local` | Serveur LDAP |
| `phpldapadmin-tools:local` | Interface LDAP web |

---

## 4. (Optionnel) Activer les interfaces externes

Les ports physiques permettent de connecter le lab à un vrai réseau BGP ou à des machines réelles. Ils sont **commentés par défaut** dans `topology.yml`.

### Identifier les interfaces physiques disponibles

```bash
ip link show
# Repérer les interfaces non utilisées (ex: enp1s0f0, enp1s0f1, enp2s0f0...)
```

### Décommenter et adapter les endpoints dans `topology.yml`

```yaml
#ports externes
- endpoints: ["AS-R1:eth4", "macvlan:enp1s0f0"]  # côté entreprise
- endpoints: ["AS-R2:eth4", "macvlan:enp1s0f1"]  # côté particulier/public
- endpoints: ["AS-R3:eth4", "macvlan:enp1s0f2"]  # peering BGP
```

> Remplacer `enp1s0f0`, `enp1s0f1`, `enp1s0f2` par les noms réels des interfaces sur la machine.

### S'assurer que les interfaces sont UP

```bash
sudo ip link set enp1s0f0 up
sudo ip link set enp1s0f1 up
sudo ip link set enp1s0f2 up
```

---

## 5. Déployer la topologie

```bash
sudo clab deploy -t topology.yml
```

Le déploiement prend **30 à 60 secondes** (les packages sont déjà dans les images).

### Vérifier que tous les containers tournent

```bash
sudo clab inspect -t topology.yml
```

---

## 6. Vérifications de base

### DHCP public (PARTICULIER-ENT)

```bash
docker exec clab-company-network-project-PARTICULIER-ENT ip addr show eth1
# Doit afficher une IP en 120.0.2.x/24
```

### DNS public

```bash
docker exec clab-company-network-project-PARTICULIER-ENT nslookup web.entreprise.lab
# Doit retourner 120.0.1.2
```

### OSPF AS10

```bash
docker exec clab-company-network-project-AS-R2 Cli -p 15 -c "show ip ospf neighbor"
# Doit afficher AS-R1 et AS-R3 en état FULL
```

### DHCP entreprise

```bash
docker exec clab-company-network-project-ENT-SITE-PRIM-SRV-DHCP cat /tmp/dnsmasq.leases
# Doit lister les baux des clients VLAN 20 et VLAN 30
```

### VPN nomade (depuis PARTICULIER-ENT)

```bash
docker exec -it clab-company-network-project-PARTICULIER-ENT sh
# Dans le container :
openvpn --config /root/vpn-nomade.ovpn --auth-user-pass /root/alice.txt \
        --daemon ovpn-alice --log /root/alice.log
sleep 5 && cat /root/alice.log | tail -5
# Doit se terminer par "Initialization Sequence Completed"
```

---

## 7. Arrêter le lab

```bash
sudo clab destroy -t topology.yml
```

---

## Adressage de référence

| Réseau | Subnet | Gateway |
|---|---|---|
| AS10 — Serveurs | 120.0.14.0/24 | 120.0.14.1 (AS-R3) |
| AS10 — DNS | 120.0.14.2 | — |
| AS10 — DHCP public | 120.0.14.3 | — |
| AS10 — Public Access | 120.0.2.0/24 | 120.0.2.1 (AS-R2) |
| Entreprise — Serveurs | 192.168.10.0/24 | 192.168.10.254 (COR-01) |
| Entreprise — Clients | 192.168.20.0/24 | 192.168.20.254 (COR-01) |
| Entreprise — VoIP | 192.168.30.0/24 | 192.168.30.254 (COR-01) |
| Site secondaire — Clients | 192.168.60.0/24 | 192.168.60.254 (COR-01) |
| Site secondaire — VoIP | 192.168.70.0/24 | 192.168.70.254 (COR-01) |
| VPN nomade | 10.8.0.0/24 | 10.8.0.1 (Firewall) |
