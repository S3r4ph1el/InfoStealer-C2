#!/bin/bash
# watch-suspicious-ips.sh - Monitora conexões suspeitas e comportamentos anômalos

LOG_FILE="/var/ossec/logs/active-responses.log"
PID_FILE="/tmp/wazuh-watch-suspicious.pid"

# Função de log
log_message() {
    echo "$(date '+%Y/%m/%d %H:%M:%S') watch-suspicious-ips: $1" >> "$LOG_FILE"
}

# Verifica se já está executando
if [ -f "$PID_FILE" ]; then
    log_message "Script já está em execução (PID: $(cat $PID_FILE))"
    exit 1
fi

# Cria arquivo PID
echo $$ > "$PID_FILE"

log_message "Iniciando monitoramento de IPs e comportamentos suspeitos..."

# Detectar conexões a IPs com alta frequência (possível C2)
HIGH_FREQ_IPS=$(netstat -tn | grep ESTABLISHED | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -nr | awk '$1 > 5 {print $2}')

for IP in $HIGH_FREQ_IPS; do
    # Ignorar IPs privados
    if echo "$IP" | grep -qE "^(127\.|10\.|172\.1[6-9]\.|172\.2[0-9]\.|172\.3[0-1]\.|192\.168\.)"; then
        continue
    fi
    
    # Verificar se há processos Python conectados
    PYTHON_PROCS=$(lsof -i | grep "$IP" | grep python | awk '{print $2}' | sort -u)
    
    for PID in $PYTHON_PROCS; do
        if [ -n "$PID" ] && [ "$PID" != "PID" ]; then
            # Verificar comportamentos suspeitos do processo
            PROCESS_CMD=$(ps -p "$PID" -o cmd= 2>/dev/null)
            PROCESS_CWD=$(readlink -f "/proc/$PID/cwd" 2>/dev/null)
            
            SUSPICIOUS=0
            
            # Processo executando de diretório temporário
            if echo "$PROCESS_CWD" | grep -qE "(tmp|var/tmp|dev/shm)"; then
                log_message "SUSPEITO: Processo Python PID:$PID executando de diretório temporário: $PROCESS_CWD"
                SUSPICIOUS=1
            fi
            
            # Processo sem path completo (possivelmente ofuscado)
            if ! echo "$PROCESS_CMD" | grep -q "^/"; then
                log_message "SUSPEITO: Processo Python PID:$PID sem path absoluto: $PROCESS_CMD"
                SUSPICIOUS=1
            fi
            
            # Verificar se está acessando arquivos sensíveis
            SENSITIVE_FILES=$(lsof -p "$PID" 2>/dev/null | grep -E "(\.ssh|\.gnupg|Documents|Downloads|Desktop|\.config)" | wc -l)
            if [ "$SENSITIVE_FILES" -gt 3 ]; then
                log_message "SUSPEITO: Processo Python PID:$PID acessando muitos arquivos sensíveis ($SENSITIVE_FILES)"
                SUSPICIOUS=1
            fi
            
            # Verificar conexões de rede frequentes
            NET_CONNECTIONS=$(lsof -p "$PID" 2>/dev/null | grep -E "TCP.*ESTABLISHED" | wc -l)
            if [ "$NET_CONNECTIONS" -gt 2 ]; then
                log_message "SUSPEITO: Processo Python PID:$PID com muitas conexões ativas ($NET_CONNECTIONS)"
                SUSPICIOUS=1
            fi
            
            if [ "$SUSPICIOUS" -eq 1 ]; then
                log_message "ALERTA: Processo Python suspeito detectado - PID:$PID, IP:$IP, CMD:$PROCESS_CMD"
                
                # Adicionar IP à lista de bloqueio
                if ! grep -q "$IP" /var/ossec/etc/lists/blocked_c2_ips 2>/dev/null; then
                    echo "$IP" >> /var/ossec/etc/lists/blocked_c2_ips
                    log_message "IP $IP adicionado à lista de IPs bloqueados"
                fi
                
                # Bloquear IP se possível
                iptables -I OUTPUT -d "$IP" -j DROP 2>/dev/null && \
                    log_message "IP $IP bloqueado via iptables"
            fi
        fi
    done
done

# Detectar novos arquivos Python em locais suspeitos
NEW_PYTHON_FILES=$(find /tmp /var/tmp /dev/shm -name "*.py" -mmin -5 -type f 2>/dev/null)

for FILE in $NEW_PYTHON_FILES; do
    log_message "ALERTA: Novo arquivo Python criado em local suspeito: $FILE"
    
    # Verificar conteúdo do arquivo
    if grep -qE "(http|socket|base64|encrypt|collect)" "$FILE" 2>/dev/null; then
        log_message "CRÍTICO: Arquivo Python suspeito com padrões de malware: $FILE"
        
        # Remover permissões de execução
        chmod 000 "$FILE" 2>/dev/null
        log_message "Permissões de execução removidas de $FILE"
    fi
done

# Detectar processos Python executando de stdin ou pipes (técnica de evasão)
STDIN_PYTHON=$(ps aux | grep -E "python.*-c|python.*-" | grep -v grep)

if [ -n "$STDIN_PYTHON" ]; then
    log_message "ALERTA: Processos Python executando comandos diretos ou de stdin detectados:"
    echo "$STDIN_PYTHON" | while read line; do
        PID=$(echo "$line" | awk '{print $2}')
        log_message "  PID:$PID - $line"
    done
fi

# Remover arquivo PID
rm -f "$PID_FILE"

log_message "Monitoramento de comportamentos suspeitos finalizado"
exit 0
                    fi
                fi
            fi
        fi
    fi
done < /var/log/audit/audit.log
