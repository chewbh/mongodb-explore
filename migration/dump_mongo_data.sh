#!/bin/bash

############################################################################
# MongoDB migration - dump / backup
############################################################################
# dump entire data from a legacy mongo cluster (e.g. v3.2) database
# leverge on `mongodump` and `mongorestore` with mongodb docker containers

# handles collection data and indexes (including sharded collection)
# dumped data are in json (metadata) and bson (data) files
# db roles and users are not dumped

# connection details to mongo v3.2
MONGO_DOCKER_IMG=docker.io/mongo:3.2
MONGO_HOST=100.115.92.195   # point to mongos instance
MONGO_PORT=27017
MONGO_AUTH_DB=admin
MONGO_USER=root
DATABASE=result

DATA_PATH="$PWD/dump"
DATE_SF=`date "+%Y%m%d"`
DATA_FILENAME="dump.$DATABASE.$DATE_SF.gz"

echo ""
read -s -p "mongo password: " MONGO_PASSWORD
echo ""
echo ""
echo "dumping data from $DATABASE - $MONGO_HOST:$MONGO_PORT..."
sudo docker run -it --rm -v "$DATA_PATH:/dump" \
    $MONGO_DOCKER_IMG \
    mongodump -h $MONGO_HOST:$MONGO_PORT \
    --db=$DATABASE \
    --gzip --archive=/dump/$DATA_FILENAME
#    -u $MONGO_USER -p $MONGO_PASSWORD --authenticationDatabase $MONGO_AUTH_DB \
#    --db=$DATABASE \
#    --gzip --archive=/dump/$DATA_FILENAME

echo "done!"

