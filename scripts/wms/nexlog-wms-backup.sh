#!/usr/bin/env bash
set -euo pipefail

export PATH="/usr/local/bin:/usr/bin:/bin:$PATH"

source /root/nexlog-secrets/azcopy-spn.env

ORIGEN="/var/backups/nexlog/wms-inventario-demo.csv"
FECHA=$(date -u +%Y%m%dT%H%M%SZ)

DESTINO="https://stnexlog91da1dd1.blob.core.windows.net/wms-backups/wms/automaticos/wms-inventario-${FECHA}.csv"

if [ ! -s "$ORIGEN" ]; then
    echo "ERROR: archivo de respaldo inexistente o vacio"
    exit 1
fi

echo "NEXLOG: iniciando respaldo $FECHA"

azcopy copy "$ORIGEN" "$DESTINO" --overwrite=false

echo "NEXLOG: transferencia finalizada correctamente"
