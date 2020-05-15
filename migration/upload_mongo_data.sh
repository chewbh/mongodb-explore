#!/bin/bash

############################################################################
# MongoDB migration - restore / upload
############################################################################
# dump entire data from a legacy mongo cluster (e.g. v3.2) database
# leverge on `mongodump` and `mongorestore` with mongodb docker containers

# handles collection data and indexes (including sharded collection)
# dumped data are in json (metadata) and bson (data) files
# db roles and users are not dumped

# connection details to mongo v3.2
MONGO_DOCKER_IMG=docker.io/mongo:4.2
MONGO_HOST=178.128.115.52   # point to mongos instance
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
echo "uploading data to $DATABASE - $MONGO_HOST:$MONGO_PORT..."
sudo docker run -it --rm -v "$DATA_PATH:/dump" \
    $MONGO_DOCKER_IMG \
    mongorestore -h $MONGO_HOST:$MONGO_PORT \
    --gzip --archive=/dump/$DATA_FILENAME \
    -u $MONGO_USER -p $MONGO_PASSWORD --authenticationDatabase $MONGO_AUTH_DB \
    --nsInclude=$(echo "'$DATABASE.*'") \
    --gzip --archive=/dump/$DATA_FILENAME

echo "done!"
