FROM node:20-alpine

# FIXED: Forces the container runtime and OS layers to handle UTF-8 text encoding natively
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

WORKDIR /app

COPY package*.json ./
RUN npm install --production

COPY server.js ./

EXPOSE 8080

CMD ["node", "server.js"]
