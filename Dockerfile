# Use a lightweight base image to minimize footprint and security risks
FROM nginx:stable-alpine-slim AS base

# Install dependencies for user management (optional)
RUN apk add --no-cache --virtual .build-deps build-base openrc

# Create a non-root user for security (optional)
RUN adduser -D -u 1000 websiteuser

# Set the working directory for the web server
WORKDIR /var/www/html

# Copy the website content from the current directory
COPY ./public .

# Expose the default web server port (80)
EXPOSE 80

# Volume to mount the nginx configuration file (replace with your path)
VOLUME ["./nginx.conf"]

# Start the web server using the default command
CMD ["nginx", "-g", "daemon off;"]
