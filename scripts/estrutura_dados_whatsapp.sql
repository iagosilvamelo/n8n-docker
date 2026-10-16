CREATE TABLE n8n_historico_mensagens (
    id BIGSERIAL PRIMARY KEY,
    session_id VARCHAR(40) NOT NULL,
    message JSONB NOT NULL,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_n8n_historico_mensagens_session_id
    ON n8n_historico_mensagens (session_id);

CREATE TABLE n8n_fila_mensagens (
    id BIGSERIAL PRIMARY KEY,
    id_mensagem VARCHAR(40) NOT NULL,
    telefone VARCHAR(40) NOT NULL,
    mensagem TEXT NOT NULL,
    "timestamp" TIMESTAMP WITHOUT TIME ZONE NOT NULL
);

CREATE INDEX idx_n8n_fila_mensagens_telefone
    ON n8n_fila_mensagens (telefone);

CREATE TABLE treatments (
    id BIGSERIAL PRIMARY KEY,
    protocol VARCHAR(40) NOT NULL,
    phone_number VARCHAR(40) NOT NULL,
    messages JSONB NOT NULL,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_treatments_protocol ON treatments (protocol);

CREATE TABLE transmission_phones (
    id BIGSERIAL PRIMARY KEY,
    phone_number VARCHAR(40) NOT NULL UNIQUE,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_transmission_phones_phone_number
    ON transmission_phones (phone_number);

CREATE TABLE conversation_metadata (
    session_id VARCHAR(255) PRIMARY KEY,
    id_conversa VARCHAR(255),
    id_conta VARCHAR(255),
    last_updated TIMESTAMP
);

CREATE INDEX idx_conversation_metadata_session_id
    ON conversation_metadata (session_id);