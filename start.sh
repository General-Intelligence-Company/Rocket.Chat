#!/bin/bash
set -e

MONGO_PORT="${PORT:-27017}"

# Start mongod in background with replica set
mongod --replSet rs0 --bind_ip_all --port $MONGO_PORT --dbpath /data/db &
MONGOD_PID=$!

# Wait for MongoDB to be ready
echo "Waiting for MongoDB to start..."
until mongosh --port $MONGO_PORT --eval "db.adminCommand('ping')" &>/dev/null; do
  sleep 1
done

# Initialize replica set (ignore if already initialized)
echo "Initializing replica set..."
mongosh --port $MONGO_PORT --eval "
  try {
    rs.status();
    print('Replica set already initialized');
  } catch(e) {
    rs.initiate({_id: 'rs0', members: [{_id: 0, host: 'localhost:$MONGO_PORT'}]});
    print('Replica set initialized');
  }
"

echo "MongoDB replica set ready on port $MONGO_PORT"

# Wait for mongod process
wait $MONGOD_PID
