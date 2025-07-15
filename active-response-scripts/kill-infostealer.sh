#!/bin/bash
# kill-infostealer.sh - Mata processos Python maliciosos relacionados ao infostealer

LOG_FILE="/var/ossec/logs/active-responses.log"
PID_FILE="/tmp/wazuh-kill-infostealer.pid"

# Função de log
log_message() {
    echo "$(date '+%Y/%m/%d %H:%M:%S') kill-infostealer: $1" >> "$LOG_FILE"
}

# Verifica se já está executando
if [ -f "$PID_FILE" ]; then
    log_message "Script já está em execução (PID: $(cat $PID_FILE))"
    exit 1
fi

# Cria arquivo PID
echo $$ > "$PID_FILE"

log_message "Iniciando busca por processos Python maliciosos..."

# Buscar processos Python suspeitos por comportamento
MALICIOUS_PIDS=$(ps aux | grep -E "python.*" | grep -v grep | while read line; do
    PID=$(echo "$line" | awk '{print $2}')
    CMD=$(echo "$line" | awk '{for(i=11;i<=NF;i++) printf "%s ", $i}')
    
    # Verificar se o processo está fazendo conexões de rede suspeitas
    if netstat -tnp 2>/dev/null | grep -q "$PID"; then
        # Verificar se está acessando arquivos sensíveis
        if lsof -p "$PID" 2>/dev/null | grep -qE "(\.ssh|\.gnupg|Documents|Downloads|Desktop)"; then
            echo "$PID"
        fi
    fi
    
    # Verificar se o processo Python está tentando se persistir
    if lsof -p "$PID" 2>/dev/null | grep -qE "(\.config/systemd|\.bashrc|\.profile|crontab)"; then
        echo "$PID"
    fi
    
    # Verificar processos Python executando de locais suspeitos
    if echo "$CMD" | grep -qE "(/tmp/|/var/tmp/|/dev/shm/).*\.py"; then
        echo "$PID"
    fi
done | sort -u)

if [ -z "$MALICIOUS_PIDS" ]; then
    log_message "Nenhum processo Python malicioso encontrado"
else
    log_message "Processos maliciosos encontrados: $MALICIOUS_PIDS"
    
    for PID in $MALICIOUS_PIDS; do
        # Verificar se o processo ainda existe
        if kill -0 "$PID" 2>/dev/null; then
            # Tentar SIGTERM primeiro
            log_message "Enviando SIGTERM para PID $PID"
            kill -TERM "$PID" 2>/dev/null
            sleep 2
            
            # Se ainda estiver rodando, usar SIGKILL
            if kill -0 "$PID" 2>/dev/null; then
                log_message "Processo $PID ainda ativo, enviando SIGKILL"
                kill -KILL "$PID" 2>/dev/null
                sleep 1
            fi
            
            # Verificar se foi morto
            if ! kill -0 "$PID" 2>/dev/null; then
                log_message "Processo $PID terminado com sucesso"
            else
                log_message "ERRO: Falha ao terminar processo $PID"
            fi
        else
            log_message "Processo $PID já estava morto"
        fi
    done
fi

# Remover arquivo PID
rm -f "$PID_FILE"

log_message "Script kill-infostealer finalizado"
exit 0
