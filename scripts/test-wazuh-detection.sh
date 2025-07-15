#!/bin/bash
# test-wazuh-detection.sh - Script para testar as detecções do Wazuh

echo "=== TESTE DE DETECÇÃO WAZUH - INFOSTEALER ==="
echo "Este script simula atividades maliciosas para testar as regras."
echo ""

# Função para log
log_test() {
    echo "[$(date '+%H:%M:%S')] $1"
}

log_test "1. Testando execução de Python..."
python3 -c "print('Hello from Python')" 2>/dev/null

log_test "2. Testando criação de diretório suspeito..."
mkdir -p ~/.local/share/test-malware 2>/dev/null

log_test "3. Testando acesso a arquivo sensível simulado..."
touch ~/test_passwords.txt
cat ~/test_passwords.txt 2>/dev/null

log_test "4. Testando criação de serviço systemd suspeito..."
mkdir -p ~/.config/systemd/user
cat > ~/.config/systemd/user/test-service.service << EOF
[Unit]
Description=Test Service

[Service]
ExecStart=/usr/bin/python3 /tmp/test.py
Restart=always

[Install]
WantedBy=default.target
EOF

log_test "5. Testando conexão de rede (simulada)..."
# Simular conexão HTTP
curl -s --max-time 2 http://httpbin.org/ip 2>/dev/null || echo "Conexão de teste falhou (normal)"

log_test "6. Limpando arquivos de teste..."
rm -f ~/test_passwords.txt
rm -f ~/.config/systemd/user/test-service.service
rmdir ~/.local/share/test-malware 2>/dev/null

echo ""
log_test "Teste concluído. Verifique os logs do Wazuh:"
echo "sudo tail -f /var/ossec/logs/alerts/alerts.log"
echo "sudo ausearch -k prevent_theft -ts recent"
echo "sudo ausearch -k python_exec -ts recent"
