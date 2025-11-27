#!/bin/bash
echo "Consumindo mensagens do início para ver offsets..."
docker exec kafka kafka-console-consumer \
    --bootstrap-server localhost:9092 \
    --topic demo-particoes \
    --from-beginning \
    --property print.partition=true \
    --property print.offset=true \
    --property print.key=true \
    --timeout-ms 5000

