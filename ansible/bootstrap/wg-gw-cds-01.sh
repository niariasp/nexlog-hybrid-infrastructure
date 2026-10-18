#!/bin/sh
set -eu

echo "[NEXLOG] Restaurando WireGuard GW-CDS-01"

# Instalar herramientas si es necesario
if ! command -v wg >/dev/null 2>&1; then
    apk add --no-cache iproute2 wireguard-tools
fi

# Recuperar clave privada en ruta compatible
mkdir -p /etc/wireguard
chmod 700 /etc/wireguard
cp /etc/network/wireguard/private.key /etc/wireguard/private.key
chmod 600 /etc/wireguard/private.key

# Recuperar interfaz e IP del tunel
ip link show wg0 >/dev/null 2>&1 || ip link add wg0 type wireguard
ip -4 addr show dev wg0 | grep -q '172.27.0.2/30' || \
    ip addr add 172.27.0.2/30 dev wg0

# Configurar peer del CD Principal
wg set wg0 \
    listen-port 51820 \
    private-key /etc/wireguard/private.key \
    peer ECJViFb+oxkaxzVYrTtwTEzXtgCz1N/JjJeS7/+j3Ws= \
    allowed-ips 172.27.0.1/32,10.10.30.0/24

# Activar tunel y ruta hacia WMS
ip link set wg0 up
ip route replace 10.10.30.0/24 dev wg0
ip route replace prohibit 10.10.0.0/16

echo "[NEXLOG] WireGuard GW-CDS-01 restaurado"
