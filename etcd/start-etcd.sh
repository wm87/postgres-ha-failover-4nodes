#!/bin/sh
set -e

apk add --no-cache ca-certificates curl tar bash

# Download etcd nur wenn noch nicht vorhanden
if [ ! -d "./etcd-v3.5.20-linux-amd64" ]; then
	curl -L https://github.com/etcd-io/etcd/releases/download/v3.5.20/etcd-v3.5.20-linux-amd64.tar.gz | tar xz
fi

# Starte etcd v3
exec ./etcd-v3.5.20-linux-amd64/etcd \
	--initial-advertise-peer-urls "http://$ETCD_NAME:2380" \
	--listen-peer-urls "http://0.0.0.0:2380" \
	--listen-client-urls "http://0.0.0.0:2379" \
	--advertise-client-urls "http://$ETCD_NAME:2379" \
	--initial-cluster etcd1=http://etcd1:2380,etcd2=http://etcd2:2380,etcd3=http://etcd3:2380 \
	--initial-cluster-state new
