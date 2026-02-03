# MongoDB with Replica Set for Rocket.Chat on Render
# This creates a single-node replica set suitable for Render private services

FROM mongo:6.0

# Copy initialization scripts
COPY init-replica-set.sh /init-replica-set.sh
COPY docker-entrypoint-initdb.d/ /docker-entrypoint-initdb.d/

# Make scripts executable and ensure proper line endings
RUN chmod +x /init-replica-set.sh && \
    chmod +x /docker-entrypoint-initdb.d/*.sh 2>/dev/null || true && \
    sed -i 's/\r$//' /init-replica-set.sh && \
    sed -i 's/\r$//' /docker-entrypoint-initdb.d/*.sh 2>/dev/null || true

# Create data directory and set permissions
RUN mkdir -p /data/db /data/configdb && \
    chown -R mongodb:mongodb /data

# Default port - Render will override with $PORT env var (typically 10000)
ENV PORT=27017

# Health check - verify MongoDB is running and replica set is initialized
# Uses $PORT which Render sets for private services
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=5 \
    CMD mongosh --port $PORT --quiet --eval "db.adminCommand({ replSetGetStatus: 1 }).ok" | grep -q 1 || exit 1

# Use custom entrypoint that initializes replica set
ENTRYPOINT ["/bin/bash", "/init-replica-set.sh"]
