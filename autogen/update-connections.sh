#!/bin/bash

# Загружаем переменные окружения
if [ -f .env ]; then
    set -a
    source .env
    set +a
else
    echo "Файл .env не найден! Создайте его сначала."
    exit 1
fi

echo "Генерация user-mapping.xml для Guacamole..."

# Создаем временный файл
TEMP_FILE=$(mktemp)

cat > "$TEMP_FILE" << EOFTEMP
<?xml version="1.0" encoding="UTF-8"?>
<user-mapping>
    <!-- Администратор -->
    <authorize username="admin" password="admin">
EOFTEMP

# Генерируем подключения для каждого рабочего стола
for i in $(seq 1 ${VDI_COUNT:-2}); do
    cat >> "$TEMP_FILE" << EOFCONN
        <connection name="VDI Desktop ${i}">
            <protocol>rdp</protocol>
            <param name="hostname">vdi-desktop-${i}</param>
            <param name="port">3389</param>
            <param name="username">${VDI_USER:-student}</param>
            <param name="password">${VDI_PASSWORD:-student123}</param>
            <param name="ignore-cert">true</param>
            <param name="security">${RDP_SECURITY:-any}</param>
            <param name="width">${RDP_WIDTH:-1280}</param>
            <param name="height">${RDP_HEIGHT:-720}</param>
            <param name="dpi">${RDP_DPI:-96}</param>
            <param name="server-layout">en-us-qwerty</param>
            <param name="enable-drive">true</param>
            <param name="drive-path">/tmp</param>
            <param name="create-drive-path">true</param>
        </connection>
EOFCONN
done

cat >> "$TEMP_FILE" << EOFTEMPEND
    </authorize>
</user-mapping>
EOFTEMPEND

# Копируем в нужное место
cp "$TEMP_FILE" guacamole/user-mapping.xml

# Очищаем временный файл
rm "$TEMP_FILE"

echo "Конфигурация обновлена!"
echo "Создано подключений: ${VDI_COUNT:-2}"
echo "Файл: guacamole/user-mapping.xml"

# Проверяем содержимое
echo ""
echo "Содержимое файла:"
echo "-----------------"
head -30 guacamole/user-mapping.xml
