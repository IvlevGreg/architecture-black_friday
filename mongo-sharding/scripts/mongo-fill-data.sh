#!/bin/bash

###
# Инициализируем бд
###

echo "1. Добавляем шарды и настраиваем шардинг..."
docker exec mongo-sharding mongosh --port 27020 --quiet --eval "
  // Добавляем шарды
  sh.addShard('shard1/shard1:27018');
  sh.addShard('shard2/shard2:27019');

  // Настраиваем шардинг
  sh.enableSharding('somedb');
  sh.shardCollection('somedb.helloDoc', { 'name' : 'hashed' });

  // Вставляем тестовые данные
  db = db.getSiblingDB('somedb');
  for(let i = 0; i < 1000; i++) {
    db.helloDoc.insertOne({age:i, name:'ly'+i});
  }

  print('Всего документов в кластере:', db.helloDoc.countDocuments());
"

echo "2. Проверяем количество документов на шарде 1..."
docker exec shard1 mongosh --port 27018 --quiet --eval "
  db = db.getSiblingDB('somedb');
  print('Документов на shard1:', db.helloDoc.countDocuments());
"

echo "3. Проверяем количество документов на шарде 2..."
docker exec shard2 mongosh --port 27019 --quiet --eval "
  db = db.getSiblingDB('somedb');
  print('Документов на shard2:', db.helloDoc.countDocuments());
"

echo "Инициализация завершена!"
