Pipeline CDC com Debezium e Kafka Connect
Pipeline completo de Change Data Capture (CDC) usando apenas Debezium e Kafka Connect.

📋 Arquitetura Simplificada
┌─────────────────────┐
│  Postgres Origem    │
│  (Tabelas: customers│
│   orders)           │
└──────────┬──────────┘
           │ WAL Replication
           ▼
┌─────────────────────┐
│ Debezium Connector  │
│ (Kafka Connect)     │
└──────────┬──────────┘
           │ Publica eventos CDC
           ▼
┌─────────────────────┐
│       Kafka         │
│  Topics: cdc.*      │
└──────┬────────┬─────┘
       │        │
       │        └─────────────┐
       ▼                      ▼
┌──────────────┐    ┌──────────────────┐
│ JDBC Sink    │    │   S3 Sink        │
│ Connector    │    │   Connector      │
└──────┬───────┘    └────────┬─────────┘
       │                     │
       ▼                     ▼
┌──────────────┐    ┌──────────────────┐
│  Postgres    │    │     MinIO        │
│  Destino     │    │   (S3 Storage)   │
└──────────────┘    └──────────────────┘
✨ Componentes
Postgres Origem - Banco com WAL habilitado para CDC
Debezium Source Connector - Captura mudanças do Postgres
Kafka - Streaming de eventos CDC
JDBC Sink Connector - Replica dados para Postgres destino
S3 Sink Connector - Armazena dados no MinIO
MinIO - Storage compatível com S3
Kafka UI - Interface web para monitoramento
🚀 Início Rápido
Pré-requisitos
Docker e Docker Compose
6GB+ RAM disponível
Portas livres: 5432, 5433, 8080, 8083-8085, 9000-9001, 9092, 29092
1. Estrutura de Arquivos
Crie a seguinte estrutura:

cdc-pipeline/
├── docker-compose.yml
├── init-source.sql
├── init-destination.sql
├── debezium-postgres-connector.json
├── postgres-sink-connector.json
├── s3-sink-connector.json
├── setup.sh
└── README.md
2. Iniciar Pipeline
bash
# Clone ou crie os arquivos
cd cdc-pipeline

# Inicie todos os serviços
docker-compose up -d

# Aguarde ~60 segundos para todos os serviços iniciarem
docker-compose ps

# Execute o script de configuração
chmod +x setup.sh
./setup.sh
O script setup.sh irá:

✅ Aguardar todos os serviços ficarem prontos
✅ Registrar o Source Connector (Debezium)
✅ Aguardar criação dos tópicos Kafka
✅ Registrar o Postgres Sink Connector
✅ Registrar o S3/MinIO Sink Connector
✅ Verificar status de todos os conectores
3. Testar o Pipeline
Inserir Dados no Origem
bash
# Conectar ao Postgres de origem
docker exec -it postgres-source psql -U sourceuser -d sourcedb

# Inserir novo cliente
INSERT INTO customers (name, email) 
VALUES ('Teste CDC', 'teste@cdc.com');

# Inserir pedido
INSERT INTO orders (customer_id, product_name, quantity, price) 
VALUES (1, 'Mouse Gamer', 1, 199.99);

# Atualizar cliente
UPDATE customers 
SET name = 'João Silva Santos' 
WHERE id = 1;

# Deletar pedido
DELETE FROM orders WHERE id = 1;

# Sair
\q
Verificar Replicação no Destino
bash
# Conectar ao Postgres de destino
docker exec -it postgres-destination psql -U destuser -d destdb

# Listar tabelas (nomes incluem o tópico completo)
\dt

# Consultar dados replicados
SELECT * FROM "cdc.public.customers";
SELECT * FROM "cdc.public.orders";

# Sair
\q
Verificar Dados no MinIO
Acesse http://localhost:9001
Login: minioadmin / minioadmin
Navegue até o bucket cdc-data
Veja os arquivos JSON organizados por data/hora
Monitorar via Kafka UI
Acesse http://localhost:8080
Visualize:
Topics: cdc.public.customers, cdc.public.orders
Conectores ativos
Mensagens em tempo real
Consumer groups
🔧 Comandos Úteis
Gerenciar Conectores
bash
# Listar todos os conectores
curl http://localhost:8083/connectors | jq

# Status do Source Connector
curl http://localhost:8083/connectors/postgres-source-connector/status | jq

# Status do Postgres Sink
curl http://localhost:8084/connectors/postgres-sink-connector/status | jq

# Status do S3 Sink
curl http://localhost:8085/connectors/s3-sink-connector/status | jq

# Pausar um conector
curl -X PUT http://localhost:8083/connectors/postgres-source-connector/pause

# Retomar um conector
curl -X PUT http://localhost:8083/connectors/postgres-source-connector/resume

# Reiniciar um conector
curl -X POST http://localhost:8083/connectors/postgres-source-connector/restart

# Deletar um conector
curl -X DELETE http://localhost:8083/connectors/postgres-source-connector
Monitorar Kafka
bash
# Listar tópicos
docker exec kafka kafka-topics --bootstrap-server localhost:9092 --list

