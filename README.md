# NexLog Chile - Hybrid Network Infrastructure

Proof of Concept desarrollado para el proyecto de título:

**Diseño e implementación de una infraestructura de red híbrida con integración Cloud y automatización para una empresa de logística y distribución.**

## Arquitectura actual

El Centro de Distribución Principal utiliza una arquitectura Collapsed Core + Access.

- FortiGate: seguridad perimetral, NAT y salida WAN.
- DIST-CORE-01: gateways, routing inter-VLAN y segmentación.
- ACC-01 / ACC-02: switching de acceso y VLANs.
- AlmaLinux: servicio web representativo del WMS.
- Ansible: automatización de configuración.
- Git/GitHub: control de versiones y trazabilidad.

## Redes

| Segmento | Red |
|---|---|
| VLAN 10 - ADMIN | 10.10.10.0/24 |
| VLAN 20 - OPERACIONES | 10.10.20.0/24 |
| VLAN 30 - SERVIDORES | 10.10.30.0/24 |
| Tránsito Firewall | 10.255.255.0/30 |
| Management | 192.168.99.0/24 |

## Automatización

Los playbooks Ansible permiten reconstruir la configuración funcional de:

- puertos access;
- trunks 802.1Q;
- interfaces L3;
- routing IPv4;
- tránsito hacia FortiGate;
- segmentación mediante OpenFlow.

El acceso de management y SSH se considera actualmente un bootstrap previo.

## Estado

**v0.1-cdp:** Centro de Distribución Principal funcional.
