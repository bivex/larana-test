#!/bin/bash
set -e

# Цвета для вывода
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Настройки
ELECTROSTATIC_DIR="electrostatic"
CONTENT_DIR="mysite"
DIST_DIR="dist"
BINARY_NAME="esbuild"
PORT=":3030"

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

# Шаг 1: Сборка electrostatic
echo -e "${GREEN}[1/3] Building electrostatic...${NC}"
(cd "$ELECTROSTATIC_DIR" && go mod tidy && go build -o "$BINARY_NAME" .)
cp "$ELECTROSTATIC_DIR/$BINARY_NAME" ./
echo -e "${GREEN}✓ Build complete${NC}"
echo ""

# Режим запуска
if [ "$1" == "--ssr" ]; then
    # SSR режим с live reload
    echo -e "${GREEN}[2/3] Starting SSR server on http://localhost${PORT}${NC}"
    echo -e "${YELLOW}Press Ctrl+C to stop${NC}"
    echo ""

    ./"$BINARY_NAME" -m serve -r "$CONTENT_DIR" -p "$PORT"
else
    # Статический режим
    echo -e "${GREEN}[2/3] Exporting static site...${NC}"
    rm -rf "$DIST_DIR"
    mkdir -p "$DIST_DIR"
    ./"$BINARY_NAME" -m export -r "$CONTENT_DIR" -d "$DIST_DIR"
    echo -e "${GREEN}✓ Export complete${NC}"
    echo ""

    # Запуск простого HTTP сервера
    echo -e "${GREEN}[3/3] Starting HTTP server on http://localhost${PORT}${NC}"
    echo -e "${YELLOW}Press Ctrl+C to stop${NC}"
    echo ""
    echo -e "${BLUE}Re-run this script to rebuild after changes${NC}"
    echo ""

    # Используем встроенный в Python HTTP сервер
    cd "$DIST_DIR"
    python3 -m http.server 3030 &
    SERVER_PID=$!

    # Ожидание
    wait $SERVER_PID 2>/dev/null || true
fi
