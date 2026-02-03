# MongoDB for Rocket.Chat on Render

This directory contains the MongoDB setup configured for Rocket.Chat deployment on Render.

## Features

- **MongoDB 6.0** with single-node replica set (required by Rocket.Chat)
- **Automatic replica set initialization** on startup
- **Health checks** for container orchestration
- **Render-optimized** for private service deployment

## Why Replica Set?

Rocket.Chat requires MongoDB with a replica set for:
- Real-time message delivery via oplog tailing
- Change streams for live updates
- Proper transaction support

## Files

| File | Description |
|------|-------------|
| `Dockerfile` | MongoDB image with replica set support |
| `init-replica-set.sh` | Startup script that initializes the replica set |
| `docker-entrypoint-initdb.d/` | Optional initialization scripts |

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `MONGO_REPLICA_SET_NAME` | `rs0` | Name of the replica set |
| `MONGO_PORT` | `27017` | MongoDB port |
| `ROCKETCHAT_DB` | `rocketchat` | Database name for Rocket.Chat |

## Connection Strings

When deployed on Render, use these connection strings in your Rocket.Chat service:

```
MONGO_URL=mongodb://mongodb:27017/rocketchat?replicaSet=rs0
MONGO_OPLOG_URL=mongodb://mongodb:27017/local?replicaSet=rs0
```

> **Note:** `mongodb` is the service name defined in `render.yaml`. Render's internal DNS resolves this to the private service.

## Local Testing

```bash
# Build the image
docker build -t rocketchat-mongodb ./mongodb

# Run locally
docker run -d \
  --name rocketchat-mongo \
  -p 27017:27017 \
  -v mongodb_data:/data/db \
  rocketchat-mongodb

# Check replica set status
docker exec rocketchat-mongo mongosh --eval "rs.status()"
```

## Health Check

The container includes a health check that verifies:
1. MongoDB is running
2. Replica set is initialized and healthy

```bash
# Check health status
docker inspect --format='{{.State.Health.Status}}' rocketchat-mongo
```

## Persistence

For production use on Render, add a persistent disk to the MongoDB service:

```yaml
disk:
  name: mongodb-data
  mountPath: /data/db
  sizeGB: 10  # Adjust based on your needs
```

## Troubleshooting

### Replica set not initializing
Check the logs: `docker logs rocketchat-mongo`

### Connection refused
Ensure the service is healthy and the replica set is initialized.

### Oplog access issues
The `local` database is automatically available for oplog tailing once the replica set is initialized.
