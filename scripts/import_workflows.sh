#!/bin/bash
set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKFLOWS_DIR="$REPO_DIR/workflows"
CONTAINER_NAME="${N8N_CONTAINER_NAME:-n8n}"
TEMP_IMPORT_DIR="/tmp/workflows_import_$(date +%s)"

if [ ! -d "$WORKFLOWS_DIR" ] || [ -z "$(ls -A "$WORKFLOWS_DIR"/*.json 2>/dev/null)" ]; then
  echo "⚠️ Nenhum arquivo .json encontrado na pasta $WORKFLOWS_DIR"
  exit 1
fi

echo "🔄 Importando workflows da IDE para o n8n (container: $CONTAINER_NAME)..."

# Cria pasta temporária no container e envia os arquivos JSON
docker exec "$CONTAINER_NAME" mkdir -p "$TEMP_IMPORT_DIR"
docker cp "$WORKFLOWS_DIR/." "$CONTAINER_NAME:$TEMP_IMPORT_DIR/"

# Importa os workflows para o n8n
docker exec "$CONTAINER_NAME" n8n import:workflow --separate --input="$TEMP_IMPORT_DIR/"

# Remove pasta temporária
docker exec "$CONTAINER_NAME" rm -rf "$TEMP_IMPORT_DIR"

# Restaura o status ativo dos workflows que têm "active": true no JSON
for file in "$WORKFLOWS_DIR"/*.json; do
  [ -f "$file" ] || continue
  is_active=$(grep -o '"active":[[:space:]]*true' "$file" || true)
  if [ -n "$is_active" ]; then
    wf_id=$(basename "$file" .json)
    echo "⚡ Reativando workflow $wf_id..."
    docker exec "$CONTAINER_NAME" n8n publish:workflow --id="$wf_id" >/dev/null 2>&1 || true
  fi
done

echo "✅ Importação concluída com sucesso!"
echo "💡 Importante: Se o painel do n8n estiver aberto no navegador, pressione F5 para atualizar o canvas com as mudanças."
