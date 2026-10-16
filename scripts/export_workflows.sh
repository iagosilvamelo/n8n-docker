#!/bin/bash
set -e

# Diretório base do repositório
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKFLOWS_DIR="$REPO_DIR/workflows"
CONTAINER_NAME="${N8N_CONTAINER_NAME:-n8n}"
TEMP_EXPORT_DIR="/tmp/workflows_export_$(date +%s)"

echo "🔄 Exportando workflows do n8n em execução (container: $CONTAINER_NAME)..."

# Cria diretório temporário no container e exporta os workflows formatados e separados
docker exec "$CONTAINER_NAME" mkdir -p "$TEMP_EXPORT_DIR"
docker exec "$CONTAINER_NAME" n8n export:workflow --backup --output="$TEMP_EXPORT_DIR/"

# Garante que o diretório de destino local existe
mkdir -p "$WORKFLOWS_DIR"

# Copia os arquivos exportados para a pasta workflows do repositório
docker cp "$CONTAINER_NAME:$TEMP_EXPORT_DIR/." "$WORKFLOWS_DIR/"

# Remove diretório temporário dentro do container
docker exec "$CONTAINER_NAME" rm -rf "$TEMP_EXPORT_DIR"

echo "✅ Workflows exportados com sucesso para $WORKFLOWS_DIR:"
ls -lh "$WORKFLOWS_DIR"/*.json
