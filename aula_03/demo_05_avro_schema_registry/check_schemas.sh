#!/bin/bash
echo "Listando subjects (tópicos registrados) no Schema Registry:"
curl -X GET http://localhost:8081/subjects | python3 -m json.tool

echo ""
echo "Pegando a última versão do schema 'demo-avro-value':"
curl -X GET http://localhost:8081/subjects/demo-avro-value/versions/latest | python3 -m json.tool

