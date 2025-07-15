# Active Response Scripts - Functional Overview

## 🛡️ Scripts de Resposta Ativa para Detecção de InfoStealers

### 1. **kill-infostealer.sh**
**Função**: Identifica e termina processos Python maliciosos
**Como detecta**:
- Processos Python fazendo conexões de rede + acessando arquivos sensíveis
- Processos executando de diretórios temporários (`/tmp`, `/var/tmp`, `/dev/shm`)
- Processos tentando modificar arquivos de persistência (systemd, bashrc)
**Ação**: Mata processos com SIGTERM, depois SIGKILL se necessário

### 2. **quarantine-file.sh**
**Função**: Localiza e isola arquivos Python suspeitos
**Como detecta**:
- Arquivos Python em locais temporários
- Arquivos com padrões de código malicioso (`socket`, `http`, `base64`, `encrypt`)
- Arquivos executáveis recentes em locais incomuns
- Scripts com capacidades de rede e acesso a dados sensíveis
**Ação**: Move arquivos para `/var/ossec/quarantine` e remove permissões

### 3. **disable-systemd-service.sh**
**Função**: Desabilita serviços systemd maliciosos de usuário
**Como detecta**:
- Serviços executando Python de diretórios temporários
- Serviços sem descrição adequada
- Configurações de restart excessivamente frequentes
- Serviços executando de diretórios ocultos
**Ação**: Para, desabilita e move arquivos de serviço para quarentena

### 4. **block-c2-connection.sh**
**Função**: Bloqueia conexões a servidores C2 suspeitos
**Como detecta**:
- Processos Python conectados a IPs externos
- Processos executando de locais temporários com conexões ativas
- Validação de legitimidade do path do processo
**Ação**: Bloqueia IPs via iptables e adiciona à lista de IPs bloqueados

### 5. **watch-suspicious-ips.sh**
**Função**: Monitora comportamentos suspeitos em tempo real
**Como detecta**:
- IPs com alta frequência de conexões
- Processos Python sem path absoluto (possivelmente ofuscados)
- Acesso excessivo a arquivos sensíveis (`.ssh`, `.gnupg`, `Documents`)
- Múltiplas conexões TCP ativas de um único processo
- Novos arquivos Python criados em locais suspeitos
- Processos executando via stdin/pipes (técnica de evasão)
**Ação**: Registra alertas, bloqueia IPs e remove permissões de arquivos suspeitos

## 🎯 **Estratégia de Detecção**

### **Indicadores Primários**
- **Localização**: `/tmp/`, `/var/tmp/`, `/dev/shm/`
- **Rede**: Conexões a IPs externos não privados
- **Acesso**: Arquivos sensíveis (`.ssh/`, `Documents/`, `.config/`)
- **Persistência**: Modificação de systemd, bashrc, crontab

### **Padrões Comportamentais**
- Combinação de capacidades de rede + acesso a dados
- Execução de locais temporários + conexões externas
- Alta frequência de atividade de rede
- Tentativas de ocultação ou evasão

### **Técnicas de Evasão Detectadas**
- Renomeação de arquivos/processos
- Execução via `python -c`
- Uso de stdin/pipes
- Processos sem path absoluto
- Ocultação em diretórios temporários

## ⚡ **Fluxo de Resposta**
1. **Detecção** → Análise comportamental em tempo real
2. **Classificação** → Combinação de múltiplos indicadores
3. **Ação** → Bloqueio/quarentena/terminação conforme severidade
4. **Log** → Registro detalhado para análise forense
