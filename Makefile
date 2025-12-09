.PHONY: help build up down restart logs clean init rebuild deploy status

help: ## Показать это сообщение
	@echo "Доступные команды:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

init: ## Инициализация проекта (первый запуск)
	@echo "Инициализация проекта..."
	@chmod +x init.sh autogen/update-connections.sh
	@./init.sh

build: ## Собрать образ рабочего стола
	@echo "Сборка образа рабочего стола..."
	@docker build -f dockerfiles/Dockerfile.xfce-desktop -t vdi-desktop .

up: build ## Запустить все сервисы
	@echo "Запуск VDI инфраструктуры..."
	@docker-compose up -d

down: ## Остановить все сервисы
	@echo "Остановка VDI инфраструктуры..."
	@docker-compose down

restart: down up ## Перезапустить все сервисы

logs: ## Показать логи
	@docker-compose logs -f

clean: ## Очистить проект (остановить и удалить контейнеры)
	@echo "Очистка проекта..."
	@docker-compose down -v
	@docker rmi -f vdi-desktop 2>/dev/null || true

rebuild: clean build up ## Полная пересборка

deploy: ## Деплой всего стека (основной + Jenkins)
	@echo "Деплой полного стека..."
	@make up
	@docker-compose -f docker-compose.jenkins.yml up -d

status: ## Показать статус контейнеров
	@echo "=== Основные сервисы ==="
	@docker-compose ps
	@echo ""
	@echo "=== Jenkins ==="
	@docker-compose -f docker-compose.jenkins.yml ps

# Jenkins управление
jenkins-up: ## Запустить Jenkins
	@docker-compose -f docker-compose.jenkins.yml up -d

jenkins-down: ## Остановить Jenkins
	@docker-compose -f docker-compose.jenkins.yml down

jenkins-logs: ## Логи Jenkins
	@docker-compose -f docker-compose.jenkins.yml logs -f

# Обновление конфигураций
update-connections: ## Обновить подключения Guacamole
	@echo "Обновление подключений..."
	@./autogen/update-connections.sh

# Информация
info: ## Показать информацию о проекте
	@echo "=== VDI Система ==="
	@echo "Guacamole: http://localhost:8080"
	@echo "Jenkins:   http://localhost:8082/jenkins"
	@echo "RDP хосты: vdi-desktop-1, vdi-desktop-2"
	@echo ""
	@echo "Сетевые интерфейсы:"
	@echo "- NAT: 192.168.56.103"
	@echo "- Host-only: 10.0.2.15"
	@echo ""
	@echo "Учетные данные:"
	@echo "Guacamole: admin/admin"
	@echo "Рабочие столы: student/student123"
