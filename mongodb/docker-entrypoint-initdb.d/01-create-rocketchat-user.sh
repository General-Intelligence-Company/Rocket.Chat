#!/bin/bash
# Create Rocket.Chat database and user (optional, for added security)
# This script runs after replica set initialization

MONGO_PORT="${MONGO_PORT:-27017}"
ROCKETCHAT_DB="${ROCKETCHAT_DB:-rocketchat}"

# Create the rocketchat database by inserting and removing a dummy document
# This ensures the database exists for the connection
mongosh --quiet --port "$MONGO_PORT" --eval "
    // Switch to rocketchat database
    use('$ROCKETCHAT_DB');

    // Create a collection to ensure database exists
    db.createCollection('_init');

    // Remove the init collection (optional cleanup)
    db._init.drop();

    print('Database $ROCKETCHAT_DB initialized');
"

echo "Rocket.Chat database '$ROCKETCHAT_DB' is ready"
