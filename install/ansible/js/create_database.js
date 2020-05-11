
// enable sharding for database
sh.enableSharding("result")

// switch to sharded database
db = db.getSiblingDB('result')

// create shared collection
db.adminCommand( { shardCollection: "result.jobs", key: { resultId: "hashed" } } )


