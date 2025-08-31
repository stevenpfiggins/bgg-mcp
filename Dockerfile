# Multi-stage Dockerfile for building and running the bgg-mcp MCP server

########################
# Build stage
########################
FROM node:20-bullseye-slim AS build
WORKDIR /app

# Copy dependency manifests first for better layer caching
COPY package*.json ./
COPY tsconfig.json ./

# Install all deps (including devDeps) so we can run tsc
RUN npm ci

# Copy source and build
COPY src ./src
RUN npm run build

########################
# Runtime stage
########################
FROM node:20-bullseye-slim AS runtime
WORKDIR /app

# Copy only production dependencies and the built output
COPY package*.json ./
RUN npm ci --only=production

# Copy built app from build stage
COPY --from=build /app/dist ./dist

ENV NODE_ENV=production

# Expose a port if the server ever binds (not required for stdio transport)
EXPOSE 8080

# Default command - run the compiled server
CMD ["node", "dist/index.js"]
