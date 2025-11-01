# Imagen base con Apache y PHP 8.2
FROM php:8.2-apache

# Actualizar e instalar dependencias comunes
RUN apt-get update && apt-get install -y \
    libzip-dev zip unzip git curl \
 && docker-php-ext-install pdo pdo_mysql mysqli \
 && a2enmod rewrite \
 && rm -rf /var/lib/apt/lists/*

# Copiar el código fuente
WORKDIR /var/www/html
COPY php-simple-app/src/ ./

# Configurar Apache
RUN chown -R www-data:www-data /var/www/html \
 && echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Exponer el puerto HTTP
EXPOSE 80

# Definir usuario de ejecución (seguridad)
USER www-data

# Iniciar Apache (ya configurado en la imagen base)
CMD ["apache2-foreground"]
