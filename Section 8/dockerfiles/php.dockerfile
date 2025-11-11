FROM php:8.2-fpm-alpine

WORKDIR /var/www/html

COPY src .

RUN docker-php-ext-install pdo_mysql

# Give permissions to the www-data user
RUN chown -R www-data:www-data /var/www/html