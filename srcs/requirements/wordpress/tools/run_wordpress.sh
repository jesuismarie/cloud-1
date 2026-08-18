#!/bin/bash
set -e

WP_PATH="/var/www/html"
cd "$WP_PATH"

for secret in db_pass wp_root_pass wp_user_pass; do
	if [ ! -s "/run/secrets/${secret}" ]; then
		echo "[x] Missing or empty secret file(s)"
		exit 1
	fi
done

PHP_FPM_CONF="/etc/php/${PHP_VERSION}/fpm/pool.d/www.conf"
if [ -f "$PHP_FPM_CONF" ]; then
	sed -i "s|^listen = .*|listen = 0.0.0.0:9000|" "$PHP_FPM_CONF"
fi

download_wordpress()
{
	if [ ! -f "wp-includes/version.php" ]; then
		echo "[WordPress] Downloading WordPress core..."
		wp core download --allow-root
		echo "[WordPress] Core downloaded successfully."
	else
		echo "[WordPress] Core already present — skipping."
	fi
}

configure_wordpress()
{
	if [ -f "wp-config.php" ]; then
		echo "[WordPress] wp-config.php already exists — skipping"
		return 0
	fi

	echo "[WordPress] Creating wp-config.php..."

	wp config create \
		--dbname="$MYSQL_DATABASE" \
		--dbuser="$MYSQL_USER" \
		--dbpass="$(cat /run/secrets/db_pass)" \
		--dbhost="$MYSQL_HOSTNAME" \
		--dbcharset="utf8mb4" \
		--force \
		--allow-root
}

install_wordpress()
{
	echo "[WordPress] Installing WordPress..."
	wp core install \
		--url="$DOMAIN_NAME" \
		--title="$WORDPRESS_TITLE" \
		--admin_user="$WORDPRESS_ROOT_USERNAME" \
		--admin_password="$(cat /run/secrets/wp_root_pass)" \
		--admin_email="$WORDPRESS_ROOT_EMAIL" \
		--skip-email \
		--allow-root

	echo "[WordPress] Creating subscriber user..."
	wp user create "$WORDPRESS_USER_USERNAME" "$WORDPRESS_USER_EMAIL" \
		--role=subscriber \
		--user_pass="$(cat /run/secrets/wp_user_pass)" \
		--allow-root
}

install_theme()
{
	echo "[WordPress] Installing theme..."
	wp theme install twentytwentytwo --activate --allow-root || true
}

download_wordpress
configure_wordpress
echo "[WordPress] Waiting for MySQL..."
until bash -c "echo > /dev/tcp/$MYSQL_HOSTNAME/3306" 2>/dev/null; do
	echo "[WordPress] Not ready — retrying in 2s..."
	sleep 2
done
echo "[WordPress] Database is ready."
if ! wp core is-installed --allow-root >/dev/null 2>&1; then
	install_wordpress
fi
install_theme

chown -R www-data:www-data "$WP_PATH"
chmod -R 755 "$WP_PATH"

echo "[WordPress] Ready. Starting PHP-FPM..."

exec "$@"