#!/bin/bash
ENV_FILE="/usr/src/.env.ini"
if [ -f "$ENV_FILE" ]; then
    export $(grep -v '^#' "$ENV_FILE" | xargs)
    echo "Variables cargadas desde $ENV_FILE"
else
    echo "Archivo $ENV_FILE no encontrado"
    exit 1
fi

start_time=$(date +%s)

while true; do
    # Intentar conectarse al MySQL en el contenedor
    if mysql -h"$MYSQL_SERVICE_NAME" -u"$DB_USER" -p"$DB_PASSWORD" -e "SELECT 1;" >/dev/null 2>&1; then
        echo "MySQL está listo para aceptar conexiones."
        break
    else
        echo "MySQL no está listo aún, esperando..."
    fi

    # Verificar si se ha excedido el tiempo de espera máximo
    current_time=$(date +%s)
    elapsed_time=$((current_time - start_time))

    if [ "$elapsed_time" -ge "$MAX_WAIT" ]; then
        echo "Se agotó el tiempo de espera. MySQL no está listo."
        exit 1
    fi

    # Esperar antes de volver a intentar
    sleep "$WAIT_INTERVAL"
done

php artisan storage:link
php artisan optimize:clear
php artisan down
php artisan migrate --force
php artisan config:cache
php artisan route:cache
php artisan view:cache
php artisan up

exec php-fpm