#!/bin/bash

set -e

echo "🔧 Instalando Docker..."

# Actualizar sistema
sudo apt update
sudo apt install -y ca-certificates curl

# Keyrings
sudo install -m 0755 -d /etc/apt/keyrings

# Descargar clave GPG de Docker
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Añadir repositorio
echo "📦 Añadiendo repositorio Docker..."
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

# Instalar Docker
sudo apt update -y
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Permitir usar docker sin sudo
sudo usermod -aG docker $USER

echo "🐳 Docker instalado"

# Crear estructura
mkdir -p webtop
cd webtop

echo "📝 Creando Dockerfile..."

cat <<EOF > Dockerfile
FROM lscr.io/linuxserver/webtop:ubuntu-xfce

RUN apt update && \
    apt install -y wget gpg apt-transport-https && \
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /usr/share/keyrings/microsoft.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list && \
    apt update && \
    apt install -y code git && \
    apt clean
EOF

echo "📝 Creando docker-compose.yml..."

cat <<EOF > docker-compose.yml
services:
  webtop:
    build: .
    container_name: webtop
    security_opt:
      - seccomp:unconfined
    ports:
      - "3000:3000"
      - "443:3001"
      - "3389:3389"
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/Madrid
    volumes:
      - ./config:/config
      - ./workspace:/workspace
      - /var/run/docker.sock:/var/run/docker.sock
    shm_size: "1gb"
    restart: unless-stopped
EOF

echo "🚀 Construyendo y levantando contenedor..."

sudo docker compose up -d --build

echo "✅ Todo listo"
echo "👉 Accede a: http://localhost:3000"
echo "⚠️ Reinicia sesión o ejecuta: newgrp docker"
