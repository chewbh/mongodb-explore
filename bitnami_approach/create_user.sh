db.getSiblingDB("admin").createUser({
    user: "mongodb_exporter",
    pwd: "s3cR#tpa$$worD",
    roles: [
        { role: "clusterMonitor", db: "admin" },
        { role: "read", db: "local" }
    ]
})