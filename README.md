# MongoDB with Replica Set for Render

Minimal MongoDB 6.0 with single-node replica set, designed for Render deployment.

## Features

- Official `mongo:6.0` image
- Single-node replica set (`rs0`) auto-initialized on startup
- Uses Render's `$PORT` environment variable (defaults to 27017)

## Deployment on Render

1. Create a new **Private Service** on Render
2. Connect this repository, select the `mongodb-only` branch
3. Set environment type to **Docker**
4. Add a **Disk** mounted at `/data/db` for persistence

## Connection String

From other Render services in the same environment:
```
mongodb://mongodb:${PORT}/rocketchat?replicaSet=rs0
```

Replace `mongodb` with your Render service name.
