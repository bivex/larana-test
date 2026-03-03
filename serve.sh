#!/bin/bash
set -e

# Цвета для вывода
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Настройки
ELECTROSTATIC_DIR="electrostatic"
CONTENT_DIR="mysite"
DIST_DIR="dist"
BINARY_NAME="esbuild"
PORT="3030"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  @bivex Blog - Local Server${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Функция для остановки фоновых процессов
cleanup() {
    echo -e "${YELLOW}Stopping server...${NC}"
    if [ ! -z "$SERVER_PID" ]; then
        kill $SERVER_PID 2>/dev/null || true
    fi
    exit 0
}

trap cleanup INT TERM

# Остановить старый процесс на порту если есть
stop_old_server() {
    local OLD_PID=$(lsof -ti:$PORT 2>/dev/null || true)
    if [ ! -z "$OLD_PID" ]; then
        echo -e "${YELLOW}Stopping old server on port $PORT (PID: $OLD_PID)...${NC}"
        kill -9 $OLD_PID 2>/dev/null || true
        sleep 1
    fi
}

# Шаг 1: Сборка electrostatic
echo -e "${GREEN}[1/4] Building electrostatic...${NC}"
(cd "$ELECTROSTATIC_DIR" && go mod tidy && go build -o "$BINARY_NAME" .)
cp "$ELECTROSTATIC_DIR/$BINARY_NAME" ./
echo -e "${GREEN}✓ Build complete${NC}"
echo ""

# Режим запуска
if [ "$1" == "--ssr" ]; then
    # SSR режим с live reload
    stop_old_server
    echo -e "${GREEN}[2/4] Starting SSR server on http://localhost:$PORT${NC}"
    echo -e "${YELLOW}Press Ctrl+C to stop${NC}"
    echo ""

    ./"$BINARY_NAME" -m serve -r "$CONTENT_DIR" -p ":$PORT"
else
    # Статический режим
    echo -e "${GREEN}[2/4] Exporting static site...${NC}"
    rm -rf "$DIST_DIR"
    mkdir -p "$DIST_DIR"
    ./"$BINARY_NAME" -m export -r "$CONTENT_DIR" -d "$DIST_DIR"
    echo -e "${GREEN}✓ Export complete${NC}"
    echo ""

    # Остановить старый сервер
    stop_old_server

    # Запуск HTTP сервера
    echo -e "${GREEN}[3/4] Starting HTTP server on http://localhost:$PORT${NC}"
    echo -e "${YELLOW}Press Ctrl+C to stop${NC}"
    echo ""

    cd "$DIST_DIR"

    # Проверяем доступность Python
    if command -v python3 &> /dev/null; then
        python3 -m http.server $PORT &
        SERVER_PID=$!
    elif command -v python &> /dev/null; then
        python -m http.server $PORT &
        SERVER_PID=$!
    else
        echo -e "${RED}Error: Python not found. Please install Python or use --ssr mode${NC}"
        exit 1
    fi

    echo -e "${GREEN}✓ Server started with PID: $SERVER_PID${NC}"
    echo -e "${BLUE}Re-run this script to rebuild after changes${NC}"
    echo ""

    # Ожидание
    wait $SERVER_PID 2>/dev/null || true
fi
