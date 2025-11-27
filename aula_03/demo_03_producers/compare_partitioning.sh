#!/bin/bash
echo "Consumindo para verificar distribuição..."
docker exec kafka kafka-console-consumer \
    --bootstrap-server localhost:9092 \
    --topic demo-producers \
    --from-beginning \
    --property print.key=true \
    --property print.partition=true \
    --max-messages 40

