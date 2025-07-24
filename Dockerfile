# Stage 1: Build the React application
FROM node:18-alpine AS builder

# Set the working directory inside the container
WORKDIR /app

# Copy package.json and package-lock.json first to leverage Docker cache
COPY package.json ./
COPY package-lock.json ./

# Install project dependencies. 'npm ci' ensures clean, consistent installs based on package-lock.json
# '--only=production' skips development dependencies for a smaller node_modules
RUN npm ci --only=production

# Copy the rest of your application code
COPY . ./

# Build the React application for production.
# This command assumes your package.json has a "build" script that outputs to a "build" folder.
RUN npm run build

# Stage 2: Serve the React application with Nginx
FROM nginx:alpine

# Copy the built React application from the 'builder' stage to Nginx's default public directory
COPY --from=builder /app/build /usr/share/nginx/html

# Remove the default Nginx configuration file
RUN rm /etc/nginx/conf.d/default.conf

# Copy your custom Nginx configuration. You need to create `nginx.conf` in your project root.
COPY nginx.conf /etc/nginx/conf.d/finsarthi.conf

# Expose port 80 to allow external access to the Nginx server
EXPOSE 80

# Command to run Nginx in the foreground, essential for Docker containers
CMD ["nginx", "-g", "daemon off;"]
