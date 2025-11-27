# Demo 5: Avro e Schema Registry

Esta demo ensina como usar **Schemas** para garantir a integridade dos dados e evoluir contratos sem quebrar consumidores.

## Por que usar Avro?
1. **Compactação**: Mensagens binárias menores que JSON.
2. **Contrato**: O producer só consegue enviar se respeitar o schema.
3. **Evolução**: Podemos adicionar campos sem quebrar consumers antigos (Backward Compatibility).

## Roteiro

### 1. Criar Tópico
```bash
docker exec kafka kafka-topics --create \
    --topic demo-avro \
    --bootstrap-server localhost:9092 \
    --partitions 1
```

### 2. Produzir Versão 1 (Nome e Email)
O script abaixo registra o schema `user-value` (v1) e envia dados.
```bash
python producer_avro_v1.py
```

### 3. Consumir Dados
O consumidor baixará o schema automaticamente do Registry para desserializar:
```bash
python consumer_avro.py
```
*Deixe rodando.*

### 4. Evoluir Schema (Versão 2)
Vamos adicionar um campo `idade` com valor default (garantindo compatibilidade).
```bash
python producer_avro_v2.py
```
*Observe no consumidor:* Ele conseguirá ler as novas mensagens v2 sem erro, e se chegarem mensagens v1 antigas, ele também lerá (usando o default para o campo novo).

### 5. Verificar Schemas
Liste os schemas registrados no Schema Registry:
```bash
bash check_schemas.sh
```

