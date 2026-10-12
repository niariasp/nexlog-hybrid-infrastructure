#!/bin/sh
set -eu

echo "[NEXLOG] Iniciando bootstrap ACC-02"

# Verificar claves autorizadas de Ansible
if [ ! -s /root/.ssh/authorized_keys ]; then
    echo "[ERROR] authorized_keys no disponible"
    exit 1
fi

# Verificar respaldo de identidad SSH
BACKUP="/root/.ssh/nexlog-hostkeys"

if [ ! -s "$BACKUP/ssh_host_ed25519_key" ]; then
    echo "[ERROR] Respaldo SSH no disponible"
    exit 1
fi

# Recuperar dependencias cuando sea necesario
if ! command -v python3 >/dev/null 2>&1 || \
   ! command -v sshd >/dev/null 2>&1; then
    echo "[NEXLOG] Instalando Python y OpenSSH..."
    apk add --no-cache python3 openssh-server
fi

# Restaurar identidad SSH
mkdir -p /etc/ssh /run/sshd

cp -p "$BACKUP"/ssh_host_*_key* /etc/ssh/

chmod 600 /etc/ssh/ssh_host_*_key
chmod 644 /etc/ssh/ssh_host_*_key.pub

# Validar e iniciar SSH
/usr/sbin/sshd -t

if ! pidof sshd >/dev/null 2>&1; then
    /usr/sbin/sshd
fi

echo "[NEXLOG] Bootstrap ACC-02 completado"
