# Rocket.Chat deployment Dockerfile
# Uses the official pre-built Rocket.Chat image

FROM rocketchat/rocket.chat:latest

# Environment variables
# NOTE: Do NOT set PORT here - let Render provide it (typically 10000)
ENV NODE_ENV=production \
    DEPLOY_METHOD=render

# Health check using the PORT env var that Render provides
# Use shell form (CMD with /bin/sh -c) to enable variable expansion
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD /bin/sh -c 'wget --no-verbose --tries=1 --spider http://localhost:${PORT:-3000}/health || exit 1'

# The base image already has CMD ["node", "main.js"]
# Rocket.Chat reads PORT from environment and listens on it
