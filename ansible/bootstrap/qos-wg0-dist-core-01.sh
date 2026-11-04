#!/bin/sh
# NexLog Chile - QoS en el enlace entre sedes (wg0) de DIST-CORE-01
#
# Simula un enlace WAN de capacidad limitada (RATE_KBIT) y prioriza el
# trafico del WMS hacia el CD Secundario sobre el trafico masivo.
#
# Uso:
#   sh qos-wg0-dist-core-01.sh on     # HTB con 3 clases (WMS / gestion+ICMP / resto)
#   sh qos-wg0-dist-core-01.sh flat   # solo limite de capacidad, SIN prioridad (linea base)
#   sh qos-wg0-dist-core-01.sh show   # contadores por clase
#   sh qos-wg0-dist-core-01.sh off    # retira todo
#
# Variables opcionales: DEV (wg0), RATE_KBIT (20000 = 20 Mbit/s), WMS_IP (10.10.30.10)

DEV="${DEV:-wg0}"
RATE_KBIT="${RATE_KBIT:-20000}"
WMS_IP="${WMS_IP:-10.10.30.10}"

WMS_KBIT=$((RATE_KBIT * 60 / 100))   # garantizado al WMS
OAM_KBIT=$((RATE_KBIT * 10 / 100))   # gestion e ICMP
BULK_KBIT=$((RATE_KBIT * 30 / 100))  # todo lo demas

command -v tc >/dev/null 2>&1 || apk add -q iproute2
ip link show "$DEV" >/dev/null 2>&1 || { echo "[NEXLOG] ERROR: $DEV no existe (ejecutar restore-wg0.sh)"; exit 1; }

clear_qos() { tc qdisc del dev "$DEV" root 2>/dev/null; return 0; }

case "${1:-on}" in
  off)
    clear_qos
    echo "[NEXLOG] QoS retirado de $DEV"
    ;;
  show)
    tc -s qdisc show dev "$DEV"
    tc -s class show dev "$DEV"
    ;;
  flat)
    clear_qos
    tc qdisc add dev "$DEV" root handle 1: htb default 10 r2q 100 || exit 1
    tc class add dev "$DEV" parent 1: classid 1:1 htb rate "${RATE_KBIT}kbit" ceil "${RATE_KBIT}kbit"
    tc class add dev "$DEV" parent 1:1 classid 1:10 htb rate "${RATE_KBIT}kbit" ceil "${RATE_KBIT}kbit"
    echo "[NEXLOG] $DEV limitado a ${RATE_KBIT} kbit/s SIN prioridad (cola FIFO unica)"
    ;;
  on)
    clear_qos
    tc qdisc add dev "$DEV" root handle 1: htb default 30 r2q 100 || exit 1
    tc class add dev "$DEV" parent 1: classid 1:1 htb rate "${RATE_KBIT}kbit" ceil "${RATE_KBIT}kbit"
    # 1:10 WMS (AF21): prioridad 0, garantizado 60 %, puede usar todo si esta libre
    tc class add dev "$DEV" parent 1:1 classid 1:10 htb rate "${WMS_KBIT}kbit" ceil "${RATE_KBIT}kbit" prio 0
    # 1:20 Gestion / ICMP (CS2): prioridad 1, garantizado 10 %
    tc class add dev "$DEV" parent 1:1 classid 1:20 htb rate "${OAM_KBIT}kbit" ceil "${RATE_KBIT}kbit" prio 1
    # 1:30 Resto / masivo (AF11-CS1): prioridad 2, garantizado 30 %
    tc class add dev "$DEV" parent 1:1 classid 1:30 htb rate "${BULK_KBIT}kbit" ceil "${RATE_KBIT}kbit" prio 2
    LEAF=pfifo
    for c in 10 20 30; do
      if tc qdisc add dev "$DEV" parent 1:$c handle $c: fq_codel 2>/dev/null; then LEAF=fq_codel
      elif tc qdisc add dev "$DEV" parent 1:$c handle $c: sfq perturb 10 2>/dev/null; then LEAF=sfq
      fi
    done
    # Clasificacion: respuestas HTTP/HTTPS del WMS hacia el CD Secundario
    tc filter add dev "$DEV" parent 1: protocol ip prio 1 u32 match ip src "$WMS_IP"/32 match ip sport 80 0xffff flowid 1:10
    tc filter add dev "$DEV" parent 1: protocol ip prio 1 u32 match ip src "$WMS_IP"/32 match ip sport 443 0xffff flowid 1:10
    # Paquetes ya marcados AF21 (DSCP 18 -> TOS 0x48)
    tc filter add dev "$DEV" parent 1: protocol ip prio 2 u32 match ip dsfield 0x48 0xfc flowid 1:10
    # ICMP (diagnostico) y SSH (gestion)
    tc filter add dev "$DEV" parent 1: protocol ip prio 3 u32 match ip protocol 1 0xff flowid 1:20
    tc filter add dev "$DEV" parent 1: protocol ip prio 3 u32 match ip dport 22 0xffff flowid 1:20
    echo "[NEXLOG] QoS activo en $DEV: total ${RATE_KBIT} kbit/s | WMS ${WMS_KBIT} | gestion/ICMP ${OAM_KBIT} | resto ${BULK_KBIT} (kbit/s garantizados; cola por clase: $LEAF)"
    ;;
  *)
    echo "Uso: $0 on|flat|show|off"; exit 2
    ;;
esac
