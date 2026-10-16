
BEGIN;

-- =========================================================
-- 1. CONTAS DO INSTAGRAM
-- Permite atender várias contas comerciais.
-- =========================================================

CREATE TABLE IF NOT EXISTS instagram_contas (
    id BIGSERIAL PRIMARY KEY,
    instagram_account_id VARCHAR(100) NOT NULL UNIQUE,
    username VARCHAR(255),
    nome VARCHAR(255),
    ativa BOOLEAN NOT NULL DEFAULT TRUE,
    configuracoes JSONB NOT NULL DEFAULT '{}'::JSONB,
    created_at TIMESTAMP WITHOUT TIME ZONE
        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITHOUT TIME ZONE
        NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- =========================================================
-- 2. CONTATOS
-- O Instagram ID identifica o usuário no contexto da conta.
-- =========================================================

CREATE TABLE IF NOT EXISTS instagram_contatos (
    id BIGSERIAL PRIMARY KEY,
    conta_id BIGINT NOT NULL
        REFERENCES instagram_contas(id) ON DELETE CASCADE,
    instagram_user_id VARCHAR(100) NOT NULL,
    username VARCHAR(255),
    nome VARCHAR(255),
    nome_completo VARCHAR(255),
    foto_perfil_url TEXT,
    dados_adicionais JSONB NOT NULL DEFAULT '{}'::JSONB,
    primeira_interacao_em TIMESTAMP WITHOUT TIME ZONE
        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ultima_interacao_em TIMESTAMP WITHOUT TIME ZONE,
    created_at TIMESTAMP WITHOUT TIME ZONE
        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITHOUT TIME ZONE
        NOT NULL DEFAULT CURRENT_TIMESTAMP,

    UNIQUE (conta_id, instagram_user_id)
);

CREATE INDEX IF NOT EXISTS idx_instagram_contatos_username
    ON instagram_contatos (username);

CREATE INDEX IF NOT EXISTS idx_instagram_contatos_ultima_interacao
    ON instagram_contatos (ultima_interacao_em DESC);

-- =========================================================
-- 3. CONVERSAS
-- Uma conversa pertence a uma conta e a um contato.
-- =========================================================

CREATE TABLE IF NOT EXISTS instagram_conversas (
    id BIGSERIAL PRIMARY KEY,
    conta_id BIGINT NOT NULL
        REFERENCES instagram_contas(id) ON DELETE CASCADE,
    contato_id BIGINT NOT NULL
        REFERENCES instagram_contatos(id) ON DELETE CASCADE,

    instagram_conversation_id VARCHAR(255),
    canal VARCHAR(30) NOT NULL DEFAULT 'direct',
    origem VARCHAR(30) NOT NULL DEFAULT 'direct',
    status VARCHAR(30) NOT NULL DEFAULT 'aberta',

    atendente_tipo VARCHAR(30) NOT NULL DEFAULT 'ia',
    atendente_identificador VARCHAR(255),

    assunto VARCHAR(255),
    intencao_atual VARCHAR(255),
    etapa_atendimento VARCHAR(100),
    prioridade SMALLINT NOT NULL DEFAULT 0,

    ultima_mensagem_em TIMESTAMP WITHOUT TIME ZONE,
    ultima_mensagem_recebida_em TIMESTAMP WITHOUT TIME ZONE,
    ultima_resposta_enviada_em TIMESTAMP WITHOUT TIME ZONE,

    metadados JSONB NOT NULL DEFAULT '{}'::JSONB,

    created_at TIMESTAMP WITHOUT TIME ZONE
        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITHOUT TIME ZONE
        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    encerrada_em TIMESTAMP WITHOUT TIME ZONE,

    CHECK (prioridade BETWEEN 0 AND 5),
    UNIQUE (id, conta_id)
);

CREATE UNIQUE INDEX IF NOT EXISTS
    uq_instagram_conversas_api_id
    ON instagram_conversas (conta_id, instagram_conversation_id)
    WHERE instagram_conversation_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_instagram_conversas_contato
    ON instagram_conversas (conta_id, contato_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_instagram_conversas_status
    ON instagram_conversas (status, ultima_mensagem_em DESC);

CREATE INDEX IF NOT EXISTS idx_instagram_conversas_atendente
    ON instagram_conversas (atendente_tipo, status);

-- =========================================================
-- 4. MENSAGENS
-- Histórico original e cronológico da conversa.
-- =========================================================

CREATE TABLE IF NOT EXISTS instagram_mensagens (
    id BIGSERIAL PRIMARY KEY,
    conversa_id BIGINT NOT NULL,
    conta_id BIGINT NOT NULL,

    instagram_message_id VARCHAR(255),
    mensagem_resposta_id VARCHAR(255),

    direcao VARCHAR(10) NOT NULL,
    tipo VARCHAR(30) NOT NULL DEFAULT 'text',
    remetente_tipo VARCHAR(20) NOT NULL,
    remetente_instagram_id VARCHAR(100),

    conteudo TEXT,
    conteudo_processado TEXT,
    midias JSONB NOT NULL DEFAULT '[]'::JSONB,
    payload_original JSONB NOT NULL DEFAULT '{}'::JSONB,

    status VARCHAR(30) NOT NULL DEFAULT 'recebida',
    erro_envio TEXT,

    enviada_pela_ia BOOLEAN NOT NULL DEFAULT FALSE,
    dados_ia JSONB NOT NULL DEFAULT '{}'::JSONB,

    mensagem_em TIMESTAMP WITHOUT TIME ZONE
        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    recebida_em TIMESTAMP WITHOUT TIME ZONE,
    processada_em TIMESTAMP WITHOUT TIME ZONE,
    created_at TIMESTAMP WITHOUT TIME ZONE
        NOT NULL DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (conversa_id, conta_id)
        REFERENCES instagram_conversas(id, conta_id)
        ON DELETE CASCADE,

    CHECK (direcao IN ('entrada', 'saida')),
    CHECK (remetente_tipo IN ('usuario', 'ia', 'humano', 'sistema')),

    UNIQUE (id, conversa_id)
);

-- Evita duplicação de mensagens recebidas ou enviadas.
CREATE UNIQUE INDEX IF NOT EXISTS
    uq_instagram_mensagens_api_id
    ON instagram_mensagens (conta_id, instagram_message_id)
    WHERE instagram_message_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_instagram_mensagens_historico
    ON instagram_mensagens (conversa_id, mensagem_em, id);

CREATE INDEX IF NOT EXISTS idx_instagram_mensagens_status
    ON instagram_mensagens (status, created_at)
    WHERE status IN ('recebida', 'pendente', 'erro');

CREATE INDEX IF NOT EXISTS idx_instagram_mensagens_resposta
    ON instagram_mensagens (mensagem_resposta_id)
    WHERE mensagem_resposta_id IS NOT NULL;

-- =========================================================
-- 5. CONTEXTO PERSISTENTE DA IA
-- Resumo e fatos que devem sobreviver entre execuções.
-- =========================================================

CREATE TABLE IF NOT EXISTS instagram_contexto_ia (
    id BIGSERIAL PRIMARY KEY,
    conversa_id BIGINT NOT NULL UNIQUE
        REFERENCES instagram_conversas(id) ON DELETE CASCADE,

    resumo_conversa TEXT,
    fatos_importantes JSONB NOT NULL DEFAULT '{}'::JSONB,
    preferencias JSONB NOT NULL DEFAULT '{}'::JSONB,
    intencoes JSONB NOT NULL DEFAULT '[]'::JSONB,
    pendencias JSONB NOT NULL DEFAULT '[]'::JSONB,

    ultima_intencao VARCHAR(255),
    sentimento VARCHAR(30),
    etapa_jornada VARCHAR(100),

    instrucoes_especificas TEXT,
    ultima_mensagem_resumida_id BIGINT,
    quantidade_mensagens_resumidas INTEGER NOT NULL DEFAULT 0,
    versao_contexto INTEGER NOT NULL DEFAULT 1,

    atualizado_pela_ia_em TIMESTAMP WITHOUT TIME ZONE,
    created_at TIMESTAMP WITHOUT TIME ZONE
        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITHOUT TIME ZONE
        NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- =========================================================
-- 6. EVENTOS DE WEBHOOK
-- Rastreia eventos recebidos, falhas e reprocessamentos.
-- =========================================================

CREATE TABLE IF NOT EXISTS instagram_eventos (
    id BIGSERIAL PRIMARY KEY,
    conta_id BIGINT
        REFERENCES instagram_contas(id) ON DELETE SET NULL,

    idempotency_key VARCHAR(255) NOT NULL UNIQUE,
    tipo_evento VARCHAR(100) NOT NULL,
    instagram_message_id VARCHAR(255),
    payload JSONB NOT NULL,

    status VARCHAR(30) NOT NULL DEFAULT 'pendente',
    tentativas INTEGER NOT NULL DEFAULT 0,
    ultimo_erro TEXT,

    recebido_em TIMESTAMP WITHOUT TIME ZONE
        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    proxima_tentativa_em TIMESTAMP WITHOUT TIME ZONE,
    processado_em TIMESTAMP WITHOUT TIME ZONE
);

CREATE INDEX IF NOT EXISTS idx_instagram_eventos_pendentes
    ON instagram_eventos (status, proxima_tentativa_em, recebido_em)
    WHERE status IN ('pendente', 'erro', 'processando');

-- =========================================================
-- 7. FILA DE MENSAGENS
-- Controla o processamento assíncrono no n8n.
-- =========================================================

CREATE TABLE IF NOT EXISTS instagram_fila_mensagens (
    id BIGSERIAL PRIMARY KEY,
    evento_id BIGINT
        REFERENCES instagram_eventos(id) ON DELETE SET NULL,
    mensagem_id BIGINT
        REFERENCES instagram_mensagens(id) ON DELETE CASCADE,
    conversa_id BIGINT NOT NULL
        REFERENCES instagram_conversas(id) ON DELETE CASCADE,

    tipo_tarefa VARCHAR(50) NOT NULL DEFAULT 'responder',
    status VARCHAR(30) NOT NULL DEFAULT 'pendente',
    prioridade SMALLINT NOT NULL DEFAULT 0,

    tentativas INTEGER NOT NULL DEFAULT 0,
    max_tentativas INTEGER NOT NULL DEFAULT 5,
    payload JSONB NOT NULL DEFAULT '{}'::JSONB,
    ultimo_erro TEXT,

    disponivel_em TIMESTAMP WITHOUT TIME ZONE
        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    bloqueada_em TIMESTAMP WITHOUT TIME ZONE,
    concluida_em TIMESTAMP WITHOUT TIME ZONE,
    created_at TIMESTAMP WITHOUT TIME ZONE
        NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_instagram_fila_processamento
    ON instagram_fila_mensagens
        (status, prioridade DESC, disponivel_em, id)
    WHERE status IN ('pendente', 'erro');

CREATE INDEX IF NOT EXISTS idx_instagram_fila_conversa
    ON instagram_fila_mensagens (conversa_id, created_at DESC);

COMMIT;
