#!/bin/bash
# Wait until all etcd nodes are available

for host in etcd1 etcd2 etcd3; do
    until nc -z $host 2379; do
        echo "Waiting for $host:2379"
        sleep 1
    done
done

# Start Patroni
exec patroni /patroni/patroni.yml
