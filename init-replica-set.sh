#!/bin/bash
set -e

# MongoDB Replica Set Initialization Script for Render
# This script starts MongoDB with replica set configuration and initializes it

REPLICA_SET_NAME="${MONGO_REPLICA_SET_NAME:-rs0}"
MONGO_PORT="${MONGO_PORT:-27017}"

echo "=========================================="
echo "Starting MongoDB with Replica Set: $REPLICA_SET_NAME"
echo "Port: $MONGO_PORT"
echo "=========================================="

# Ensure data directory exists and has correct permissions
mkdir -p /data/db /data/configdb /var/log/mongodb
chown -R mongodb:mongodb /data 2>/dev/null || true

# Start MongoDB in the background with replica set enabled
# Using foreground logging to stdout for container compatibility
echo "Starting mongod process..."
mongod --replSet "$REPLICA_SET_NAME" --bind_ip_all --port "$MONGO_PORT" --dbpath /data/db &
MONGOD_PID=$!

# Give mongod a moment to start
sleep 2

# Check if mongod started successfully
if ! kill -0 $MONGOD_PID 2>/dev/null; then
    echo "ERROR: mongod failed to start"
    exit 1
fi

# Wait for MongoDB to start accepting connections
echo "Waiting for MongoDB to accept connections..."
MAX_TRIES=60
TRIES=0
until mongosh --quiet --port "$MONGO_PORT" --eval "db.adminCommand('ping')" > /dev/null 2>&1; do
    TRIES=$((TRIES + 1))
    if [ $TRIES -ge $MAX_TRIES ]; then
        echo "ERROR: MongoDB failed to start within $MAX_TRIES seconds"
        exit 1
    fi

    # Check if mongod is still running
    if ! kill -0 $MONGOD_PID 2>/dev/null; then
        echo "ERROR: mongod process died unexpectedly"
        exit 1
    fi

    echo "Waiting for MongoDB... ($TRIES/$MAX_TRIES)"
    sleep 1
done

echo "MongoDB is accepting connections"

# Check if replica set is already initialized
RS_STATUS=$(mongosh --quiet --port "$MONGO_PORT" --eval "try { rs.status().ok } catch(e) { 0 }" 2>/dev/null || echo "0")

if [ "$RS_STATUS" != "1" ]; then
    echo "Initializing replica set '$REPLICA_SET_NAME'..."

    # Initialize single-node replica set
    # Using localhost for single-node setup on Render
    INIT_RESULT=$(mongosh --quiet --port "$MONGO_PORT" --eval "
        var config = {
            _id: '$REPLICA_SET_NAME',
            members: [
                {
                    _id: 0,
                    host: 'localhost:$MONGO_PORT',
                    priority: 1
                }
            ]
        };
        var result = rs.initiate(config);
        printjson(result);
    " 2>&1)

    echo "Replica set init result: $INIT_RESULT"

    # Wait for replica set to be ready
    echo "Waiting for replica set to initialize..."
    MAX_TRIES=60
    TRIES=0
    until mongosh --quiet --port "$MONGO_PORT" --eval "rs.status().myState" 2>/dev/null | grep -q "1"; do
        TRIES=$((TRIES + 1))
        if [ $TRIES -ge $MAX_TRIES ]; then
            echo "ERROR: Replica set failed to initialize within $MAX_TRIES seconds"
            mongosh --quiet --port "$MONGO_PORT" --eval "printjson(rs.status())" 2>/dev/null || true
            exit 1
        fi
        echo "Waiting for replica set to become PRIMARY... ($TRIES/$MAX_TRIES)"
        sleep 1
    done

    echo "=========================================="
    echo "Replica set '$REPLICA_SET_NAME' initialized successfully!"
    echo "=========================================="
else
    echo "Replica set '$REPLICA_SET_NAME' already initialized"
fi

# Print replica set status
echo "Replica Set Status:"
mongosh --quiet --port "$MONGO_PORT" --eval "printjson(rs.status())" || true

# Run any initialization scripts in /docker-entrypoint-initdb.d/
if [ -d "/docker-entrypoint-initdb.d" ]; then
    for f in /docker-entrypoint-initdb.d/*.sh; do
        if [ -f "$f" ]; then
            echo "Running $f..."
            . "$f"
        fi
    done
    for f in /docker-entrypoint-initdb.d/*.js; do
        if [ -f "$f" ]; then
            echo "Running $f..."
            mongosh --quiet --port "$MONGO_PORT" "$f"
        fi
    done
fi

echo "=========================================="
echo "MongoDB is ready for connections"
echo "Connection string: mongodb://localhost:$MONGO_PORT/?replicaSet=$REPLICA_SET_NAME"
echo "=========================================="

# Keep the script running (wait for mongod process)
wait $MONGOD_PID
