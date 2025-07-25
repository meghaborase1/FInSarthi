# 1. Base Image: Use the official Node.js 20 image.
FROM node:20-slim AS base

# 2. Set working directory
WORKDIR /app

# 3. Install pnpm for efficient package management
RUN npm install -g pnpm

# --- DEPENDENCY STAGE ---
# Installs dependencies, which are cached in a separate layer.
FROM base AS deps
WORKDIR /app

# Copy only the package files to leverage Docker cache
COPY package.json pnpm-lock.yaml* ./
# Use pnpm to install dependencies
RUN pnpm install --frozen-lockfile

# --- BUILD STAGE ---
# Builds the Next.js application.
FROM base AS builder
WORKDIR /app

# Copy dependencies from the 'deps' stage
COPY --from=deps /app/node_modules ./node_modules
# Copy the rest of the application source code
COPY . .

# Environment variables needed for the build process
# These will be passed in during the Cloud Run build
ARG DATABASE_URL
ENV DATABASE_URL=$DATABASE_URL

ARG GROQ_API_KEY
ENV GROQ_API_KEY=$GROQ_API_KEY

# Run the Next.js build command
RUN npm run build

# --- RUNNER STAGE ---
# This is the final, small image that will run on Cloud Run.
FROM base AS runner
WORKDIR /app

# Set production environment
ENV NODE_ENV production

# Automatically set the PORT from Cloud Run
# No need to expose a specific port, Cloud Run handles this.

# Copy the standalone output from the builder stage.
# This includes a minimal server and only the necessary node_modules.
COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

# Start the application using the standalone server script.
CMD ["node", "server.js"]
