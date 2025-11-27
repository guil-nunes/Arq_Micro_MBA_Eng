from confluent_kafka import Consumer
from confluent_kafka.schema_registry import SchemaRegistryClient
from confluent_kafka.schema_registry.avro import AvroDeserializer
from confluent_kafka.serialization import SerializationContext, MessageField

schema_registry_conf = {'url': 'http://localhost:8081'}
schema_registry_client = SchemaRegistryClient(schema_registry_conf)

# O Deserializer baixa o schema pelo ID que vem na mensagem
avro_deserializer = AvroDeserializer(schema_registry_client)

consumer_conf = {
    'bootstrap.servers': 'localhost:9092',
    'group.id': 'avro-consumer-group',
    'auto.offset.reset': 'earliest'
}

consumer = Consumer(consumer_conf)
consumer.subscribe(['demo-avro'])

print("Consumidor Avro iniciado...")

while True:
    try:
        msg = consumer.poll(1.0)
        if msg is None: continue
        
        # Desserialização acontece aqui
        user = avro_deserializer(msg.value(), SerializationContext(msg.topic(), MessageField.VALUE))
        
        if user is not None:
            print(f"Recebido: {user}")
    except Exception as e:
        print(f"Erro na desserialização: {e}")

