# MongoDB for Rocket.Chat on Render

This branch contains a standalone MongoDB setup with replica set support, designed for deploying Rocket.Chat on Render.

## Overview

Rocket.Chat requires MongoDB with a replica set enabled for:
- Real-time message delivery via oplog tailing
- Change streams for live updates
- Proper transaction support

This Docker image automatically initializes a single-node replica set on startup.

## Files

| File | Description |
|------|-------------|
| `Dockerfile` | MongoDB 6.0 image with replica set support |
| `init-replica-set.sh` | Startup script that initializes the replica set |
| `docker-entrypoint-initdb.d/` | Optional initialization scripts |

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | `27017` | **Render sets this automatically** (typically 10000 for private services) |
| `MONGO_REPLICA_SET_NAME` | `rs0` | Name of the replica set |
| `ROCKETCHAT_DB` | `rocketchat` | Database name for Rocket.Chat |

## Render Port Configuration

**Important:** Render private services use a platform-assigned port via the `$PORT` environment variable (typically 10000, not 27017). This MongoDB setup automatically uses `$PORT` to comply with Render's networking requirements.

## Deploying on Render

### 1. Create MongoDB Private Service

Create a new **Private Service** on Render:
- **Name:** `mongodb`
- **Repository:** This repo/branch
- **Branch:** `mongodb-only`
- **Root Directory:** (leave empty - files are at root)

### 2. Configure the Service

- **Docker Build:** Render will auto-detect the Dockerfile
- **Port:** Leave as default - the service uses the `$PORT` env var automatically

### 3. Add Persistent Disk (Required for data persistence)

- **Name:** `mongodb-data`
- **Mount Path:** `/data/db`
- **Size:** 10GB (adjust as needed)

### 4. Connection Strings for Rocket.Chat

Use these environment variables in your Rocket.Chat service:

```
MONGO_URL=mongodb://mongodb:10000/rocketchat?replicaSet=rs0
MONGO_OPLOG_URL=mongodb://mongodb:10000/local?replicaSet=rs0
```

> **Note:**
> - `mongodb` is the private service name - Render's internal DNS resolves this automatically
> - Port `10000` is Render's typical private service port (check your service's "Connect" info to confirm)
> - Both services must be in the **same Render region** for private networking to work

### 5. Verify the Port

After deployment, check your MongoDB service's "Connect" section in the Render dashboard to confirm the internal port. Update your Rocket.Chat connection strings if the port differs from 10000.

## Local Testing

```bash
# Build the image
docker build -t rocketchat-mongodb .

# Run locally (uses default port 27017)
docker run -d \
  --name rocketchat-mongo \
  -p 27017:27017 \
  -v mongodb_data:/data/db \
  rocketchat-mongodb

# Or run with a custom port (simulating Render)
docker run -d \
  --name rocketchat-mongo \
  -e PORT=10000 \
  -p 10000:10000 \
  -v mongodb_data:/data/db \
  rocketchat-mongodb

# Check replica set status
docker exec rocketchat-mongo mongosh --port 27017 --eval "rs.status()"

# Test connection string
docker exec rocketchat-mongo mongosh "mongodb://localhost:27017/rocketchat?replicaSet=rs0" --eval "db.stats()"
```

## Health Check

The container includes a health check that verifies:
1. MongoDB is running on `$PORT`
2. Replica set is initialized and healthy

```bash
# Check health status
docker inspect --format='{{.State.Health.Status}}' rocketchat-mongo
```

## Troubleshooting

### Replica set not initializing
Check the logs for errors:
```bash
docker logs rocketchat-mongo
```

### Connection refused from Rocket.Chat
1. Ensure both services are in the **same Render region**
2. Verify the service name matches (`mongodb`)
3. Check the port in Render's "Connect" section matches your connection string
4. Check that the replica set is initialized (health check passing)

### Wrong port in connection string
Render assigns the port dynamically. Check your MongoDB service's dashboard under "Connect" to see the actual internal address and port.

### Data not persisting
Ensure you've attached a persistent disk to `/data/db`
