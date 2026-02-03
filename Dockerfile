# Rocket.Chat deployment Dockerfile
# Uses the official pre-built Rocket.Chat image

FROM rocketchat/rocket.chat:latest

# Environment variables
# NOTE: Do NOT set PORT here - let Render provide it (typically 10000)
ENV NODE_ENV=production \
    DEPLOY_METHOD=render

# Health check using the PORT env var that Render provides
# Rocket.Chat takes 2-3+ minutes to fully start, so we use generous timing:
# - start-period: 300s (5 min) - grace period before health checks count as failures
# - interval: 60s - time between checks
# - timeout: 30s - max time to wait for response
# - retries: 3 - number of consecutive failures before unhealthy
# Using /api/info endpoint - it's lightweight and returns quickly once the server is up
HEALTHCHECK --interval=60s --timeout=30s --start-period=300s --retries=3 \
    CMD /bin/sh -c 'wget --no-verbose --tries=1 --spider http://localhost:${PORT:-3000}/api/info || exit 1'

# The base image already has CMD ["node", "main.js"]
# Rocket.Chat reads PORT from environment and listens on it
