docker exec -it configSrv1 mongosh --port 27017 --eval "rs.initiate({_id: 'config_server', configsvr: true, members: [{_id: 0, host: 'configSrv1:27017'}, {_id: 1, host: 'configSrv2:27021'}, {_id: 2, host: 'configSrv3:27022'}]})"

docker exec -it shard1a mongosh --port 27018 --eval "rs.initiate({_id: 'shard1', members: [{_id: 0, host: 'shard1a:27018'}, {_id: 1, host: 'shard1b:27023'}, {_id: 2, host: 'shard1c:27024'}]})"

docker exec -it shard2a mongosh --port 27019 --eval "rs.initiate({_id: 'shard2', members: [{_id: 0, host: 'shard2a:27019'}, {_id: 1, host: 'shard2b:27025'}, {_id: 2, host: 'shard2c:27026'}]})"
