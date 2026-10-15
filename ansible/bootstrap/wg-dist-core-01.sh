#!/bin/sh
set -eu

echo "[NEXLOG] Restaurando WireGuard DIST-CORE-01"

# Verificar herramientas
if ! command -v wg >/dev/null 2>&1; then
    apk add --no-cache iproute2 wireguard-tools
fi

# Recuperar clave privada
mkdir -p /etc/wireguard
chmod 700 /etc/wireguard
cp /etc/network/wireguard/private.key /etc/wireguard/private.key
chmod 600 /etc/wireguard/private.key

# Recuperar interfaz e IP del tunel
ip link show wg0 >/dev/null 2>&1 || ip link add wg0 type wireguard
ip -4 addr show dev wg0 | grep -q '172.27.0.1/30' || \
    ip addr add 172.27.0.1/30 dev wg0

# Configurar peer del CD Secundario
wg set wg0 \
    listen-port 51820 \
    private-key /etc/wireguard/private.key \
    peer hxn+K0WLpwef72EoNJhHAbZI8vurnA+af2obLyZoCHQ= \
    endpoint 192.168.42.231:51820 \
    allowed-ips 172.27.0.2/32,10.20.20.0/24 \
    persistent-keepalive 25

# Activar tunel y ruta de retorno
ip link set wg0 up
ip route replace 10.20.20.0/24 dev wg0

echo "[NEXLOG] WireGuard DIST-CORE-01 restaurado"
