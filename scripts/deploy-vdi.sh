#!/bin/bash

echo "=== VDI Deployment with Guacamole ==="

cd ~/vdi-project

# 1. Останавливаем всё
echo "Stopping existing containers..."
docker-compose down 2>/dev/null || true
docker rm -f $(docker ps -aq --filter "name=vdi-*" --filter "name=guacamole" --filter "name=mysql") 2>/dev/null || true

# 2. Собираем образ рабочего стола
echo "Building desktop image..."
docker build -t vdi-desktop -f dockerfiles/Dockerfile.xfce-desktop dockerfiles/

# 3. Запускаем контейнеры
echo "Starting containers..."
docker-compose up -d

# 4. Ждем инициализации
echo "Waiting for initialization..."
sleep 30

# 5. Инициализируем базу данных Guacamole
echo "Initializing Guacamole database..."
docker exec mysql mysql -u root -prootpassword -e "CREATE DATABASE IF NOT EXISTS guacamole_db;" 2>/dev/null || true
docker run --rm guacamole/guacamole /opt/guacamole/bin/initdb.sh --mysql | docker exec -i mysql mysql -u root -prootpassword guacamole_db 2>/dev/null || true

# 6. Перезапускаем Guacamole для применения настроек
echo "Restarting Guacamole..."
docker-compose restart guacamole

# 7. Проверяем
sleep 10
echo ""
echo "=== Deployment Complete ==="
echo "Guacamole URL: http://$(hostname -I | awk '{print $1}'):8080/guacamole"
echo "Login: admin"
echo "Password: admin"
echo ""
echo "Desktop credentials:"
echo "Username: student"
echo "Password: student123"
