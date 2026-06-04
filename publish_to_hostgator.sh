#!/bin/bash

# Faz o script parar se qualquer comando falhar
set -e

# Script para publicar o pacote de deploy via SSH (HostGator)
# Requisito: ter o 'ssh' e 'scp' instalados. 
# Recomendado: ter o 'sshpass' se for usar senha do .env (sudo apt install sshpass)

# Carregar variáveis do .env se existir
if [ -f .env ]; then
    # Usando export para que subcomandos possam ver as variáveis
    export $(grep -v '^#' .env | xargs)
fi

# Configurações
HOST=${FTP_HOST:-"seu_host_ou_ip"}
USER=${FTP_USER:-"adri7808"}
PASS=${FTP_PASS:-"sua_senha_aqui"}
PORT=${SSH_PORT:-22} # HostGator as vezes usa 2222

# Caminhos remotos (relativos ao home do usuário)
REMOTE_CORE="php_template"
REMOTE_PUBLIC="public_html/php_template"

# Verificar se pacotes existem
if [ ! -d "./deploy_package/php_template_core" ] || [ ! -d "./deploy_package/php_template_public" ]; then
    echo "❌ Erro: Pacote de deploy não encontrado! Execute ./generate_deploy_package.sh primeiro."
    exit 1
fi

echo "📦 Compactando arquivos localmente..."
tar -czf core.tar.gz -C ./deploy_package/php_template_core .
tar -czf public.tar.gz -C ./deploy_package/php_template_public .

# Função para executar comandos via SSH (com ou sem sshpass)
run_ssh() {
    if command -v sshpass >/dev/null 2>&1 && [ ! -z "$PASS" ]; then
        sshpass -p "$PASS" ssh -p $PORT -o StrictHostKeyChecking=no "$USER@$HOST" "$1"
    else
        ssh -p $PORT "$USER@$HOST" "$1"
    fi
}

# Função para enviar via SCP (com ou sem sshpass)
run_scp() {
    if command -v sshpass >/dev/null 2>&1 && [ ! -z "$PASS" ]; then
        sshpass -p "$PASS" scp -P $PORT -o StrictHostKeyChecking=no "$1" "$USER@$HOST:$2"
    else
        scp -P $PORT "$1" "$USER@$HOST:$2"
    fi
}

echo "🚀 Enviando arquivos compactados para $HOST..."
run_scp "core.tar.gz" "~/"
run_scp "public.tar.gz" "~/"

echo "🔄 Iniciando descompactação e swap no destino..."

# Comandos remotos para processar ambos os pacotes
REMOTE_COMMANDS="
set -e

deploy_step() {
    local target=\$1
    local archive=\$2
    local archive_path=\"\$HOME/\$archive\"
    
    echo \"  🔹 Processando \$target...\"
    
    # 1. Limpar pasta .old anterior se existir
    rm -rf \"\${target}.old\"
    
    # 2. Criar pasta .tmp e descompactar
    mkdir -p \"\${target}.tmp\"
    tar -xzf \"\$archive_path\" -C \"\${target}.tmp\"
    
    # 3. Swap: renomear atual para .old e .tmp para real
    if [ -d \"\$target\" ]; then
        mv \"\$target\" \"\${target}.old\"
    fi
    mv \"\${target}.tmp\" \"\$target\"
    
    # 4. Limpar arquivo enviado
    rm \"\$archive_path\"
}

deploy_step \"$REMOTE_CORE\" \"core.tar.gz\"
deploy_step \"$REMOTE_PUBLIC\" \"public.tar.gz\"
"

run_ssh "$REMOTE_COMMANDS"

echo "🧹 Limpando arquivos temporários locais..."
rm core.tar.gz public.tar.gz

echo "✅ Deploy realizado com sucesso e de forma atômica!"