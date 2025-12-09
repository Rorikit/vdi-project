#!/bin/bash

# Включаем строгий режим - любая ошибка остановит выполнение
set -e

echo "=== Развертывание VDI инфраструктуры ==="
echo "Начало: $(date)"
echo ""

# Проверка 1: Docker доступен
echo "1. Проверка Docker..."
if ! docker --version > /dev/null 2>&1; then
    echo "❌ ОШИБКА: Docker не доступен!"
    exit 1
fi
echo "✅ Docker доступен: $(docker --version)"

# Проверка 2: Docker Compose доступен
echo ""
echo "2. Проверка Docker Compose..."
if ! docker-compose --version > /dev/null 2>&1; then
    echo "❌ ОШИБКА: Docker Compose не доступен!"
    exit 1
fi
echo "✅ Docker Compose доступен: $(docker-compose --version)"

# Проверка 3: Директория проекта существует
echo ""
echo "3. Проверка директории проекта..."
cd /var/jenkins_home/vdi-project 2>/dev/null || cd ~/vdi-project

if [ ! -f "docker-compose.yml" ]; then
    echo "❌ ОШИБКА: Файл docker-compose.yml не найден!"
    echo "Текущая директория: $(pwd)"
    echo "Содержимое:"
    ls -la
    exit 1
fi
echo "✅ Проект найден в: $(pwd)"

# Проверка 4: Dockerfile существует
echo ""
echo "4. Проверка Dockerfile..."
if [ ! -f "dockerfiles/Dockerfile.xfce-desktop" ]; then
    echo "❌ ОШИБКА: Dockerfile.xfce-desktop не найден!"
    exit 1
fi
echo "✅ Dockerfile найден"

# Шаг 5: Остановка старых контейнеров
echo ""
echo "5. Остановка старых контейнеров..."
if docker-compose down; then
    echo "✅ Старые контейнеры остановлены"
else
    echo "⚠️  Предыдущие контейнеры не найдены (но это не ошибка)"
fi

# Шаг 6: Сборка образа с проверкой
echo ""
echo "6. Сборка Docker образа..."
if docker build -t vdi-desktop:latest -f dockerfiles/Dockerfile.xfce-desktop dockerfiles/; then
    echo "✅ Образ успешно собран"
else
    echo "❌ ОШИБКА: Не удалось собрать Docker образ!"
    exit 1
fi

# Шаг 7: Запуск инфраструктуры
echo ""
echo "7. Запуск VDI инфраструктуры..."
if docker-compose up -d; then
    echo "✅ Контейнеры запущены"
else
    echo "❌ ОШИБКА: Не удалось запустить docker-compose!"
    exit 1
fi

# Шаг 8: Ожидание запуска
echo ""
echo "8. Ожидание запуска сервисов..."
sleep 20

# Шаг 9: Проверка состояния контейнеров
echo ""
echo "9. Проверка состояния контейнеров..."
CONTAINER_STATUS=$(docker-compose ps --services --filter "status=running" | wc -l)
TOTAL_CONTAINERS=$(docker-compose ps --services | wc -l)

echo "Запущено контейнеров: $CONTAINER_STATUS из $TOTAL_CONTAINERS"

if [ "$CONTAINER_STATUS" -lt "$TOTAL_CONTAINERS" ]; then
    echo "❌ ПРЕДУПРЕЖДЕНИЕ: Не все контейнеры запущены"
    echo "Подробности:"
    docker-compose ps
    # Это не фатальная ошибка, продолжаем
fi

# Шаг 10: Проверка Guacamole
echo ""
echo "10. Проверка Guacamole..."
MAX_RETRIES=5
RETRY_COUNT=0
GUACAMOLE_READY=false

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if docker exec guacamole curl -s -f http://localhost:8080 > /dev/null 2>&1; then
        GUACAMOLE_READY=true
        break
    fi
    echo "  Попытка $((RETRY_COUNT+1))/$MAX_RETRIES: Guacamole еще не готов..."
    RETRY_COUNT=$((RETRY_COUNT+1))
    sleep 10
done

if [ "$GUACAMOLE_READY" = true ]; then
    echo "✅ Guacamole запущен и отвечает"
else
    echo "❌ ОШИБКА: Guacamole не запустился за $MAX_RETRIES попыток!"
    echo "Логи Guacamole:"
    docker-compose logs guacamole --tail=50
    exit 1
fi

# Шаг 11: Проверка рабочих столов
echo ""
echo "11. Проверка рабочих столов..."
DESKTOP_CONTAINERS=("vdi-desktop-1" "vdi-desktop-2")
DESKTOP_FAILED=0

for container in "${DESKTOP_CONTAINERS[@]}"; do
    if docker exec "$container" ps aux | grep -q "xrdp"; then
        echo "✅ $container: xrdp запущен"
    else
        echo "❌ $container: xrdp НЕ запущен"
        DESKTOP_FAILED=$((DESKTOP_FAILED+1))
    fi
done

if [ $DESKTOP_FAILED -gt 0 ]; then
    echo "❌ ПРЕДУПРЕЖДЕНИЕ: $DESKTOP_FAILED из ${#DESKTOP_CONTAINERS[@]} рабочих столов не запустились"
fi

# Шаг 12: Финальный отчет
echo ""
echo "=== РАЗВЕРТЫВАНИЕ ЗАВЕРШЕНО ==="
echo "Время окончания: $(date)"
echo ""
echo "=== СТАТУС СИСТЕМЫ ==="
docker-compose ps
echo ""
echo "=== ДОСТУП ==="
SERVER_IP=$(hostname -I | awk '{print $1}')
echo "Guacamole (веб-интерфейс): http://${SERVER_IP}:8080/guacamole"
echo "  Логин по умолчанию: guacadmin / guacadmin"
echo ""
echo "Прямой RDP доступ:"
echo "  Рабочий стол 1: ${SERVER_IP}:3391"
echo "  Рабочий стол 2: ${SERVER_IP}:3392"
echo "  Логин: student / student123"
echo ""
echo "Jenkins: http://${SERVER_IP}:8082"
echo ""
echo "=== ЛОГИ ==="
echo "Для просмотра логов выполните:"
echo "  docker-compose logs guacamole"
echo "  docker-compose logs vdi-desktop-1"

# Если есть проблемы с рабочими столами, не фейлим джобу, но предупреждаем
if [ $DESKTOP_FAILED -eq ${#DESKTOP_CONTAINERS[@]} ]; then
    echo ""
    echo "⚠️  ВНИМАНИЕ: Ни один рабочий стол не запустился!"
    echo "Но основная инфраструктура (Guacamole) работает."
fi
