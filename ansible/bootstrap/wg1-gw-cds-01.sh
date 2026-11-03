#!/bin/sh
# NexLog Chile - GW-CDS-01: tunel wg1 hacia la extension Cloud (GW-AZ-01).
# Se ejecuta despues de restore-wg0.sh. Los valores publicos del peer
# (clave publica y endpoint) se leen de wg1.env; la clave privada vive
# solo en el nodo (/etc/network/wireguard/private-az.key, permisos 600).
set -eu

DIR=/etc/network/wireguard
KEY="$DIR/private-az.key"
ENV="$DIR/wg1.env"

echo "[NEXLOG] Restaurando wg1 (CD Secundario <-> Azure)"

command -v wg >/dev/null 2>&1 || apk add --no-cache wireguard-tools

[ -s "$KEY" ] || { echo "[ERROR] Falta $KEY"; exit 1; }
[ -s "$ENV" ] || { echo "[ERROR] Falta $ENV (AZ_PUBKEY y AZ_ENDPOINT)"; exit 1; }
. "$ENV"

ip link show wg1 >/dev/null 2>&1 || ip link add wg1 type wireguard
wg set wg1 private-key "$KEY" \
    peer "$AZ_PUBKEY" \
    endpoint "$AZ_ENDPOINT" \
    allowed-ips 172.27.1.1/32,10.100.10.0/24 \
    persistent-keepalive 25
ip addr replace 172.27.1.2/30 dev wg1
ip link set wg1 up

# Solo la subred de aplicaciones de Azure; gestion y borde no se enrutan.
ip route replace 10.100.10.0/24 dev wg1

echo "[NEXLOG] wg1 restaurado"
