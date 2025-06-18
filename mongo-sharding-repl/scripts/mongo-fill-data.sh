#!/bin/bash

###
# Инициализируем бд с учетом реплицированных шардов
###

echo "1. Инициализируем конфигурационный сервер (replica set)..."
docker exec configSrv1 mongosh --port 27017 --quiet --eval "
  // Ждем инициализации replica set
  sleep(1000);
  rs.initiate({
    _id: 'config_server',
    configsvr: true,
    members: [
      {_id: 0, host: 'configSrv1:27017'},
      {_id: 1, host: 'configSrv2:27021'},
      {_id: 2, host: 'configSrv3:27022'}
    ]
  });
"

echo "2. Инициализируем шард1 (replica set)..."
docker exec shard1a mongosh --port 27018 --quiet --eval "
  // Ждем инициализации replica set
  sleep(1000);
  rs.initiate({
    _id: 'shard1',
    members: [
      {_id: 0, host: 'shard1a:27018', priority: 2},
      {_id: 1, host: 'shard1b:27023', priority: 1},
      {_id: 2, host: 'shard1c:27024', priority: 1, arbiterOnly: true}
    ]
  });
"

echo "3. Инициализируем шард2 (replica set)..."
docker exec shard2a mongosh --port 27019 --quiet --eval "
  // Ждем инициализации replica set
  sleep(1000);
  rs.initiate({
    _id: 'shard2',
    members: [
      {_id: 0, host: 'shard2a:27019', priority: 2},
      {_id: 1, host: 'shard2b:27025', priority: 1},
      {_id: 2, host: 'shard2c:27026', priority: 1, arbiterOnly: true}
    ]
  });
"

echo "4. Ждем стабилизации репликационных наборов..."
sleep 10

echo "5. Добавляем шарды в кластер через mongos..."
docker exec mongo-sharding mongosh --port 27020 --quiet --eval "
  // Добавляем шарды с указанием полного состава их реплик
  sh.addShard('shard1/shard1a:27018,shard1b:27023,shard1c:27024');
  sh.addShard('shard2/shard2a:27019,shard2b:27025,shard2c:27026');

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

echo "6. Проверяем количество документов на репликах шарда 1..."
docker exec shard1a mongosh --port 27018 --quiet --eval "
  db = db.getSiblingDB('somedb');
  print('Документов на shard1 primary:', db.helloDoc.countDocuments());
"
docker exec shard1b mongosh --port 27023 --quiet --eval "
  db = db.getSiblingDB('somedb');
  print('Документов на shard1 secondary:', db.helloDoc.countDocuments());
"

echo "7. Проверяем количество документов на репликах шарда 2..."
docker exec shard2a mongosh --port 27019 --quiet --eval "
  db = db.getSiblingDB('somedb');
  print('Документов на shard2 primary:', db.helloDoc.countDocuments());
"
docker exec shard2b mongosh --port 27025 --quiet --eval "
  db = db.getSiblingDB('somedb');
  print('Документов на shard2 secondary:', db.helloDoc.countDocuments());
"

echo "Инициализация завершена!"
