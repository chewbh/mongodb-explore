#!/bin/bash

if [ -z "$DB_PASSWORD" ]
then
    PASSWORD=""
else
    PASSWORD="--password $DB_PASSWORD"
fi

if [ -z "$DB_CLUSTER_NAME" ]
then
    CLUSTER_NAME=""
else
    CLUSTER_NAME="--cluster $DB_CLUSTER_NAME"
fi

echo "sleep for ${POST_ACTION_WAIT_SEC:-'5s'} for pmm-agent to be started up"
sleep ${POST_ACTION_WAIT_SEC:-'5s'}

if [ -z "$POST_ACTION_DEBUG" ]
then
    echo "run registeration now"
else
    echo pmm-admin add \
        ${DB_TYPE:-'mongodb'} \
        --username ${DB_USERNAME:-'root'} $PASSWORD \
        $CLUSTER_NAME \
        $DB_ARGS \
        $SERVICE_NAME \
        ${DB_ADDRESS:-'localhost:27017'} > /tmp/test
fi

pmm-admin add \
    ${DB_TYPE:-'mongodb'} \
    --username ${DB_USERNAME:-'root'} $PASSWORD \
    $CLUSTER_NAME \
    $DB_ARGS \
    $SERVICE_NAME \
    ${DB_ADDRESS:-'localhost:27017'}