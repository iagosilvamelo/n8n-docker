#!/bin/bash
set -e

# -------------------------------------------------------
#     CRIAÇÃO DO USUÁRIO E BANCO DE DADOS DO CHATWOOT    
# -------------------------------------------------------
echo "Verificando usuário do Chatwoot: $CHATWOOT_POSTGRES_USER"
# Verifica se o usuário já existe
if ! psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -tAc "SELECT 1 FROM pg_roles WHERE rolname='$CHATWOOT_POSTGRES_USER'" | grep -q 1; then
    psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "CREATE USER $CHATWOOT_POSTGRES_USER WITH PASSWORD '$CHATWOOT_POSTGRES_PASSWORD';"
    echo "Usuário $CHATWOOT_POSTGRES_USER criado."
else
    echo "Usuário $CHATWOOT_POSTGRES_USER já existe."
fi

echo "Verificando banco de dados do Chatwoot: $CHATWOOT_POSTGRES_DB"
# Verifica se o banco de dados já existe
if ! psql -U "$POSTGRES_USER" -lqt | cut -d \| -f 1 | grep -qw "$CHATWOOT_POSTGRES_DB"; then
    psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "CREATE DATABASE $CHATWOOT_POSTGRES_DB OWNER $CHATWOOT_POSTGRES_USER;"
    echo "Banco de dados $CHATWOOT_POSTGRES_DB criado."
else
    echo "Banco de dados $CHATWOOT_POSTGRES_DB já existe."
fi

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$CHATWOOT_POSTGRES_DB" <<-EOSQL
    CREATE EXTENSION IF NOT EXISTS vector;
EOSQL
echo "Extensão 'vector' habilitada em $CHATWOOT_POSTGRES_DB."


# -------------------------------------------------------
#     CRIAÇÃO DO USUÁRIO E BANCO DE DADOS DO N8N
# -------------------------------------------------------
echo "Verificando usuário do n8n: $N8N_POSTGRES_USER"
# Verifica se o usuário já existe
if ! psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -tAc "SELECT 1 FROM pg_roles WHERE rolname='$N8N_POSTGRES_USER'" | grep -q 1; then
    psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "CREATE USER $N8N_POSTGRES_USER WITH PASSWORD '$N8N_POSTGRES_PASSWORD';"
    echo "Usuário $N8N_POSTGRES_USER criado."
else
    echo "Usuário $N8N_POSTGRES_USER já existe."
fi

echo "Verificando banco de dados do n8n: $N8N_POSTGRES_DB"
# Verifica se o banco de dados já existe
if ! psql -U "$POSTGRES_USER" -lqt | cut -d \| -f 1 | grep -qw "$N8N_POSTGRES_DB"; then
    psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "CREATE DATABASE $N8N_POSTGRES_DB OWNER $N8N_POSTGRES_USER;"
    echo "Banco de dados $N8N_POSTGRES_DB criado."
else
    echo "Banco de dados $N8N_POSTGRES_DB já existe."
fi

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$N8N_POSTGRES_DB" <<-EOSQL
    CREATE EXTENSION IF NOT EXISTS vector;
EOSQL
echo "Extensão 'vector' habilitada em $N8N_POSTGRES_DB."

echo ">>>>>>>>> SCRIPT DE INICIALIZAÇÃO DO BANCO DE DADOS CONCLUÍDO <<<<<<<<<"