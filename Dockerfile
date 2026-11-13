FROM node:20-alpine

WORKDIR /usr/src/app

# Copy package files first for layer caching
COPY package*.json ./

# Deterministic production-only install
RUN npm ci --only=production

# Copy application source and set ownership to node user
COPY --chown=node:node . .

# Drop root privileges before running the app
USER node

EXPOSE 8080

CMD ["node", "server.js"]
