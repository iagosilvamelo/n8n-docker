# Estrutura Docker para Automação de WhatsApp com n8n e Chatwoot

Este projeto implanta uma infraestrutura completa e robusta para automação de conversas no WhatsApp. Ele utiliza o **n8n** como motor de automação, **Chatwoot** como plataforma de atendimento, **Baileys API** como ponte de comunicação com o WhatsApp e o **Minio** como bucket para armazenamento de arquivos a serem enviados na conversa, tudo orquestrado com Docker Compose.

## 🏗️ Arquitetura e Componentes

A estrutura é composta pelos seguintes serviços:

* **n8n**: Plataforma de automação de fluxos de trabalho. É o cérebro da operação, onde a lógica da conversa e as integrações são construídas.

* **Chatwoot**: Plataforma de atendimento ao cliente omnichannel. Oferece uma interface para que agentes humanos possam visualizar, assumir e gerenciar as conversas.

* **Sidekiq**: Processador de tarefas em segundo plano para o Chatwoot, garantindo que a aplicação principal não seja sobrecarregada.

* **Baileys API**: Uma API RESTful que serve como ponte para a biblioteca Baileys, permitindo a comunicação direta com o WhatsApp.

* **PostgreSQL (com pgvector)**: Banco de dados relacional que armazena os dados do n8n e do Chatwoot em bancos de dados separados. A extensão `pgvector` está disponível para futuras aplicações de IA (ex: busca semântica).

* **Redis**: Banco de dados em memória de alto desempenho, utilizado como cache e para gerenciamento de filas pelo Chatwoot e Sidekiq.

* **MinIO**: Serviço de armazenamento de objetos compatível com a API S3, usado para guardar arquivos e mídias das conversas (imagens, áudios, documentos).

## 🚀 Primeiros Passos

Siga as instruções abaixo para configurar e iniciar o ambiente.

### Pré-requisitos

* [Docker](https://docs.docker.com/get-docker/)
* [Docker Compose](https://docs.docker.com/compose/install/)

### Configuração

1.  **Clone o Repositório**
    ```bash
    git clone <url-do-seu-repositorio>
    cd <nome-do-seu-repositorio>
    ```

2.  **Crie o arquivo de ambiente**
    Crie um arquivo chamado `.env` na raiz do projeto, copiando o conteúdo do exemplo abaixo. Este arquivo centraliza todas as variáveis de ambiente necessárias para os serviços.

    ```dotenv
    # .env.example

    # --- Configurações Gerais ---
    GENERIC_TIMEZONE=America/Sao_Paulo

    # --- Configurações do n8n ---
    # Domínio para acessar o n8n e para os webhooks
    SUBDOMAIN=n8n
    DOMAIN_NAME=localhost
    N8N_POSTGRES_DB=n8n_db
    N8N_POSTGRES_USER=n8n_user
    N8N_POSTGRES_PASSWORD=sua-senha-segura-para-n8n

    # --- Configurações do Chatwoot ---
    # URL pública do Chatwoot (ex: http://localhost:3000)
    FRONTEND_URL=http://localhost:3000
    CHATWOOT_POSTGRES_DB=chatwoot_db
    CHATWOOT_POSTGRES_USER=chatwoot_user
    CHATWOOT_POSTGRES_PASSWORD=sua-senha-segura-para-chatwoot

    # --- Configurações do PostgreSQL (Admin) ---
    # Usuário e senha principal do PostgreSQL
    POSTGRES_DB=postgres
    POSTGRES_USER=admin
    POSTGRES_PASSWORD=sua-senha-de-admin-do-postgres

    # --- Configurações do Redis ---
    # Defina uma senha para o Redis
    SERVICE_PASSWORD_REDIS=sua-senha-segura-para-redis

    # --- Configurações do Baileys API ---
    BAILEYS_PROVIDER_DEFAULT_CLIENT_NAME=baileys_client
    # Gere uma chave de API para o Baileys com: openssl rand -base64 64
    SERVICE_PASSWORD_64_BAILEYSDEFAULTAPIKEY=sua-chave-de-api-aqui

    # --- Configurações de LOG ---
    LOG_LEVEL=info
    BAILEYS_LOG_LEVEL=error

    # --- Chaves Secretas (SECRET_KEY_BASE para o Chatwoot) ---
    # Gere uma chave com: openssl rand -base64 64
    SERVICE_PASSWORD_64_SECRETKEYBASE=sua-chave-secreta-do-rails-aqui

    # --- Configurações do MinIO ---
    MINIO_ROOT_USER=minio_admin
    MINIO_ROOT_PASSWORD=sua-senha-segura-para-minio
    ```

    **Importante**: Para gerar as chaves secretas (`SERVICE_PASSWORD_64...`), utilize o comando abaixo no seu terminal e cole o resultado no arquivo `.env`:
    ```bash
    openssl rand -base64 64
    ```

### Executando a Aplicação

Com o arquivo `.env` devidamente configurado, inicie todos os serviços em modo "detached" (-d):

```bash
docker-compose up -d
```

Conecte o PostgreSQL e crie um banco de dados com o nome **n8n** para que a aplicação N8N possa subir. Crie um banco de dados com nome da sua escolha para usar como gestor de histórico da sua agente IA.