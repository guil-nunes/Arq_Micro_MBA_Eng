#!/bin/bash
echo "Criando tópico 'demo-particoes'..."
docker exec kafka kafka-topics --create \
    --topic demo-particoes \
    --bootstrap-server localhost:9092 \
    --partitions 4 \
    --replication-factor 3

echo "Tópico criado com sucesso!"
echo "Listando detalhes do tópico:"
docker exec kafka kafka-topics --describe \
    --topic demo-particoes \
    --bootstrap-server localhost:9092

