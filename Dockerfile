# Ultra-simple Rocket.Chat Dockerfile for Render
FROM rocketchat/rocket.chat:latest

# No custom health checks - let Render handle it
# No PORT override - Rocket.Chat reads PORT from env

# That's it - the official image handles everything
