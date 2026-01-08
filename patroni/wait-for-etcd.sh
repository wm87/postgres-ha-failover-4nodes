#!/bin/bash
# wait-for-etcd.sh
for host in etcd1 etcd2 etcd3; do
    until nc -z $host 2379; do
        echo "Waiting for $host:2379"
        sleep 1
    done
done

# Starte Patroni
exec patroni /patroni/patroni2.yml
