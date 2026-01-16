#!/usr/bin/env bash
set -e

# ===========================
#   Pterodactyl Panel Updater
# ===========================

clear
echo "==============================================="
echo "      🚀 PTERODACTYL PANEL UPDATE SCRIPT 🚀    "
echo "==============================================="
echo ""

echo ">>> Starting Pterodactyl Panel Update..."

# Go to panel directory
cd /var/www/pterodactyl || { echo "❌ Panel directory not found!"; exit 1; }

# Put panel into maintenance mode
echo "⚙️ Putting panel into maintenance mode..."
php artisan down

# Download latest release
echo "⬇️ Downloading latest Panel release..."
curl -L https://github.com/pterodactyl/panel/releases/download/v1.11.7/panel.tar.gz | tar -xzv

# Fix permissions
echo "🔑 Setting correct permissions..."
chmod -R 755 storage/* bootstrap/cache

# Install PHP dependencies
echo "📦 Running composer install..."
composer install --no-dev --optimize-autoloader

# Clear caches
echo "🧹 Clearing cache..."
php artisan view:clear
php artisan config:clear

# Run migrations
echo "📂 Running migrations..."
php artisan migrate --seed --force

# Fix ownership
echo "👤 Setting ownership to www-data..."
chown -R www-data:www-data /var/www/pterodactyl/*

# Restart queue workers
echo "♻️ Restarting queue workers..."
php artisan queue:restart

# Bring panel back online
echo "✅ Bringing panel back online..."
php artisan up

echo ""
echo "==============================================="
echo " 🎉 Pterodactyl Panel downgrate completed! 🎉 "
echo "==============================================="
