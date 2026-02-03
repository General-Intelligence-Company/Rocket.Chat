# MongoDB with Replica Set for Rocket.Chat on Render
# This creates a single-node replica set suitable for Render private services

FROM mongo:6.0

# Copy initialization scripts
COPY docker-entrypoint-initdb.d/ /docker-entrypoint-initdb.d/
COPY init-replica-set.sh /init-replica-set.sh

# Make scripts executable
RUN chmod +x /init-replica-set.sh && \
    chmod +x /docker-entrypoint-initdb.d/*.sh 2>/dev/null || true

# Create data directory and set permissions
RUN mkdir -p /data/db /data/configdb && \
    chown -R mongodb:mongodb /data

# Expose MongoDB port
EXPOSE 27017

# Health check - verify MongoDB is running and replica set is initialized
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=5 \
    CMD mongosh --quiet --eval "try { rs.status().ok } catch(e) { 0 }" | grep -q 1 || exit 1

# Use custom entrypoint that initializes replica set
ENTRYPOINT ["/init-replica-set.sh"]
