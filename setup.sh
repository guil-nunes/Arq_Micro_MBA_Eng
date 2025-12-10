#!/bin/bash

echo "=============================================="
echo "Pipeline CDC - Configuração Automática"
echo "=============================================="

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Função para aguardar serviço
wait_for_service() {
    local service=$1
    local url=$2
    local max_attempts=60
    local attempt=0
    
    echo -e "${YELLOW}⏳ Aguardando $service...${NC}"
    
    while [ $attempt -lt $max_attempts ]; do
        response=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null)
        if [ "$response" = "200" ] || [ "$response" = "404" ]; then
            echo -e "${GREEN}✓ $service está pronto!${NC}"
            return 0
        fi
        attempt=$((attempt + 1))
        echo -n "."
        sleep 2
    done
    
    echo -e "${RED}✗ Timeout aguardando $service${NC}"
    return 1
}

# Função para registrar conector
register_connector() {
    local name=$1
    local config_file=$2
    local connect_url=$3
    
    echo -e "${BLUE}📋 Registrando conector: $name${NC}"
    
    # Remove conector existente
    curl -s -X DELETE "$connect_url/connectors/$name" > /dev/null 2>&1
    sleep 2
    
    # Registra novo conector
    response=$(curl -s -w "\n%{http_code}" -X POST \
        -H "Accept:application/json" \
        -H "Content-Type:application/json" \
        "$connect_url/connectors/" \
        -d @"$config_file")
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "201" ] || [ "$http_code" = "200" ]; then
        echo -e "${GREEN}✓ Conector $name registrado com sucesso!${NC}"
        return 0
    else
        echo -e "${RED}✗ Erro ao registrar $name (HTTP $http_code)${NC}"
        echo "$body" | jq '.' 2>/dev/null || echo "$body"
        return 1
    fi
}

# Função para verificar status do conector
check_connector_status() {
    local name=$1
    local connect_url=$2
    
    echo -e "${BLUE}🔍 Status do conector: $name${NC}"
    
    status=$(curl -s "$connect_url/connectors/$name/status" | jq '.')
    
    if [ $? -eq 0 ]; then
        echo "$status" | jq '.connector.state, .tasks[0].state'
        state=$(echo "$status" | jq -r '.connector.state')
        if [ "$state" = "RUNNING" ]; then
            echo -e "${GREEN}✓ Conector $name está RUNNING${NC}"
        else
            echo -e "${YELLOW}⚠ Conector $name está em estado: $state${NC}"
        fi
    else
        echo -e "${RED}✗ Não foi possível verificar status de $name${NC}"
    fi
}

echo ""
echo "================================================"
echo "Etapa 1: Aguardando serviços iniciarem..."
echo "================================================"

wait_for_service "Kafka Connect Source" "http://localhost:8083"
wait_for_service "Kafka Connect Postgres Sink" "http://localhost:8084"
wait_for_service "Kafka Connect S3 Sink" "http://localhost:8085"

echo ""
echo "================================================"
echo "Etapa 2: Registrando Source Connector (Debezium)"
echo "================================================"

register_connector "postgres-source-connector" \
    "debezium-postgres-connector.json" \
    "http://localhost:8083"

sleep 5
check_connector_status "postgres-source-connector" "http://localhost:8083"

echo ""
echo "================================================"
echo "Etapa 3: Aguardando criação de tópicos..."
echo "================================================"

echo -e "${YELLOW}⏳ Aguardando tópicos do Kafka serem criados...${NC}"
sleep 15

echo "Tópicos disponíveis:"
docker exec kafka kafka-topics --bootstrap-server localhost:9092 --list | grep "cdc.public"

echo ""
echo "================================================"
echo "Etapa 4: Registrando Postgres Sink Connector"
echo "================================================"

register_connector "postgres-sink-connector" \
    "postgres-sink-connector.json" \
    "http://localhost:8084"

sleep 5
check_connector_status "postgres-sink-connector" "http://localhost:8084"

echo ""
echo "================================================"
echo "Etapa 5: Registrando S3/MinIO Sink Connector"
echo "================================================"

register_connector "s3-sink-connector" \
    "s3-sink-connector.json" \
    "http://localhost:8085"

sleep 5
check_connector_status "s3-sink-connector" "http://localhost:8085"

echo ""
echo "================================================"
echo "✅ Configuração Concluída!"
echo "================================================"
echo ""
echo "📊 SERVIÇOS DISPONÍVEIS:"
echo "================================================"
echo ""
echo "🗄️  Postgres Origem:"
echo "   URL: localhost:5432"
echo "   User: sourceuser | Pass: sourcepass | DB: sourcedb"
echo ""
echo "🗄️  Postgres Destino:"
echo "   URL: localhost:5433"
echo "   User: destuser | Pass: destpass | DB: destdb"
echo ""
echo "📨 Kafka:"
echo "   Broker: localhost:29092"
echo "   UI: http://localhost:8080"
echo ""
echo "🔌 Kafka Connect:"
echo "   Source (Debezium): http://localhost:8083"
echo "   Postgres Sink: http://localhost:8084"
echo "   S3 Sink: http://localhost:8085"
echo ""
echo "💾 MinIO:"
echo "   Console: http://localhost:9001"
echo "   API: http://localhost:9000"
echo "   User: minioadmin | Pass: minioadmin"
echo ""
echo "================================================"
echo "🧪 TESTAR O PIPELINE:"
echo "================================================"
echo ""
echo "1️⃣  Conectar ao Postgres de origem:"
echo "   docker exec -it postgres-source psql -U sourceuser -d sourcedb"
echo ""
echo "2️⃣  Inserir dados:"
echo "   INSERT INTO customers (name, email) VALUES ('Teste CDC', 'teste@cdc.com');"
echo ""
echo "3️⃣  Verificar no Postgres destino:"
echo "   docker exec -it postgres-destination psql -U destuser -d destdb"
echo "   SELECT * FROM \"cdc.public.customers\";"
echo ""
echo "4️⃣  Verificar no MinIO:"
echo "   Acesse http://localhost:9001 e navegue no bucket 'cdc-data'"
echo ""
echo "5️⃣  Monitorar no Kafka UI:"
echo "   Acesse http://localhost:8080"
echo ""
echo "================================================"
echo "📝 COMANDOS ÚTEIS:"
echo "================================================"
echo ""
echo "# Listar conectores:"
echo "curl http://localhost:8083/connectors"
echo ""
echo "# Status de um conector:"
echo "curl http://localhost:8083/connectors/postgres-source-connector/status | jq"
echo ""
echo "# Ver mensagens de um tópico:"
echo "docker exec kafka kafka-console-consumer \\"
echo "  --bootstrap-server localhost:9092 \\"
echo "  --topic cdc.public.customers \\"
echo "  --from-beginning"
echo ""
echo "# Logs de um serviço:"
echo "docker-compose logs -f kafka-connect-source"
echo ""
echo "================================================"