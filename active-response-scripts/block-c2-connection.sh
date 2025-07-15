#!/bin/bash
# block-c2-connection.sh - Bloqueia conexões para servidores C2 suspeitos

LOG_FILE="/var/ossec/logs/active-responses.log"
PID_FILE="/tmp/wazuh-block-c2.pid"

# Função de log
log_message() {
    echo "$(date '+%Y/%m/%d %H:%M:%S') block-c2-connection: $1" >> "$LOG_FILE"
}

# Verifica se já está executando
if [ -f "$PID_FILE" ]; then
    log_message "Script já está em execução (PID: $(cat $PID_FILE))"
    exit 1
fi

# Cria arquivo PID
echo $$ > "$PID_FILE"

log_message "Iniciando bloqueio de conexões C2..."

# Extrair IP suspeito do alerta (se disponível via variáveis de ambiente do Wazuh)
SUSPICIOUS_IP=""

# Extrair IP suspeito de conexões ativas em tempo real
SUSPICIOUS_CONNECTIONS=$(netstat -tn | grep ESTABLISHED | awk '{print $5}' | cut -d: -f1 | sort -u)

if [ -n "$SUSPICIOUS_CONNECTIONS" ]; then
    for IP in $SUSPICIOUS_CONNECTIONS; do
        # Verificar se é IP externo (não privado) 
        if ! echo "$IP" | grep -qE "^(127\.|10\.|172\.1[6-9]\.|172\.2[0-9]\.|172\.3[0-1]\.|192\.168\.)"; then
            
            # Verificar se há processo Python suspeito conectado a este IP
            PYTHON_PROCESSES=$(lsof -i | grep "$IP" | grep python)
            
            if [ -n "$PYTHON_PROCESSES" ]; then
                # Verificar se o processo Python não é legítimo
                PID=$(echo "$PYTHON_PROCESSES" | awk '{print $2}' | head -1)
                PROCESS_PATH=$(readlink -f "/proc/$PID/exe" 2>/dev/null)
                
                # Considerar suspeito se executa de locais temporários ou não tem path legítimo
                if echo "$PROCESS_PATH" | grep -qE "(tmp|var/tmp|dev/shm)" || [ ! -f "$PROCESS_PATH" ]; then
                    SUSPICIOUS_IP="$IP"
                    log_message "IP C2 suspeito detectado: $SUSPICIOUS_IP (processo Python PID:$PID em local suspeito)"
                
                # Bloquear com iptables
                iptables -I OUTPUT -d "$SUSPICIOUS_IP" -j DROP 2>/dev/null
                if [ $? -eq 0 ]; then
                    log_message "IP $SUSPICIOUS_IP bloqueado via iptables OUTPUT"
                    
                    # Adicionar à lista permanente de IPs bloqueados
                    echo "$SUSPICIOUS_IP" >> /var/ossec/etc/lists/blocked_c2_ips
                    log_message "IP $SUSPICIOUS_IP adicionado à lista permanente de bloqueio"
                else
                    log_message "Falha ao bloquear IP $SUSPICIOUS_IP via iptables"
                fi
                
                # Matar conexões ativas para este IP
                ss -K dst "$SUSPICIOUS_IP" 2>/dev/null
                log_message "Conexões ativas para $SUSPICIOUS_IP terminadas"
            fi
        fi
    done
else
    log_message "Nenhuma conexão suspeita ativa encontrada"
fi

# Bloquear portas comumente usadas por C2
C2_PORTS="80 443 8080 8443 9999"
for PORT in $C2_PORTS; do
    # Verificar se há processos Python conectando nesta porta
    PYTHON_CONNECTIONS=$(lsof -i :$PORT | grep python)
    
    if [ -n "$PYTHON_CONNECTIONS" ]; then
        log_message "Conexão Python suspeita na porta $PORT detectada"
        
        # Extrair PID e matar processo
        PIDS=$(echo "$PYTHON_CONNECTIONS" | awk '{print $2}' | sort -u)
        for PID in $PIDS; do
            if kill -0 "$PID" 2>/dev/null; then
                kill -KILL "$PID" 2>/dev/null
                log_message "Processo Python suspeito (PID: $PID) na porta $PORT terminado"
            fi
        done
    fi
done

# Criar regra de bloqueio para IPs previamente identificados como maliciosos
if [ -f "/var/ossec/etc/lists/blocked_c2_ips" ]; then
    while read -r BLOCKED_IP; do
        # Ignorar comentários e linhas vazias
        if [ -n "$BLOCKED_IP" ] && [ "${BLOCKED_IP:0:1}" != "#" ] && [[ "$BLOCKED_IP" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
            # Verificar se a regra já existe antes de adicionar
            if ! iptables -C OUTPUT -d "$BLOCKED_IP" -j DROP 2>/dev/null; then
                iptables -I OUTPUT -d "$BLOCKED_IP" -j DROP 2>/dev/null
                log_message "IP C2 previamente identificado $BLOCKED_IP bloqueado"
            fi
        fi
    done < /var/ossec/etc/lists/blocked_c2_ips
fi

# Remover arquivo PID
rm -f "$PID_FILE"

log_message "Script block-c2-connection finalizado"
exit 0
