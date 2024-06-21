#!/bin/bash

# Menu
echo "================================================="
echo "  Selamat datang! Silakan pilih menu instalasi   "
echo "================================================="
echo "1. Install WordPress secara otomatis"
echo "2. Instalasi manual software"
echo "3. Uninstall semua skrip yang dijalankan"
echo "4. Tambahkan beberapa domain di web"
echo "5. Keluar"
echo "================================================="
read -p "Masukkan pilihan Anda [1-5]: " MENU_OPTION

# Validasi pilihan menu
case $MENU_OPTION in
    1)
        echo "Anda memilih menu 1: Install WordPress secara otomatis"
        # Lanjutkan dengan instalasi WordPress otomatis
        ;;
    2)
        echo "Anda memilih menu 2: Instalasi manual software"
        # Lanjutkan dengan opsi instalasi manual
        ;;
    3)
        echo "Anda memilih menu 3: Uninstall semua skrip yang dijalankan"
        # Lanjutkan dengan proses uninstall
        ;;
    4)
        echo "Anda memilih menu 4: Tambahkan beberapa domain di web"
        # Lanjutkan dengan proses tambah domain
        ;;
    5)
        echo "Terima kasih telah menggunakan skrip ini. Sampai jumpa!"
        exit 0
        ;;
    *)
        echo "Pilihan tidak valid. Silakan pilih antara 1-5."
        exit 1
        ;;
esac

# Periksa apakah script dijalankan dengan hak akses root
if [[ $EUID -ne 0 ]]; then
   echo "Script ini harus dijalankan sebagai root atau dengan sudo"
   exit 1
fi

# Meminta input pengguna untuk nama domain, nama database, pengguna database, password pengguna database, dan password root MariaDB
read -p "Masukkan nama domain (contoh: example.com): " DOMAIN
read -p "Masukkan nama database: " DB_NAME
read -p "Masukkan nama pengguna database: " DB_USER
read -sp "Masukkan password pengguna database: " DB_PASS
echo
read -sp "Masukkan password root MariaDB: " MARIADB_ROOT_PASSWORD
echo
read -p "Masukkan email untuk sertifikat SSL: " SSL_EMAIL

DOC_ROOT="/var/www/html/$DOMAIN"
NGINX_CONF="/etc/nginx/sites-available/$DOMAIN"
NGINX_LINK="/etc/nginx/sites-enabled/$DOMAIN"

# Tambahkan repositori PHP 8.3
add-apt-repository -y ppa:ondrej/php
apt-get update

# Install Nginx, PHP 8.3 serta ekstensi yang diperlukan
apt-get install -y nginx php8.3-fpm php8.3-mysql php8.3-curl php8.3-gd php8.3-mbstring php8.3-xml php8.3-xmlrpc php8.3-soap php8.3-intl php8.3-zip unzip

# Periksa apakah MariaDB sudah terinstal
if ! dpkg -l | grep -q mariadb-server; then
    echo "MariaDB tidak ditemukan. Menginstal MariaDB..."
    apt-get install -y mariadb-server
else
    echo "MariaDB sudah terinstal."
fi

# Konfigurasi MariaDB
mysql -u root -p"$MARIADB_ROOT_PASSWORD" <<EOF
CREATE DATABASE IF NOT EXISTS ${DB_NAME} DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
EOF

# Membuat direktori dokumen root
mkdir -p $DOC_ROOT
chown -R www-data:www-data $DOC_ROOT
chmod -R 755 $DOC_ROOT

# Membuat file konfigurasi Nginx
cat <<EOL > $NGINX_CONF
server {
        listen 80;
        root $DOC_ROOT;
        index index.php index.html index.htm index.nginx-debian.html;
        server_name $DOMAIN www.$DOMAIN;

        location / {
                try_files \$uri \$uri/ =404;
        }

        location ~ \.php\$ {
                include snippets/fastcgi-php.conf;
                fastcgi_pass unix:/var/run/php/php8.3-fpm.sock;
        }

        location ~ /\.ht {
                deny all;
        }
}
EOL

# Aktifkan konfigurasi Nginx
ln -s $NGINX_CONF $NGINX_LINK
nginx -t && systemctl reload nginx

# Unduh WordPress
wget https://wordpress.org/latest.tar.gz -O /tmp/latest.tar.gz
tar -xzvf /tmp/latest.tar.gz -C /tmp/
cp -r /tmp/wordpress/* $DOC_ROOT/
rm /tmp/latest.tar.gz

# Konfigurasi WordPress
cp $DOC_ROOT/wp-config-sample.php $DOC_ROOT/wp-config.php
sed -i "s/database_name_here/$DB_NAME/" $DOC_ROOT/wp-config.php
sed -i "s/username_here/$DB_USER/" $DOC_ROOT/wp-config.php
sed -i "s/password_here/$DB_PASS/" $DOC_ROOT/wp-config.php

# Setel hak akses
chown -R www-data:www-data $DOC_ROOT
chmod -R 755 $DOC_ROOT

# Instalasi Certbot untuk SSL
apt-get install -y certbot python3-certbot-nginx

# Memperoleh sertifikat SSL dari Let's Encrypt
certbot --nginx -d $DOMAIN -d www.$DOMAIN --non-interactive --agree-tos --email $SSL_EMAIL

# Memperbarui konfigurasi Nginx untuk menggunakan SSL
cat <<EOL > $NGINX_CONF
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    server_name $DOMAIN www.$DOMAIN;

    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    root $DOC_ROOT;
    index index.php index.html index.htm index.nginx-debian.html;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.3-fpm.sock;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOL

# Reload Nginx untuk menerapkan perubahan
nginx -t && systemctl reload nginx

# Selesai
echo "Instalasi WordPress dengan Nginx dan PHP 8.3 selesai. Anda bisa mengakses situs Anda pada https://$DOMAIN"
