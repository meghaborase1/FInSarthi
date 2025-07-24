# Stage 1: Build the Next.js application
# Using a slim Node.js image for a smaller base size during the build process
FROM node:20-slim AS builder

# Set the working directory inside the container
WORKDIR /app

# Copy package.json and package-lock.json (if present)
# This step is crucial for leveraging Docker's layer caching.
# If only package.json changes, npm install will re-run.
# If only code changes, this layer (and npm install) will be cached.
COPY package.json package-lock.json* ./

# Install project dependencies
# The --frozen-lockfile flag is used to ensure that the exact versions
# specified in package-lock.json are installed, leading to consistent builds.
RUN npm install --frozen-lockfile

# Copy the rest of the application source code into the container
COPY . .

# Build the Next.js application for production
# This command generates the optimized build output in the .next directory
RUN npm run build

# Stage 2: Run the Next.js application in a production environment
# Using a smaller, production-ready Node.js image for the final image
FROM node:20-slim AS runner

# Set the working directory inside the container
WORKDIR /app

# Set environment variables for production
# NODE_ENV is essential for Next.js to run in production mode
ENV NODE_ENV production
# Define the port the application will listen on.
# This matches the port used in your package.json's dev script (9002),
# but Next.js defaults to 3000 if PORT is not set. Explicitly setting it
# ensures consistency.
ENV PORT 9002

# Copy only the necessary files from the builder stage to the runner stage.
# This minimizes the final image size by excluding development dependencies
# and build artifacts not needed at runtime.
# - public: Static assets like images, fonts, etc.
# - .next: The compiled Next.js application output.
# - node_modules: Production dependencies.
# - package.json: Needed by 'npm start' to know how to run the app.
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json

# Expose the port on which the Next.js application will run.
# This informs Docker that the container listens on this port at runtime.
EXPOSE ${PORT}

# Define the command to start the Next.js application in production mode.
# 'npm start' executes the 'start' script defined in your package.json.
CMD ["npm", "start"]
