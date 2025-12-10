-- Prepara o banco de destino para receber dados do CDC
-- As tabelas serão criadas automaticamente pelo JDBC Sink Connector

-- Cria schema se necessário
CREATE SCHEMA IF NOT EXISTS public;

-- Garantir permissões adequadas
GRANT ALL PRIVILEGES ON SCHEMA public TO destuser;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO destuser;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO destuser;

-- Configuração para auto-criação de tabelas
ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT ALL PRIVILEGES ON TABLES TO destuser;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT ALL PRIVILEGES ON SEQUENCES TO destuser;