# Descrever um tópico
docker exec kafka kafka-topics \
  --bootstrap-server localhost:9092 \
  --describe \
  --topic cdc.public.customers

# Consumir mensagens de um tópico (do início)
docker exec kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic cdc.public.customers \
  --from-beginning \
  --max-messages 10

# Consumir mensagens em tempo real
docker exec kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic cdc.public.customers

# Ver consumer groups
docker exec kafka kafka-consumer-groups \
  --bootstrap-server localhost:9092 \
  --list
Verificar Logs
bash
# Logs do Source Connector
docker-compose logs -f kafka-connect-source

# Logs do Postgres Sink
docker-compose logs -f kafka-connect-postgres-sink

# Logs do S3 Sink
docker-compose logs -f kafka-connect-s3-sink

# Logs do Kafka
docker-compose logs -f kafka

# Todos os logs
docker-compose logs -f
Gerenciar Containers
bash
# Status dos containers
docker-compose ps

# Reiniciar um serviço
docker-compose restart kafka-connect-source

# Parar todos os serviços
docker-compose down

# Parar e remover volumes (CUIDADO: apaga dados)
docker-compose down -v

# Reconstruir e reiniciar
docker-compose up -d --build
🎯 Funcionalidades do Pipeline
Operações CDC Suportadas
Operação	Source (Debezium)	Postgres Sink	S3 Sink
INSERT	✅ Captura	✅ Replica	✅ Armazena
UPDATE	✅ Captura	✅ Replica	✅ Armazena
DELETE	✅ Captura	✅ Replica	✅ Armazena
Formato dos Dados
Kafka (JSON)
json
{
  "id": 1,
  "name": "João Silva",
  "email": "joao@example.com",
  "created_at": "2024-12-10T10:00:00Z",
  "updated_at": "2024-12-10T10:00:00Z"
}
MinIO (Arquivos JSON particionados)
cdc-data/
└── year=2024/
    └── month=12/
        └── day=10/
            └── hour=10/
                ├── cdc.public.customers+0+0000000000.json
                └── cdc.public.orders+0+0000000000.json
🔍 Troubleshooting
Conector não inicia
bash
# Verificar logs
docker-compose logs kafka-connect-source

# Verificar status detalhado
curl http://localhost:8083/connectors/postgres-source-connector/status | jq

# Tentar recriar
curl -X DELETE http://localhost:8083/connectors/postgres-source-connector
./setup.sh
Dados não chegam ao destino
bash
# 1. Verificar se os tópicos foram criados
docker exec kafka kafka-topics --bootstrap-server localhost:9092 --list | grep cdc

# 2. Verificar se há mensagens no Kafka
docker exec kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic cdc.public.customers \
  --max-messages 5

# 3. Verificar status dos sinks
curl http://localhost:8084/connectors/postgres-sink-connector/status | jq
curl http://localhost:8085/connectors/s3-sink-connector/status | jq

# 4. Verificar logs dos sinks
docker-compose logs kafka-connect-postgres-sink
docker-compose logs kafka-connect-s3-sink
MinIO não conecta
bash
# Verificar se MinIO está rodando
docker-compose ps minio

# Reiniciar MinIO
docker-compose restart minio

# Recriar bucket
docker exec -it minio-init sh -c "
  mc alias set myminio http://minio:9000 minioadmin minioadmin && \
  mc mb myminio/cdc-data --ignore-existing
"
Postgres destino não recebe dados
bash
# Verificar permissões
docker exec -it postgres-destination psql -U destuser -d destdb -c "\du"

# Verificar se o sink está consumindo
docker-compose logs kafka-connect-postgres-sink | grep "WorkerSinkTask"

# Verificar consumer group lag
docker exec kafka kafka-consumer-groups \
  --bootstrap-server localhost:9092 \
  --describe \
  --group connect-postgres-sink
Performance lenta
bash
# Aumentar número de tasks no conector
# Edite o arquivo de configuração e aumente "tasks.max"

# Aumentar flush.size no S3 Sink
# Edite s3-sink-connector.json: "flush.size": "500"

# Aumentar recursos do Docker
# Configurações do Docker Desktop > Resources
📊 Monitoramento
Métricas Importantes
Kafka Connect Source
source-record-poll-rate: Taxa de leitura do WAL
source-record-write-rate: Taxa de escrita no Kafka
Kafka
Lag dos consumer groups
Tamanho dos tópicos
Taxa de mensagens/segundo
Sinks
sink-record-read-rate: Taxa de leitura do Kafka
sink-record-send-rate: Taxa de escrita no destino
Acessar Métricas
bash
# JMX Metrics do Kafka Connect
curl http://localhost:8083/metrics | jq

# Via Kafka UI
# http://localhost:8080 > Brokers > Metrics



📚 Recursos Adicionais
Debezium Documentation
Kafka Connect Documentation
Confluent S3 Sink
PostgreSQL Logical Replication


