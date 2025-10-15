#!/usr/bin/env bash
#
# detectar_dispositivos.sh
# Purpose: Educational — preliminary device discovery on a local network.
# Usage: ./detectar_dispositivos.sh -i <interface> [-a]
#  -i INTERFACE : network interface (required)
#  -a           : enable more aggressive scans (optional, requires sudo)
#
# DISCLAIMER: Use this script ONLY on networks you own or have explicit permission to test.
# This repository is for educational and defensive purposes. Do not use on production/public networks.
#
# License: MIT (add LICENSE file to repo)
set -euo pipefail

PROGNAME="$(basename "$0")"
INTERFACE=""
AGGRESSIVE=0

usage() {
  cat <<EOF
Usage: $PROGNAME -i <interface> [-a]
  -i INTERFACE   Interface to scan (example: eth0)
  -a             Aggressive mode: enables OS detection and service versioning (requires sudo)
EOF
  exit 1
}

while getopts ":i:ah" opt; do
  case ${opt} in
    i) INTERFACE="${OPTARG}" ;;
    a) AGGRESSIVE=1 ;;
    h) usage ;;
    *) usage ;;
  esac
done

if [[ -z "$INTERFACE" ]]; then
  echo "[!] Interfaz no definida."
  usage
fi

# Dependencias básicas
deps=(arp-scan nmap awk sort)
for cmd in "${deps[@]}"; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "[!] Falta: $cmd. Instalar (ej): sudo apt install $cmd"
    exit 1
  fi
done

echo "[*] Recon (preliminar) en interfaz: $INTERFACE"
echo "[*] Nota: este script realiza peticiones de red. Ejecuta solo en redes autorizadas."

# Ejecutar arp-scan (requiere sudo on many systems)
if ! sudo -n true 2>/dev/null; then
  echo "[*] No se detectó permiso sudo sin contraseña. Se solicitará contraseña para operaciones necesarias."
fi

# Ejecutar arp-scan para listado de hosts (localnet)
raw_hosts=$(sudo arp-scan --localnet --interface="$INTERFACE" 2>/dev/null || true)

# Extraer líneas con IPs (heurística); evitar encabezados
HOSTS=$(echo "$raw_hosts" | awk '/([0-9]{1,3}\.){3}[0-9]{1,3}/ {print $1, $2, substr($0, index($0,$3))}' | sort -u || true)

if [[ -z "$HOSTS" ]]; then
  echo "[!] No se encontraron hosts con arp-scan o no se pudo ejecutar."
  exit 0
fi

printf "%-15s | %-30s | %-15s | %-20s | %-12s\n" "IP" "FABRICANTE" "OS (approx)" "PUERTOS ABIERTOS" "TIPO"
printf "%s\n" "-----------------------------------------------------------------------------------------------------"

# Función para clasificar tipo básico
classify() {
  local ip="$1" vendor="$2" os="$3" ports="$4"
  local tipo="Desconocido"
  if [[ "$vendor" =~ (Samsung|Huawei|Xiaomi|Motorola) ]] && [[ "$os" =~ Android ]]; then
    tipo="Móvil/Tablet"
  elif [[ "$vendor" =~ (LG|Sony|Samsung) ]] && [[ "$ports" =~ 8008|8009 ]]; then
    tipo="Smart TV"
  elif [[ "$os" =~ Windows ]]; then
    tipo="PC Windows"
  elif [[ "$os" =~ Linux ]] && [[ "$ports" =~ 22 ]]; then
    tipo="Servidor Linux"
  elif [[ "$ports" =~ 9100 ]]; then
    tipo="Impresora"
  elif [[ "$ip" =~ \.1$ ]]; then
    tipo="Router"
  fi
  echo "$tipo"
}

while IFS= read -r line; do
  # line: ip mac vendor...
  ip=$(echo "$line" | awk '{print $1}')
  mac=$(echo "$line" | awk '{print $2}')
  vendor=$(echo "$line" | cut -d' ' -f3- | xargs)

  # Saltar si ip vacía
  [[ -z "$ip" ]] && continue

  # Opcional: escaneo agresivo
  os="Desconocido"
  puertos="Ninguno"
  if [[ "$AGGRESSIVE" -eq 1 ]]; then
    # nmap -sT for non-root TCP connect scan; -O (OS) commented unless asked (agressive)
    if sudo -n true 2>/dev/null; then
      os=$(sudo nmap -sT --version-light --top-ports 10 --open "$ip" 2>/dev/null | awk -F': ' '/^Service Info:|OS details:/{print $2}' | head -n1 | xargs || true)
      # Ports
      puertos=$(sudo nmap -sT --top-ports 10 --open "$ip" 2>/dev/null | awk '/open/{print $1}' | tr '\n' ',' | sed 's/,$//')
    else
      # Fallback less intrusive
      puertos=$(nmap -Pn --top-ports 10 --open "$ip" 2>/dev/null | awk '/open/{print $1}' | tr '\n' ',' | sed 's/,$//')
    fi
  else
    # Light probe: ping to check alive and simple TCP connect for common ports (no OS detection)
    if ping -c 1 -W 1 "$ip" &>/dev/null; then
      # quick nmap connect scan (non-root)
      puertos=$(nmap -Pn --top-ports 5 --open "$ip" 2>/dev/null | awk '/open/{print $1}' | tr '\n' ',' | sed 's/,$//')
    fi
  fi

  [[ -z "$puertos" ]] && puertos="Ninguno"
  tipo=$(classify "$ip" "$vendor" "$os" "$puertos")
  printf "%-15s | %-30s | %-15s | %-20s | %-12s\n" "$ip" "$vendor" "$os" "$puertos" "$tipo"

done <<< "$HOSTS"

exit 0
