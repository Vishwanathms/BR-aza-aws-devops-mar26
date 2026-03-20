# Use Ubuntu as base image
FROM ubuntu:22.04

# Avoid interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive

# Custom environment variable
ENV APP_ENV=dev

# Update and install Apache
RUN apt-get update && \
    apt-get install -y apache2 && \
    apt-get clean

# Copy index.html to Apache web root
COPY index.html /var/www/html/index.html

# Expose port 80
EXPOSE 80

# Start Apache in foreground
CMD ["apachectl", "-D", "FOREGROUND"]