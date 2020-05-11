
//create user admin (enter password to set when prompt)
db = db.getSiblingDB('admin');
db.createUser(
  {
    user: "useradmin",
    pwd: passwordPrompt(),
    roles: [ { role: "userAdminAnyDatabase", db: "admin" }, "readWriteAnyDatabase" ]
  }
);


// create user account for cluster monitoring
db.createUser(
  {
    user: "monit",
    pwd: passwordPrompt(),
    roles: [ { role: "clusterMonitor", db: "admin" } ]
  }
);

// create with access to view and do sharding on database
db = db.getSiblingDB('result')
db.createRole(
   {
     role: "sharduser",
     privileges: [ { 
       resource: { db: "result", collection: "" }, 
       actions: [ "enableSharding" ] } ],
     roles: [ { role: "readWrite", db: "result" } ]
   }
)

// service account
db.createUser(
  {
    user: "resultusr",
    pwd:  passwordPrompt(),
    roles: [ { role: "sharduser", db: "result" } ]
  }
)


