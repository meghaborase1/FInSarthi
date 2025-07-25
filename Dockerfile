# ---- Base image ----
FROM node:20-slim AS base

# Set working directory
WORKDIR /app

# Install pnpm globally
RUN npm install -g pnpm

# ---- Install dependencies ----
FROM base AS deps

WORKDIR /app

# Only copy package.json to leverage Docker cache
COPY package.json ./

# Install all dependencies (no lockfile used)
RUN pnpm install

# ---- Build the app ----
FROM base AS builder

WORKDIR /app

# Copy dependencies from deps stage
COPY --from=deps /app/node_modules ./node_modules

# Copy all app files
COPY . .

# Optional: Set build environment variables (or set via Cloud Run)
ARG DATABASE_URL
ENV DATABASE_URL=$DATABASE_URL

ARG GROQ_API_KEY
ENV GROQ_API_KEY=$GROQ_API_KEY

# Build the Next.js app
RUN npm run build

# ---- Final run image ----
FROM node:20-slim AS runner

WORKDIR /app

ENV NODE_ENV=production

# Copy only required build output (standalone)
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static

# Use PORT from Cloud Run or default to 3000
ENV PORT=3000

# Start server
CMD ["node", "server.js"]
