FROM php:8.2-apache

# Install system dependencies and PHP extensions required for MediaWiki
RUN apt-get update && apt-get install -y --no-install-recommends \
    libicu-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    imagemagick \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) mysqli intl mbstring xml zip gd opcache \
    && rm -rf /var/lib/apt/lists/*

# Enable Apache mod_rewrite for clean URLs in MediaWiki
RUN a2enmod rewrite

# Copy MediaWiki source code from the repository directory into the web root
COPY ./mywiki/ /var/www/html/

# Set proper ownership permissions for the Apache web server
RUN chown -R www-data:www-data /var/www/html

EXPOSE 80
