# Build Stage
FROM node:18-alpine as build-stage

WORKDIR /app

# Copy package.json and package-lock.json first to leverage Docker's layer caching
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy the rest of the application files
COPY . .

# Build the React application
RUN npm run build

# Production Stage
FROM nginx:alpine

# Copy the Nginx configuration file
# Ensure you have an nginx.conf in your project root if you customize Nginx
COPY nginx.conf /etc/nginx/conf.d/default.conf

RUN ls

RUN cd /app

RUN ls
# Copy the built React application from the build stage to Nginx's web root
COPY --from=build-stage /app/build /usr/share/nginx/html

# Expose port 80 for Nginx
EXPOSE 80

# Command to start Nginx
CMD ["nginx", "-g", "daemon off;"]
