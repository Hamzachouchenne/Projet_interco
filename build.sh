#!/bin/sh
# Build local Docker images for the lab topology.
# Run once before the first `clab deploy`, then again only when Dockerfiles change.
set -e

echo "=== Building lab Docker images ==="

# Base alpine (must be first — others derive from it)
docker build -t alpine-base:local         docker/alpine-base/

# Alpine derived images
docker build -t alpine-dhcp:local         docker/alpine-dhcp/
docker build -t alpine-web:local          docker/alpine-web/
docker build -t alpine-vpn-server:local   docker/alpine-vpn-server/
docker build -t alpine-client:local       docker/alpine-client/
docker build -t alpine-phone:local        docker/alpine-phone/

# Ubuntu/specialised images
docker build -t bind9-tools:local         docker/bind9-tools/
docker build -t asterisk-tools:local      docker/asterisk-tools/
docker build -t openldap-tools:local      docker/openldap-tools/
docker build -t phpldapadmin-tools:local  docker/phpldapadmin-tools/

echo "=== Done. You can now run: clab deploy -t topology.yml ==="
