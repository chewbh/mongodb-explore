# Exploration on Sharded MongoDB Cluster

This repository is for exploring various IaaC approach for a sharded mongodb cluster setup. The goal is to eventually a production grade cluster in a air-gapped environment.

The exploration is done on digital ocean with CentOS based droplets

## Principal Consideration

- Ease of maintenance using docker
- Support for sharded cluster with each shard being a replica set
- Ease of scaling by easy to add new shard or new instance to a replica set
- Production ready
  - Largely secured

## Exploration

### Docker Image to Explore

- offical mongodb
- bitnami mongodb
- percona mongodb

### Monitoring

- PMM Server (can manually add from web UI or via pmm-client)
- custom pmm-client to auto add mongodb exporter and QAN integration

## Migration Approach
