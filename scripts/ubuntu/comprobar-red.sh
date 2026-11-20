#!/usr/bin/env bash
# Prueba desde la propia VM contra su IP NO loopback: lo que veria otro equipo de la red.
IP=$(hostname -I | awk '{print $1}')
echo "IP de la VM (interfaz NAT): $IP"
for p in 22 80 8081 3306; do
  if timeout 3 bash -c "</dev/tcp/$IP/$p" 2>/dev/null; then echo "puerto $p: ABIERTO"; else echo "puerto $p: cerrado"; fi
done
echo "--- escuchando (ss):"; ss -ltnH | awk '{print $4}' | sort -u | tr '\n' ' '; echo
echo "--- MariaDB solo loopback: $(docker port tiendalab-db-1 2>/dev/null)"
echo "--- UFW:"; ufw status | sed -n '1,10p'