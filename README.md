# NexLog Chile — Infraestructura de red híbrida (PoC)

Prueba de concepto del proyecto de título *"Diseño e implementación de una infraestructura de red híbrida con integración Cloud y automatización para una empresa de logística y distribución"* (Ingeniería en Conectividad y Redes, Duoc UC, 2026).

NexLog Chile es una empresa **ficticia** de logística 3PL. La PoC conecta dos centros de distribución (CD) simulados en GNS3 y una extensión cloud en Microsoft Azure, con segmentación, controles de seguridad y automatización.

> Alcance: laboratorio académico. La WAN entre sedes es una red NAT simulada de GNS3; no hay túnel privado hacia Azure (el respaldo usa HTTPS autenticado contra un endpoint público). Ver [Limitaciones](#limitaciones).

## Arquitectura

| Componente | Implementación | Función |
|---|---|---|
| Perímetro CD Principal | FortiGate VM 7.6.7 (licencia eval) | NAT, políticas norte-sur con log de denegación |
| Core / distribución | Open vSwitch sobre Alpine (`DIST-CORE-01`) | Collapsed core: gateways VLAN, routing, OpenFlow, **nftables** |
| Acceso | Open vSwitch (`ACC-01`, `ACC-02`) | Puertos access y uplink trunk 802.1Q |
| WMS representativo | AlmaLinux + Apache (`SRV-WMS-01`) | Servicio web y respaldo a Azure Blob |
| CD Secundario | Alpine (`GW-CDS-01`) | Gateway del sitio 2 y extremo WireGuard |
| VPN sitio a sitio | WireGuard (UDP 51820) | Acceso del CD Secundario **solo** al WMS |
| Gestión | Red fuera de banda 192.168.99.0/24 | SSH de Ansible a los equipos de red |
| Automatización | Ansible en contenedor (`ANSIBLE-V1-TEST`) | Configuración idempotente de core y acceso |
| Cloud | Azure (Terraform) | Storage + RBAC para respaldos; VNet, subredes y NSG |

### Direccionamiento

| Segmento | Red |
|---|---|
| VLAN 10 — ADMIN | 10.10.10.0/24 |
| VLAN 20 — OPERACIONES | 10.10.20.0/24 |
| VLAN 30 — SERVIDORES (WMS 10.10.30.10) | 10.10.30.0/24 |
| Tránsito DIST ↔ FortiGate | 10.255.255.0/30 |
| Gestión fuera de banda | 192.168.99.0/24 |
| LAN CD Secundario | 10.20.20.0/24 |
| Túnel WireGuard | 172.27.0.0/30 |
| VNet Azure (extensión del CD Secundario) | 10.100.0.0/16 (`snet-apps` 10.100.10.0/24, `snet-mgmt` 10.100.20.0/24) |

## Modelo de seguridad

| Flujo | Decisión | Dónde se aplica |
|---|---|---|
| ADMIN ↔ OPERACIONES | Denegado | OpenFlow (OVS) + nftables (segunda capa) |
| ADMIN / OPERACIONES → WMS | HTTP/HTTPS e ICMP | nftables `forward` |
| CD Secundario → WMS | HTTP/HTTPS e ICMP por el túnel | Rutas `prohibit` en GW-CDS-01 + `AllowedIPs` WireGuard + nftables |
| CD Secundario → resto de Site 1, gestión y tránsito | Rechazo explícito (ICMP *administratively prohibited*) | Rutas `prohibit` en GW-CDS-01 |
| Usuarios / servidores → red de gestión y tránsito | Denegado y registrado | nftables (`input` y `forward`) |
| SSH a DIST-CORE-01 | Solo por `eth0` desde 192.168.99.0/24 | nftables `input` |
| LAN → Internet | Solo HTTP, HTTPS, DNS, NTP, PING | FortiGate (política 1) |
| Gestión → Internet | Solo HTTP, HTTPS, DNS, NTP | FortiGate (política 2) |
| Underlay WireGuard | Solo DIST → endpoint del CD Secundario, UDP 51820 | FortiGate (política 3) |
| Todo lo demás | Denegado con log | FortiGate (deny implícito con `fwpolicy-implicit-log`) |

La política nftables se carga en el **bootstrap**, antes de que Ansible restaure gateways y OpenFlow, para que no exista una ventana sin segmentación tras un reinicio.

## Estructura del repositorio

```text
ansible/
  inventory.ini
  playbooks/
    configure_distribution.yml   # core: trunks, gateways, tránsito, OpenFlow, limpieza de puertos, verificación nftables
    configure_access.yml         # acceso: puertos access, uplink, limpieza de puertos
  bootstrap/
    dist-core-01.sh              # SSH + carga de nftables (persistente en /etc/network)
    nftables-dist-core-01.nft    # política deny-by-default de DIST-CORE-01
    acc-01.sh, acc-02.sh         # SSH en switches de acceso
    wg-dist-core-01.sh           # restauración WireGuard (Site 1)
    wg-gw-cds-01.sh              # restauración WireGuard + rutas prohibit (Site 2)
docker/ansible-controller/Dockerfile
scripts/wms/
  nexlog-wms-backup.sh           # respaldo WMS → Azure Blob (AzCopy + SPN con certificado)
  nexlog-wms-backup.cron
  azcopy-spn.env.example         # plantilla SIN valores reales
terraform/
  azure/                         # Storage, contenedor privado, RBAC (estado propio)
  azure-network/                 # VNet, subredes y NSG deny-by-default (estado separado)
```

## Recuperación tras reinicio

Los nodos Alpine de GNS3 pierden su estado de red (y, en arranque en frío, los paquetes instalados). La recuperación es en dos capas:

1. **Bootstrap local** en cada nodo (`/etc/network/nexlog-bootstrap.sh`): dependencias, SSH y, en DIST-CORE-01, la política nftables.
2. **WireGuard**: `/etc/network/wireguard/restore-wg0.sh` en DIST-CORE-01 y GW-CDS-01.
3. **Ansible** desde el controlador:

```sh
cd /root/nexlog-hybrid-infrastructure
ansible-playbook -i ansible/inventory.ini ansible/playbooks/configure_distribution.yml --private-key /root/.ssh/id_ed25519
ansible-playbook -i ansible/inventory.ini ansible/playbooks/configure_access.yml --private-key /root/.ssh/id_ed25519
```

Los playbooks son **idempotentes**: una segunda ejecución sobre una red ya configurada reporta `changed=0`; un `changed` distinto de cero indica una desviación real de la configuración.

## Azure (Terraform)

```powershell
cd terraform/azure-network
terraform init
terraform plan -out tfplan
terraform apply tfplan
```

- La suscripción se toma de `ARM_SUBSCRIPTION_ID`; el provider usa `resource_provider_registrations = "none"`.
- `terraform/azure` y `terraform/azure-network` tienen **estados separados**.
- Los NSG terminan en una regla `Deny-All-Inbound` (prioridad 4000), por encima de las reglas por defecto de Azure.

## Manejo de secretos

No se versionan claves privadas WireGuard, certificados/PFX, contraseñas, `azcopy-spn.env`, `terraform.tfstate` ni planes de Terraform. Los secretos viven solo en los nodos (permisos 600) y los scripts los referencian por ruta. El historial del repositorio fue revisado: solo contiene rutas, marcadores de plantilla y **claves públicas** WireGuard.

## Limitaciones

- WAN entre sedes simulada (NAT de GNS3); no se midió rendimiento WAN real.
- La conexión WMS → Azure usa HTTPS a un endpoint público autenticado (no Private Endpoint ni VPN a Azure).
- El respaldo transfiere un CSV representativo; no es un respaldo de base de datos de un WMS comercial. Depende de que el servidor esté encendido a la hora programada.
- FortiGate con licencia de evaluación (1 vCPU, 2 GB, número limitado de políticas).
- Destinos `all` en las políticas de salida a Internet; mejora posible con objetos FQDN.

## Versiones

| Tag | Hito |
|---|---|
| `v0.1-cdp` | CD Principal funcional |
| `v1.0-final` | Cierre de la PoC (se crea tras la validación final): dos CD, VPN, Azure, endurecimiento y automatización idempotente |
