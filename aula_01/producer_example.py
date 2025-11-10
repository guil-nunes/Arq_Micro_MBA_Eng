#!/usr/bin/env python3
"""
Exemplo de Producer Kafka com Schema Registry
Este script cria um tópico, registra um schema Avro e produz mensagens
"""

import json
import time
from confluent_kafka import Producer
from confluent_kafka.admin import AdminClient, NewTopic
from confluent_kafka.schema_registry import SchemaRegistryClient
from confluent_kafka.schema_registry.avro import AvroProducer

# Configurações
KAFKA_BOOTSTRAP_SERVERS = "localhost:9092"
SCHEMA_REGISTRY_URL = "http://localhost:8082"
TOPIC_NAME = "user-events"

# Schema Avro para os eventos de usuário
USER_EVENT_SCHEMA = """
{
  "type": "record",
  "name": "UserEvent",
  "namespace": "com.example",
  "fields": [
    {
      "name": "user_id",
      "type": "int"
    },
    {
      "name": "username",
      "type": "string"
    },
    {
      "name": "email",
      "type": "string"
    },
    {
      "name": "action",
      "type": {
        "type": "enum",
        "name": "Action",
        "symbols": ["LOGIN", "LOGOUT", "PURCHASE", "VIEW"]
      }
    },
    {
      "name": "timestamp",
      "type": "long"
    },
    {
      "name": "metadata",
      "type": {
        "type": "map",
        "values": "string"
      }
    }
  ]
}
"""


def create_topic():
    """Cria o tópico no Kafka se não existir"""
    admin_client = AdminClient({
        'bootstrap.servers': KAFKA_BOOTSTRAP_SERVERS
    })
    
    topic_list = [NewTopic(TOPIC_NAME, num_partitions=3, replication_factor=1)]
    
    # Verifica se o tópico já existe
    existing_topics = admin_client.list_topics(timeout=10).topics
    
    if TOPIC_NAME in existing_topics:
        print(f"Tópico '{TOPIC_NAME}' já existe!")
        return
    
    # Cria o tópico
    futures = admin_client.create_topics(topic_list)
    
    for topic, future in futures.items():
        try:
            future.result()
            print(f"Tópico '{topic}' criado com sucesso!")
        except Exception as e:
            print(f"Erro ao criar tópico '{topic}': {e}")


def produce_messages_with_schema():
    """Produz mensagens com schema Avro registrado"""
    
    # Configuração do Schema Registry
    schema_registry_client = SchemaRegistryClient({
        'url': SCHEMA_REGISTRY_URL
    })
    
    # Registra o schema primeiro
    try:
        schema_id = schema_registry_client.register_schema(
            subject_name=f"{TOPIC_NAME}-value",
            schema=USER_EVENT_SCHEMA
        )
        print(f"✓ Schema registrado com sucesso no Schema Registry! (ID: {schema_id})")
    except Exception as e:
        # Se o schema já existe, tenta obter o existente
        try:
            latest_schema = schema_registry_client.get_latest_schema(f"{TOPIC_NAME}-value")
            print(f"✓ Schema já existe no Schema Registry! (ID: {latest_schema.schema_id})")
        except:
            print(f"⚠ Erro ao registrar/obter schema: {e}")
    
    # Configuração do Producer com Avro
    producer_config = {
        'bootstrap.servers': KAFKA_BOOTSTRAP_SERVERS,
        'schema.registry.url': SCHEMA_REGISTRY_URL
    }
    
    # Cria o AvroProducer com o schema
    producer = AvroProducer(
        producer_config,
        default_value_schema=USER_EVENT_SCHEMA
    )
    
    # Dados de exemplo
    sample_users = [
        {
            "user_id": 1,
            "username": "alice",
            "email": "alice@example.com",
            "action": "LOGIN",
            "timestamp": int(time.time() * 1000),
            "metadata": {"ip": "192.168.1.1", "browser": "Chrome"}
        },
        {
            "user_id": 2,
            "username": "bob",
            "email": "bob@example.com",
            "action": "PURCHASE",
            "timestamp": int(time.time() * 1000),
            "metadata": {"product_id": "123", "price": "99.99"}
        },
        {
            "user_id": 3,
            "username": "charlie",
            "email": "charlie@example.com",
            "action": "VIEW",
            "timestamp": int(time.time() * 1000),
            "metadata": {"page": "/products", "duration": "30s"}
        },
        {
            "user_id": 1,
            "username": "alice",
            "email": "alice@example.com",
            "action": "LOGOUT",
            "timestamp": int(time.time() * 1000),
            "metadata": {"session_duration": "3600s"}
        },
        {
            "user_id": 4,
            "username": "diana",
            "email": "diana@example.com",
            "action": "LOGIN",
            "timestamp": int(time.time() * 1000),
            "metadata": {"ip": "192.168.1.2", "browser": "Firefox"}
        }
    ]
    
    # Produz mensagens
    print(f"\nProduzindo {len(sample_users)} mensagens no tópico '{TOPIC_NAME}'...")
    
    for i, user_event in enumerate(sample_users, 1):
        try:
            # Usa AvroProducer para enviar com schema
            producer.produce(
                topic=TOPIC_NAME,
                value=user_event
            )
            print(f"✓ Mensagem {i}/{len(sample_users)} enviada: {user_event['username']} - {user_event['action']}")
            time.sleep(0.5)  # Pequeno delay entre mensagens
        except Exception as e:
            print(f"✗ Erro ao enviar mensagem {i}: {e}")
            import traceback
            traceback.print_exc()
    
    # Aguarda todas as mensagens serem enviadas
    producer.flush()
    print(f"\n✓ Todas as mensagens foram enviadas com sucesso!")
    print(f"\nAcesse a UI do Kafka em: http://localhost:8080")
    print(f"Ou AKHQ em: http://localhost:8081")


def produce_messages_simple():
    """Versão simplificada sem Avro (para teste rápido)"""
    producer = Producer({
        'bootstrap.servers': KAFKA_BOOTSTRAP_SERVERS
    })
    
    sample_messages = [
        {"message": "Hello Kafka!", "number": 1},
        {"message": "Segunda mensagem", "number": 2},
        {"message": "Terceira mensagem", "number": 3},
    ]
    
    print(f"\nProduzindo {len(sample_messages)} mensagens simples no tópico '{TOPIC_NAME}'...")
    
    for i, msg in enumerate(sample_messages, 1):
        try:
            producer.produce(
                TOPIC_NAME,
                value=json.dumps(msg).encode('utf-8')
            )
            print(f"✓ Mensagem {i}/{len(sample_messages)} enviada: {msg['message']}")
        except Exception as e:
            print(f"✗ Erro ao enviar mensagem {i}: {e}")
    
    producer.flush()
    print(f"\n✓ Mensagens simples enviadas!")


if __name__ == "__main__":
    print("=" * 60)
    print("Exemplo de Producer Kafka com Schema Registry")
    print("=" * 60)
    
    # Cria o tópico
    print("\n1. Criando tópico...")
    create_topic()
    
    # Escolha qual método usar
    print("\n2. Produzindo mensagens...")
    print("\nEscolha o método:")
    print("  [1] Com Schema Avro (recomendado)")
    print("  [2] Mensagens simples JSON (sem schema)")
    
    choice = input("\nDigite sua escolha (1 ou 2, padrão: 1): ").strip() or "1"
    
    if choice == "1":
        produce_messages_with_schema()
    else:
        produce_messages_simple()

