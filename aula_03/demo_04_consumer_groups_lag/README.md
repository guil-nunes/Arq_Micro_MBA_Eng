# Demo 4: Consumer Groups, Lag e Escalabilidade

Esta demo explora o conceito mais poderoso do Kafka: **Consumer Groups**.
Você verá como múltiplos consumidores dividem o trabalho e como o **Lag** indica se o processamento está acompanhando a produção.

## Roteiro

### 1. Criar Tópico
```bash
docker exec kafka kafka-topics --create \
    --topic demo-groups \
    --bootstrap-server localhost:9092 \
    --partitions 4
```

### 2. Gerar Carga (Fast Producer)
Vamos enviar 10.000 mensagens rapidamente para criar um acúmulo:
```bash
python fast_producer.py
```

### 3. Consumidor Lento (Gerando Lag)
Inicie um consumidor que propositalmente processa devagar (simulando trabalho pesado):
```bash
python slow_consumer.py
```
*Enquanto ele roda, abra outro terminal e verifique o Lag:*
```bash
bash check_lag.sh
```
Ou veja no **Kafka UI**. Você verá o Lag crescendo ou diminuindo muito lentamente.

### 4. Escalando (Adicionando Consumidores)
Sem parar o primeiro consumidor, abra novos terminais e rode:
```bash
python consumer_group_1.py
```
E em outro terminal:
```bash
python consumer_group_2.py
```
*Observe os logs:* O Kafka fará um **Rebalance**. As partições serão redistribuídas entre os 3 consumidores ativos (slow + group_1 + group_2).
O Lag começará a cair muito mais rápido.

### 5. Tolerância a Falhas
Derrube um dos consumidores (Ctrl+C).
*Observe:* O Kafka detecta a saída e redistribui as partições dele para os sobreviventes.

