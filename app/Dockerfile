FROM oven/bun:1-alpine

RUN apk add --no-cache curl postgresql-client bash

WORKDIR /app

COPY package.json ./
RUN bun install

COPY src/ ./src/

EXPOSE 8080 9090

CMD ["bun", "run", "start"]
