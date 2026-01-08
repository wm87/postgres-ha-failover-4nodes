[![Docker](https://img.shields.io/badge/Docker-29.1.3-blue?logo=docker)](https://www.docker.com/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-18-blue?logo=postgresql)](https://www.postgresql.org/)
[![Patroni](https://img.shields.io/badge/Patroni-4.1.0-orange)](https://patroni.readthedocs.io/)
[![Etcd](https://img.shields.io/badge/Etcd-3.5.20-lightgrey)](https://etcd.io/)
[![HAProxy](https://img.shields.io/badge/HAProxy-3.3.1-red)](https://www.haproxy.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

# PostgreSQL High Availability Cluster mit Patroni, Etcd und HAProxy - WIP


## Übersicht

Dieses Projekt demonstriert einen hochverfügbaren PostgreSQL-Cluster, der speziell für Szenarien entwickelt wurde, in denen Ausfallsicherheit und kontinuierliche Verfügbarkeit der Datenbank kritisch sind.

Der Cluster nutzt **Patroni**, um automatisch einen Leader unter den PostgreSQL-Knoten zu wählen und ein Failover im Fehlerfall zu gewährleisten. **Etcd** dient dabei als verteiltes Konsenssystem, das den Clusterstatus überwacht und dafür sorgt, dass Entscheidungen wie Leader Election zuverlässig getroffen werden. **HAProxy** übernimmt die Rolle des Load Balancers und leitet Client-Anfragen intelligent an den aktuellen Leader für Schreiboperationen oder an die Replikate für Leseoperationen weiter.

Dieses Setup eignet sich für Entwicklungs-, Test- und Produktionsumgebungen, in denen Hochverfügbarkeit, automatische Replikation und minimierte Ausfallzeiten gefordert sind. Zusätzlich wird in dieser Dokumentation erklärt, warum bestimmte Knotenzahlen (z.B. 4 PostgreSQL-Knoten, 3 Etcd-Knoten) gewählt wurden, wie Quorum berechnet wird und welche Best Practices für den Betrieb gelten.

## 🛠 Work in Progress

* Dynamische Leader-Erkennung
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
                  |  Node 1|     |  Node 2|     |  Node 3|     | Node 4 |
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

* **4 PostgreSQL-Knoten** (patroni1–patroni4) laufen als Docker-Container.

  * **Warum 4 Knoten?** Drei Knoten reichen für Hochverfügbarkeit, ein zusätzlicher Knoten bietet mehr Redundanz und Lastverteilung.
* **3 Etcd-Knoten** (etcd1–etcd3) für verteilten Konsens.

  * **Warum 3 Etcd-Knoten?** Etcd benötigt eine ungerade Anzahl von Knoten, um Quorum zu erreichen.
* **Quorum**: Die Mehrheit der Etcd-Knoten muss zustimmen, damit Entscheidungen wie Leader Election durchgeführt werden. Dies verhindert Split-Brain-Situationen.

### Quorum-Berechnung

Quorum = ⌊N/2⌋ + 1

> Hinweis: Das Symbol ⌊ ⌋ bedeutet "Abrunden". Zum Beispiel: ⌊2.5⌋ = 2.

| Anzahl Etcd-Knoten (N) | Quorum (⌊N/2⌋+1) | Max. Ausfälle erlaubt |
| ---------------------- | ---------------- | --------------------- |
| 1                      | 1                | 0                     |
| 3                      | 2                | 1                     |
| 5                      | 3                | 2                     |
| 7                      | 4                | 3                     |

*Beispiel:* Bei 3 Etcd-Knoten müssen mindestens 2 Knoten online sein, damit das Cluster funktionsfähig bleibt. Fällt ein Knoten aus, bleibt das Quorum erhalten, und Patroni kann weiterhin den Leader wählen.

* **Patroni** koordiniert die Knoten, übernimmt Leader Election und Replikationsmanagement.
* **HAProxy** verteilt Lese-/Schreibanfragen an den Leader und Leseanfragen an Replikate.

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

## 📜 Lizenz

MIT
