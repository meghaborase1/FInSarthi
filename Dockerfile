# Stage 1: Build the React application
FROM node:18-alpine AS builder

WORKDIR /app

COPY package.json ./
COPY package-lock.json ./

# Install dependencies, optimize for production
RUN npm ci --only=production

COPY . ./

# Build the React app for production
# Assuming your build script is 'npm run build' and output goes to 'build' folder
RUN npm run build

# Stage 2: Serve the React application with Nginx
FROM nginx:alpine

# Copy the built React app from the builder stage
COPY --from=builder /app/build /usr/share/nginx/html

# Remove the default Nginx configuration
RUN rm /etc/nginx/conf.d/default.conf

# Copy your custom Nginx configuration (create this file if you need specific settings)
# If you don't have one, Nginx's default will serve /usr/share/nginx/html
# You might want to create a file named nginx.conf in your project root with content like:
# server {
#     listen 80;
#     location / {
#         root /usr/share/nginx/html;
#         index index.html index.htm;
#         try_files $uri $uri/ /index.html;
#     }
# }
COPY nginx.conf /etc/nginx/conf.d/your-app.conf

# Expose port 80 to the host
EXPOSE 80

# Command to run Nginx
CMD ["nginx", "-g", "daemon off;"]
