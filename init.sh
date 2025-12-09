#!/bin/bash

set -e

echo "======================================="
echo "  Инициализация VDI системы"
echo "======================================="

# Создаем необходимые директории
echo "Создание структуры директорий..."
mkdir -p guacamole/config
mkdir -p guacamole/extensions
mkdir -p jenkins/scripts
mkdir -p autogen

# Настройка прав
echo "Настройка прав доступа..."
chmod +x autogen/update-connections.sh
chmod +x init.sh

# Создание Docker network если не существует
echo "Проверка Docker network..."
if ! docker network ls | grep -q vdi-network; then
    echo "Создание сети vdi-network..."
    docker network create vdi-network
else
    echo "Сеть vdi-network уже существует"
fi

# Загрузка необходимых образов
echo "Предзагрузка Docker образов..."
docker pull guacamole/guacamole:latest || true
docker pull guacamole/guacd:latest || true
docker pull mysql:8.0 || true
docker pull jenkins/jenkins:lts-jdk11 || true
docker pull ubuntu:22.04 || true

# Сборка образа рабочего стола
echo "Сборка образа рабочего стола..."
docker build -f dockerfiles/Dockerfile.xfce-desktop -t vdi-desktop .

# Генерация начальной конфигурации Guacamole
echo "Генерация конфигурации Guacamole..."
./autogen/update-connections.sh

echo "======================================="
echo "  Инициализация завершена!"
echo "======================================="
echo ""
echo "Для запуска системы выполните:"
echo "  make deploy"
echo ""
echo "Или по отдельности:"
echo "  make up      # Основные сервисы"
echo "  make jenkins-up  # Jenkins"
echo ""
echo "Доступ:"
echo "  Guacamole: http://localhost:8080"
echo "  Jenkins:   http://localhost:8082/jenkins"
echo ""
echo "Учетные данные:"
echo "  Guacamole: admin/admin"
echo "  Рабочие столы: student/student123"
