#!/bin/bash
action=$1

if [ "$action" == "kill" ]; then
    echo "Derrubando kafka-2..."
    docker-compose stop kafka-2
elif [ "$action" == "start" ]; then
    echo "Iniciando kafka-2..."
    docker-compose start kafka-2
else
    echo "Uso: bash simulate_failure.sh [kill|start]"
fi

