#!/bin/bash
# quarantine-file.sh - Move arquivos maliciosos para quarentena

LOG_FILE="/var/ossec/logs/active-responses.log"
PID_FILE="/tmp/wazuh-quarantine.pid"
QUARANTINE_DIR="/var/ossec/quarantine"

# Função de log
log_message() {
    echo "$(date '+%Y/%m/%d %H:%M:%S') quarantine-file: $1" >> "$LOG_FILE"
}

# Verifica se já está executando
if [ -f "$PID_FILE" ]; then
    log_message "Script já está em execução (PID: $(cat $PID_FILE))"
    exit 1
fi

# Cria arquivo PID
echo $$ > "$PID_FILE"

# Criar diretório de quarentena se não existir
mkdir -p "$QUARANTINE_DIR"

log_message "Iniciando busca por arquivos maliciosos..."

# Buscar arquivos Python suspeitos por comportamento e localização
SUSPICIOUS_FILES=$(
    # Arquivos Python em locais temporários
    find /tmp /var/tmp /dev/shm -name "*.py" -type f 2>/dev/null
    
    # Arquivos Python recentemente modificados em diretórios de usuário que fazem conexões de rede
    find /home -name "*.py" -type f -mtime -1 -exec grep -l "socket\|http\|requests\|urllib" {} \; 2>/dev/null
    
    # Arquivos executáveis Python em locais incomuns
    find /home -name "*.py" -type f -executable ! -path "*/.*venv/*" ! -path "*/.*git/*" 2>/dev/null | while read file; do
        if grep -qE "(collect.*file|send.*data|base64|encrypt)" "$file" 2>/dev/null; then
            echo "$file"
        fi
    done
)

if [ -n "$SUSPICIOUS_FILES" ]; then
    log_message "Arquivos suspeitos encontrados: $SUSPICIOUS_FILES"
    
    for FILE in $SUSPICIOUS_FILES; do
        if [ -f "$FILE" ]; then
            # Criar nome único para quarentena
            TIMESTAMP=$(date +%s)
            QUARANTINE_FILE="$QUARANTINE_DIR/$(basename "$FILE").$TIMESTAMP"
            
            # Verificar se o arquivo está sendo executado
            if lsof "$FILE" >/dev/null 2>&1; then
                log_message "Arquivo $FILE está sendo usado, tentando matar processos"
                
                # Matar processos que estão usando o arquivo
                PIDS=$(lsof -t "$FILE" 2>/dev/null)
                for PID in $PIDS; do
                    if kill -0 "$PID" 2>/dev/null; then
                        kill -KILL "$PID" 2>/dev/null
                        log_message "Processo $PID que usava $FILE foi terminado"
                    fi
                done
                
                sleep 1
            fi
            
            # Mover para quarentena
            if mv "$FILE" "$QUARANTINE_FILE" 2>/dev/null; then
                log_message "Arquivo $FILE movido para quarentena: $QUARANTINE_FILE"
                
                # Registrar hash do arquivo para análise posterior
                if command -v sha256sum >/dev/null; then
                    HASH=$(sha256sum "$QUARANTINE_FILE" | cut -d' ' -f1)
                    echo "$(date '+%Y-%m-%d %H:%M:%S') $FILE $HASH" >> "$QUARANTINE_DIR/quarantine.log"
                    log_message "Hash SHA256 do arquivo: $HASH"
                fi
                
                # Remover permissões de execução
                chmod 000 "$QUARANTINE_FILE"
                
            else
                log_message "ERRO: Falha ao mover arquivo $FILE para quarentena"
            fi
        fi
    done
else
    log_message "Nenhum arquivo malicioso encontrado"
fi

# Buscar e quarentenar arquivos baixados recentemente suspeitos
RECENT_SUSPICIOUS=$(
    # Arquivos Python criados nas últimas 24 horas com padrões suspeitos
    find /tmp /var/tmp /home -name "*.py" -mtime -1 -type f 2>/dev/null | while read file; do
        if grep -qE "(http\.client|requests|socket|base64\.b64encode|os\.system|subprocess|persistence)" "$file" 2>/dev/null; then
            # Verificar se não é um arquivo legítimo (bibliotecas conhecidas)
            if ! grep -qE "(#!/usr/bin/python|# -*- coding:|from __future__|import sys)" "$file" 2>/dev/null || 
               grep -qE "(collect.*files|send.*data|systemd.*user|\.ssh|\.gnupg)" "$file" 2>/dev/null; then
                echo "$file"
            fi
        fi
    done
    
    # Arquivos executáveis recentes que não deveriam estar em certas localizações
    find /home -type f -executable -mtime -1 ! -path "*/bin/*" ! -path "*/.local/bin/*" 2>/dev/null | while read file; do
        if file "$file" | grep -qE "(Python script|text executable)"; then
            echo "$file"
        fi
    done
)

if [ -n "$RECENT_SUSPICIOUS" ]; then
    log_message "Arquivos Python recentes suspeitos: $RECENT_SUSPICIOUS"
    
    for FILE in $RECENT_SUSPICIOUS; do
        # Verificar se contém padrões de infostealer mais genéricos
        if grep -qE "(collect.*file|send.*data|base64.*encode|systemd.*user|\.ssh|\.gnupg|Documents.*zip)" "$FILE" 2>/dev/null; then
            TIMESTAMP=$(date +%s)
            QUARANTINE_FILE="$QUARANTINE_DIR/suspicious_$(basename "$FILE").$TIMESTAMP"
            
            cp "$FILE" "$QUARANTINE_FILE" 2>/dev/null
            if [ $? -eq 0 ]; then
                log_message "Arquivo suspeito copiado para quarentena: $QUARANTINE_FILE"
                chmod 000 "$QUARANTINE_FILE"
            fi
        fi
    done
fi

# Limpar quarentena antiga (arquivos com mais de 30 dias)
find "$QUARANTINE_DIR" -type f -mtime +30 -delete 2>/dev/null
log_message "Limpeza de arquivos antigos da quarentena realizada"

# Remover arquivo PID
rm -f "$PID_FILE"

log_message "Script quarantine-file finalizado"
exit 0
