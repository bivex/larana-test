#!/bin/bash
set -e

CONFIG="Deploy script for Electrostatic to GitHub Pages"

# Настройки
GITHUB_USER="bivex"
PAGES_REPO="https://github.com/${GITHUB_USER}/${GITHUB_USER}.github.io.git"
DIST_DIR="dist"
ELECTROSTATIC_DIR="electrostatic"
CONTENT_DIR="mysite"
BINARY_NAME="esbuild"

echo "========================================"
echo "  $CONFIG"
echo "========================================"
echo "User: $GITHUB_USER"
echo "Repo: ${GITHUB_USER}.github.io"
echo ""

# Шаг 1: Сборка electrostatic
echo "Step 1: Building electrostatic..."
(cd "$ELECTROSTATIC_DIR" && go mod tidy && go build -o "$BINARY_NAME" .)
cp "$ELECTROSTATIC_DIR/$BINARY_NAME" ./
echo "✓ Build complete"
echo ""

# Шаг 2: Очистка старой сборки
echo "Step 2: Cleaning old build..."
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"
echo "✓ Clean complete"
echo ""

# Шаг 3: Генерация статического сайта
echo "Step 3: Exporting static site..."
./"$BINARY_NAME" -m export -r "$CONTENT_DIR" -d "$DIST_DIR"
echo "✓ Export complete"
echo ""

# Шаг 4: Деплой в GitHub Pages
echo "Step 4: Deploying to GitHub Pages..."
cd "$DIST_DIR"

# Копируем .git из сохраненного репозитория
if [ -d "../.github-pages-git" ]; then
    cp -r ../.github-pages-git .git
    git remote set-url origin "$PAGES_REPO"
else
    # Инициализация git если нет сохраненного
    git init
    git remote add origin "$PAGES_REPO"
fi

git add -A
COMMIT_MSG="Deploy $(date '+%Y-%m-%d %H:%M:%S')"
git commit -m "$COMMIT_MSG" || echo "No changes to commit"

git push -f origin gh-pages
echo "✓ Deploy complete"
echo ""

cd ..

echo "========================================"
echo "  Deploy successful!"
echo "========================================"
echo "Site: https://${GITHUB_USER}.github.io"
echo ""
