# Rocket.Chat deployment Dockerfile
# Uses the official pre-built Rocket.Chat image

FROM rocketchat/rocket.chat:latest

# Environment variables (can be overridden at runtime)
ENV PORT=3000 \
    NODE_ENV=production \
    DEPLOY_METHOD=railway

# Expose the application port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:3000/livez || exit 1

# The base image already has CMD ["node", "main.js"]
