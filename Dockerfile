FROM php:8.2-apache

WORKDIR /var/www/html
COPY php-simple-app/src/ ./

RUN a2enmod rewrite \
 && chown -R www-data:www-data /var/www/html

EXPOSE 80
