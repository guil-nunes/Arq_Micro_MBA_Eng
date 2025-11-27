from confluent_kafka import Producer
from confluent_kafka.schema_registry import SchemaRegistryClient
from confluent_kafka.schema_registry.avro import AvroSerializer
from confluent_kafka.serialization import SerializationContext, MessageField

schema_registry_conf = {'url': 'http://localhost:8081'}
schema_registry_client = SchemaRegistryClient(schema_registry_conf)

with open("schemas/user_v1.avsc") as f:
    schema_str = f.read()

avro_serializer = AvroSerializer(schema_registry_client, schema_str)

producer_conf = {'bootstrap.servers': 'localhost:9092'}
producer = Producer(producer_conf)

topic = 'demo-avro'

def delivery_report(err, msg):
    if err is not None:
        print(f"Falha: {err}")
    else:
        print(f"Enviado V1: {msg.value()}")

print("Produzindo users V1...")
users = [
    {"id": 1, "name": "Alice", "email": "alice@test.com"},
    {"id": 2, "name": "Bob", "email": "bob@test.com"}
]

for user in users:
    producer.produce(topic=topic, 
                     value=avro_serializer(user, SerializationContext(topic, MessageField.VALUE)), 
                     callback=delivery_report)
    producer.poll(0)

producer.flush()

