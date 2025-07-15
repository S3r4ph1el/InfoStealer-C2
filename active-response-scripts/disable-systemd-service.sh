#!/bin/bash
# disable-systemd-service.sh - Desabilita serviços systemd suspeitos

LOG_FILE="/var/ossec/logs/active-responses.log"
PID_FILE="/tmp/wazuh-disable-systemd.pid"

# Função de log
log_message() {
    echo "$(date '+%Y/%m/%d %H:%M:%S') disable-systemd-service: $1" >> "$LOG_FILE"
}

# Verifica se já está executando
if [ -f "$PID_FILE" ]; then
    log_message "Script já está em execução (PID: $(cat $PID_FILE))"
    exit 1
fi

# Cria arquivo PID
echo $$ > "$PID_FILE"

log_message "Iniciando busca por serviços systemd suspeitos..."

# Buscar serviços suspeitos em user space
for USER_HOME in /home/*; do
    USERNAME=$(basename "$USER_HOME")
    
    # Verificar se é um usuário válido
    if [ ! -d "$USER_HOME" ] || [ "$USERNAME" = "*" ]; then
        continue
    fi
    
    SYSTEMD_DIR="$USER_HOME/.config/systemd/user"
    
    if [ -d "$SYSTEMD_DIR" ]; then
        # Buscar por serviços suspeitos por comportamento
        SUSPICIOUS_SERVICES=$(
            find "$SYSTEMD_DIR" -name "*.service" -type f 2>/dev/null | while read service_file; do
                # Verificar se o serviço executa Python de locais suspeitos
                if grep -qE "ExecStart=.*python.*(/tmp/|/var/tmp/|/dev/shm/)" "$service_file" 2>/dev/null; then
                    echo "$service_file"
                    continue
                fi
                
                # Verificar se o serviço não tem descrição adequada ou usa caminhos suspeitos
                if ! grep -q "^Description=" "$service_file" 2>/dev/null && 
                   grep -qE "ExecStart=.*\.py" "$service_file" 2>/dev/null; then
                    echo "$service_file"
                    continue
                fi
                
                # Verificar se o serviço tenta se executar muito frequentemente
                if grep -qE "Restart=always|RestartSec=[0-5]" "$service_file" 2>/dev/null; then
                    echo "$service_file"
                    continue
                fi
                
                # Verificar serviços que executam de diretórios ocultos
                if grep -qE "ExecStart=.*/\." "$service_file" 2>/dev/null; then
                    echo "$service_file"
                fi
            done
        )
        
        if [ -n "$SUSPICIOUS_SERVICES" ]; then
            log_message "Serviços suspeitos encontrados para usuário $USERNAME: $SUSPICIOUS_SERVICES"
            
            for SERVICE_FILE in $SUSPICIOUS_SERVICES; do
                SERVICE_NAME=$(basename "$SERVICE_FILE")
                
                log_message "Processando serviço suspeito: $SERVICE_NAME"
                
                # Parar o serviço
                sudo -u "$USERNAME" systemctl --user stop "$SERVICE_NAME" 2>/dev/null
                if [ $? -eq 0 ]; then
                    log_message "Serviço $SERVICE_NAME parado com sucesso"
                else
                    log_message "Falha ao parar serviço $SERVICE_NAME"
                fi
                
                # Desabilitar o serviço
                sudo -u "$USERNAME" systemctl --user disable "$SERVICE_NAME" 2>/dev/null
                if [ $? -eq 0 ]; then
                    log_message "Serviço $SERVICE_NAME desabilitado com sucesso"
                else
                    log_message "Falha ao desabilitar serviço $SERVICE_NAME"
                fi
                
                # Mover arquivo para quarentena
                QUARANTINE_DIR="/var/ossec/quarantine"
                mkdir -p "$QUARANTINE_DIR"
                
                QUARANTINE_FILE="$QUARANTINE_DIR/$(basename "$SERVICE_FILE").$(date +%s)"
                mv "$SERVICE_FILE" "$QUARANTINE_FILE" 2>/dev/null
                
                if [ $? -eq 0 ]; then
                    log_message "Arquivo de serviço movido para quarentena: $QUARANTINE_FILE"
                else
                    log_message "Falha ao mover arquivo para quarentena"
                fi
                
                # Recarregar daemon
                sudo -u "$USERNAME" systemctl --user daemon-reload 2>/dev/null
            done
        else
            log_message "Nenhum serviço suspeito encontrado para usuário $USERNAME"
        fi
    fi
done

# Remover arquivo PID
rm -f "$PID_FILE"

log_message "Script disable-systemd-service finalizado"
exit 0
