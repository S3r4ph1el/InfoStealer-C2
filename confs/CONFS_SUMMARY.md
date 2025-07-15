# Wazuh Configuration Files Summary

## 📁 **Configurações do Projeto InfoStealer-C2**

### 🔧 **wazuh-manager-conf.txt** - Configuração do Manager

#### **Global Settings**
- **Output**: JSON habilitado para alertas
- **Email**: Desabilitado (ambiente de laboratório)
- **Agents**: Desconexão permitida por 10 minutos
- **Whitelist**: Proteção para localhost (127.0.0.1, localhost.localdomain, 127.0.0.53)

#### **Alertas e Logs**
- **Nível de Alerta**: 3 (INFO e acima)
- **Email Alert**: 12 (praticamente desabilitado)
- **Log Format**: Plain text
- **Logs Monitorados**:
  - `journald` (sistema)
  - `/var/ossec/logs/active-responses.log`
  - `/var/log/auth.log` (autenticação)
  - `/var/log/syslog` (sistema geral)

#### **Conexões**
- **Remote**: Porta 1514, protocolo TCP seguro
- **Auth**: Porta 1515, SSL/TLS habilitado
- **Queue Size**: 131072 eventos

#### **Monitoramento (Syscheck)**
- **Frequência**: A cada 12 horas (43200s)
- **Scan Inicial**: Habilitado
- **Novos Arquivos**: Alertas habilitados
- **Diretórios Monitorados**:
  - `/etc`, `/usr/bin`, `/usr/sbin`
  - `/bin`, `/sbin`, `/boot`
  - `/home`, `/tmp`, `/var/tmp`
- **Arquivos Sensíveis** (sem diff):
  - `/etc/ssl/private.key`
  - `/etc/shadow`, `/etc/passwd`

#### **Rootcheck**
- **Frequência**: A cada 12 horas
- **Verificações**: Arquivos, trojans, dispositivos, sistema, PIDs, portas
- **Ignora**: Diretórios de containers Docker

#### **Componentes Desabilitados (Lab)**
- **Indexer**: Desabilitado
- **Cluster**: Desabilitado (nó único)
- **Rule Testing**: Desabilitado

#### **Active Response Commands**
```
kill-infostealer.sh        → Mata processos Python maliciosos
disable-systemd-service.sh → Desabilita serviços systemd suspeitos  
block-c2-connection.sh     → Bloqueia conexões C2
quarantine-file.sh         → Isola arquivos maliciosos
```

#### **Active Response Rules**
- **Rule 100301,100302** → `block-c2-connection` (timeout: 600s)
- **Rule 100303** → `quarantine-file` (timeout: 30s)
- **Rule 100304** → `disable-systemd-service` (timeout: 60s)
- **Rule 100307** → `kill-infostealer` (timeout: 300s)

#### **Ruleset**
- **Default**: Decoders e rules padrão do Wazuh
- **Custom**: Decoders e rules personalizados em `/etc/decoders` e `/etc/rules`
- **Lists**: audit-keys, aws-eventnames, security-eventchannel

---

### 🔧 **wazuh-agent-conf.txt** (Presumível)
*Configuração para agentes em VMs protegidas*

#### **Funcionalidades Esperadas**:
- **Conexão**: Apontar para Wazuh Manager
- **Syscheck**: Monitoramento local de arquivos
- **Localfile**: Configuração para logs de auditd
- **Rootcheck**: Verificação de rootkits local

---

### 📋 **local_rules.xml** 
*Regras customizadas para detecção de InfoStealers*

#### **Rules IDs Personalizados**:
- **100301**: Detecção de conexão C2
- **100302**: Padrão de comunicação suspeita
- **100303**: Arquivo malicioso detectado
- **100304**: Serviço systemd suspeito
- **100307**: Processo Python malicioso

---

### 📝 **Lists de Correlação**

#### **blocked_c2_ips.txt**
- Lista de IPs de servidores C2 conhecidos
- Utilizada para correlação em regras

#### **trusted_ips.txt**
- Lista de IPs confiáveis
- Whitelist para zero trust

---

### 🔍 **infostealer.rules** (Auditd)
*Regras de auditoria para captura de eventos*

#### **Eventos Monitorados**:
- Execução de arquivos Python
- Acesso a arquivos sensíveis
- Conexões de rede
- Modificações em arquivos de configuração
- Criação de serviços systemd

---

## 🎯 **Estratégia Geral de Configuração**

### **Otimizada para Lab**
- Performance sobre recursos desnecessários
- Foco na detecção de InfoStealers
- Configuração simplificada

### **Detecção Comportamental**
- Não depende de nomes específicos de malware
- Análise de padrões suspeitos
- Múltiplos indicadores combinados

### **Resposta Automatizada**
- Bloqueio imediato de conexões C2
- Isolamento de arquivos maliciosos
- Terminação de processos suspeitos
- Desabilitação de persistência

### **Logging Centralizado**
- Todos os eventos em `/var/ossec/logs/`
- Correlação entre diferentes fontes
- Análise forense facilitada

## 🛡️ **Fluxo de Detecção**
1. **Auditd** captura eventos do sistema
2. **Wazuh Agent** envia para Manager
3. **Rules** analisam e correlacionam eventos
4. **Active Response** executa ações automatizadas
5. **Logs** registram todas as atividades
