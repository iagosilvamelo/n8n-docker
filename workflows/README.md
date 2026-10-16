# Workflows do n8n

Nesta pasta estão versionados os arquivos JSON dos workflows do n8n em formato legível e individual (`--backup` / `--separate`), mantendo a compatibilidade direta com a CLI do n8n (`export:workflow` / `import:workflow`).

## 📋 Mapeamento dos Workflows

| Arquivo | ID | Nome do Workflow | Status |
|---|---|---|---|
| [`H3TjPx76MJA7VKoj.json`](file:///home/ubuntu/services/n8n/workflows/H3TjPx76MJA7VKoj.json) | `H3TjPx76MJA7VKoj` | `[LAILA] Secretária` | Ativo |
| [`YoXgdB6eQNIE0DfM.json`](file:///home/ubuntu/services/n8n/workflows/YoXgdB6eQNIE0DfM.json) | `YoXgdB6eQNIE0DfM` | `[cispmtb] Secretaria` | Inativo |

---

## 🔄 Fluxo de Trabalho (Painel ↔ IDE)

O n8n armazena os workflows no banco de dados (PostgreSQL) e roda uma aplicação web. Por conta disso, o painel web não lê nem grava diretamente arquivos de texto no disco em tempo real. Para transitar alterações com total segurança:

### 1. Do Painel n8n ➔ para a IDE (Export / Pull)
Sempre que você criar ou editar algo no editor web do n8n e quiser salvar na IDE para versionar:
```bash
./scripts/export_workflows.sh
```
Depois é só commitar no Git:
```bash
git add workflows/
git commit -m "feat(workflows): atualiza automações"
```

### 2. Da IDE ➔ para o Painel n8n (Import / Push)
Se você editar o JSON diretamente na IDE e quiser aplicar as alterações no n8n:
```bash
./scripts/import_workflows.sh
```
> **Nota importante:** Se a tela do n8n já estiver aberta no seu navegador, pressione **F5** para recarregar o canvas com as novidades importadas.
