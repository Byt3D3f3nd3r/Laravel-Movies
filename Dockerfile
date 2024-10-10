# Use the official PHP FPM image as the base image
FROM php:8.2-fpm AS build

# Install system dependencies and required PHP extensions
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    locales \
    zip \
    jpegoptim \
    optipng \
    pngquant \
    gifsicle \
    vim \
    unzip \
    git \
    curl \
    libzip-dev \
    libonig-dev \
    libxml2-dev \
    redis-server \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd zip

# Set working directory
WORKDIR /var/www

# Copy existing application directory contents
COPY . /var/www

# Switch to root before setting permissions
USER root

# Set appropriate permissions for Laravel in the build stage
RUN chown -R www-data:www-data /var/www/storage \
    && chown -R www-data /var/www \
    && chmod -R 775 /var/www/storage \
    && chown -R www-data:www-data /var/www/bootstrap/cache \
    && chmod -R 775 /var/www/bootstrap/cache

# Final stage using the same slim image
FROM php:8.2-fpm

# Set working directory
WORKDIR /var/www

# Copy PHP extensions from the build stage
COPY --from=build /usr/local/lib/php/extensions/no-debug-non-zts-*/ /usr/local/lib/php/extensions/no-debug-non-zts/

# Copy the application files from the build stage
COPY --from=build /var/www /var/www

# Install Composer globally
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Ensure the storage and bootstrap/cache directories have the correct permissions
RUN chown -R www-data:www-data /var/www/storage \
    && chown -R www-data:www-data /var/www/bootstrap/cache \
    && chmod -R 775 /var/www/storage \
    && chmod -R 775 /var/www/bootstrap/cache

# Expose port 9000 for PHP-FPM
EXPOSE 9000 

# Start PHP-FPM server
CMD ["php-fpm"]