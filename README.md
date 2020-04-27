Exploration for MongoDB Sharded Cluster
========================================

Principal Consideration
- Ease of maintenance using docker
- Support for sharded cluster with each shard being a replica set
- Ease of scaling by easy to add new shard or new instance to a replica set
- Production ready
    - Largely secured

Docker Image to Explore
- offical mongodb
- bitnami mongodb
- percona mongodb

Monitoring
- PMM Server (can manually add from web UI or via pmm-client)
- custom pmm-client to auto add mongodb exporter and QAN integration

Migration Approach

