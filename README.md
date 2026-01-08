# PostgreSQL High Availability Cluster mit Patroni, Etcd und HAProxy - WIP

## Übersicht

Dieses Projekt demonstriert einen hochverfügbaren PostgreSQL-Cluster mit Patroni für automatisches Failover, Etcd für verteilten Konsens und HAProxy für Load Balancing und Client-Verbindungsmanagement.

## 🛠 work in progress

* dynamische Leader-Erkennung
* Schreib-Queries gehen automatisch an den Leader


## Architektur

```text
          +----------------+           +----------------+           +----------------+
          |     Etcd1      |           |     Etcd2      |           |     Etcd3      |
          +----------------+           +----------------+           +----------------+
                  |                            |                            |
                  -----------------------------------------------------------
                                     Cluster-Status
                                              |
                       ----------------------------------------------
                       |              |              |              |
                  +--------+     +--------+     +--------+     +--------+
                  | Patroni|     | Patroni|     | Patroni|     | Patroni|
                  |  Node 1|     |  Node 2|     |  Node 3|     |  Node 4|
                  +--------+     +--------+     +--------+     +--------+
                       |              |              |              |
                       |              |              |              |
                       ---------------- HAProxy ---------------------
                                      (Read/Write Routing)
```

### Komponenten

* **PostgreSQL**: Relationales Datenbanksystem, ausgeführt auf mehreren Knoten.
* **Patroni**: Verwalten der PostgreSQL-Knoten für automatisches Failover und Leader Election.
* **Etcd**: Verteilter Key-Value-Store für Clusterzustand und Leader Election.
* **HAProxy**: Load Balancer, der Anfragen an den aktuellen Leader oder die Replikate weiterleitet.

### Architekturdetails

* 4 PostgreSQL-Knoten (patroni1–patroni4) laufen als Docker-Container.
* Etcd-Cluster (etcd1–etcd3) stellt verteilten Konsens bereit.
* Patroni koordiniert die Knoten, übernimmt Leader Election und Replikationsmanagement.
* HAProxy verteilt Lese-/Schreibanfragen an den Leader und Leseanfragen an Replikate.

## Funktionalität

* **Automatisches Failover**: Fällt der Leader aus, wird automatisch ein Replikat zum Leader befördert.
* **Streaming-Replikation**: Replikate synchronisieren Daten kontinuierlich vom Leader.
* **Health Checks**: HAProxy stellt sicher, dass nur gesunde Knoten Anfragen bedienen.
* **Persistenter Speicher**: Docker-Volumes speichern Daten, sodass Container-Neustarts unkritisch sind.

## Schritt-für-Schritt Anleitung

1. **Cluster starten**

   ```bash
   docker-compose up -d
   ```
2. **Cluster-Mitglieder überprüfen**

   ```bash
   docker exec -it patroni2 patronictl -c /patroni/patroni.yml list
   ```
3. **Fehlgeschlagene Knoten reinitialisieren**

   ```bash
   docker exec -it patroni2 patronictl -c /patroni/patroni.yml reinit postgres patroni1
   ```
4. **Replikationsstatus prüfen**

   ```bash
   docker exec -it patroni2 psql -U postgres -c "SELECT now(), pg_is_in_recovery();"
   ```
5. **Logs überwachen**

   ```bash
   docker logs -f patroni2
   ```

## Best Practices

* Immer sichere Passwörter für PostgreSQL-Benutzer verwenden.
* `pg_hba.conf` korrekt für Replikation konfigurieren.
* Etcd-Cluster überwachen, damit Patroni Leader Election durchführen kann.
* Docker-Volumes für persistente PostgreSQL-Daten verwenden.

## Zusammenfassung

Dieses Setup bietet einen robusten PostgreSQL-HA-Cluster, der sich für Produktionsumgebungen eignet. Automatisches Failover, Echtzeit-Replikation und Hochverfügbarkeit für Lese- und Schreibzugriffe sorgen für Ausfallsicherheit und vereinfachen den Betrieb.

---

## 📜 Lizenz

MIT
