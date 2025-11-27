# Demo 3: Estratégias de Particionamento

Esta demo ilustra a diferença fundamental entre produzir mensagens com e sem chave (key).

## Conceito
- **Sem chave (Key=None)**: O Kafka distribui as mensagens usando **Round-Robin** (ou Sticky Partitioning), equilibrando a carga entre todas as partições.
- **Com chave (Key != None)**: O Kafka usa um hash da chave (`hash(key) % num_partitions`) para garantir que **todas as mensagens com a mesma chave vão para a mesma partição**. Isso garante ordenação para aquela entidade.

## Roteiro

### 1. Criar Tópico
```bash
docker exec kafka kafka-topics --create \
    --topic demo-producers \
    --bootstrap-server localhost:9092 \
    --partitions 4 \
    --replication-factor 1
```

### 2. Produção Sem Chave (Round-Robin)
Execute o script que envia mensagens sem chave:
```bash
python producer_without_key.py
```
*Saída esperada:* Você verá mensagens sendo distribuídas para Partição 0, 1, 2, 3 de forma equilibrada.

### 3. Produção Com Chave (Ordering)
Execute o script que envia mensagens simulando IDs de usuários (ex: `user_123`, `user_456`):
```bash
python producer_with_key.py
```
*Saída esperada:*
- Todas as mensagens do `user_123` cairão sempre na mesma partição (ex: Partição 2).
- Todas as do `user_456` cairão em outra (ex: Partição 0).
Isso garante que eventos de um mesmo usuário sejam consumidos na ordem correta.

