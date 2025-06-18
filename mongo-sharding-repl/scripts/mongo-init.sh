# Инициализация config-сервера
docker exec -it configSrv mongosh --port 27017 --eval "rs.initiate({_id: 'config_server', configsvr: true, members: [{_id: 0, host: 'configSrv:27017'}]})"

# Инициализация шардов
docker exec -it shard1 mongosh --port 27018 --eval "rs.initiate({_id: 'shard1', members: [{_id: 0, host: 'shard1:27018'}]})"
docker exec -it shard2 mongosh --port 27019 --eval "rs.initiate({_id: 'shard2', members: [{_id: 0, host: 'shard2:27019'}]})"

# Добавление шардов через mongos (обновляем имя контейнера)
docker exec -it mongo-sharding mongosh --port 27020 --eval "sh.addShard('shard1/shard1:27018'); sh.addShard('shard2/shard2:27019')"
