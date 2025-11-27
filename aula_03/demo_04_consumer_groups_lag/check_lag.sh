#!/bin/bash
echo "Verificando LAG do grupo 'demo-group'..."
docker exec kafka kafka-consumer-groups \
    --bootstrap-server localhost:9092 \
    --describe \
    --group demo-group

