# Imagen base con Apache y PHP 8.2
FROM php:8.2-apache

# Actualizar e instalar dependencias necesarias (sin recomendados)
RUN apt-get update && apt-get install -y --no-install-recommends \
        libzip-dev zip unzip git curl \
    && docker-php-ext-install pdo pdo_mysql mysqli \
    && a2enmod rewrite \
    && rm -rf /var/lib/apt/lists/*

# Código fuente
WORKDIR /var/www/html
# Si tu código está en ./src, mantenlo así. Cambia la ruta si es distinto.
COPY ./src/ ./

# Configuración básica de Apache y permisos
RUN chown -R www-data:www-data /var/www/html \
    && echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Exponer HTTP
EXPOSE 80

# Importante: no cambiar a USER www-data; apache necesita arrancar como root en esta imagen.
CMD ["apache2-foreground"]
