#!/bin/bash

# Script untuk instalasi WordPress dengan Nginx dan PHP 8.3 pada VPS Ubuntu

# Periksa apakah script dijalankan dengan hak akses root
if [[ $EUID -ne 0 ]]; then
   echo "Script ini harus dijalankan sebagai root atau dengan sudo"
   exit 1
fi

# Fungsi untuk kembali ke menu utama
function kembali_ke_menu_utama() {
    echo "Kembali ke menu utama..."
    sleep 2
    clear
    menu_utama
}

# Fungsi untuk menampilkan pesan selamat datang
function pesan_selamat_datang() {
    clear
    echo "====================================================="
    echo " Selamat datang di Skrip Instalasi WordPress dengan Nginx dan PHP 8.3 "
    echo "====================================================="
    echo
}

# Fungsi untuk menampilkan menu utama
function menu_utama() {
    pesan_selamat_datang
    echo "Pilihan Menu:"
    echo "1. Install Otomatis WordPress"
    echo "2. Instalasi Manual untuk Software lain"
    echo "3. Uninstall Semua Skrip yang Telah Diinstal"
    echo "4. Tambahkan Domain lain di Web"
    echo "5. Keluar"
    echo
    read -p "Masukkan pilihan Anda [1-5]: " pilihan

    case $pilihan in
        1) install_wordpress ;;
        2) instalasi_manual ;;
        3) uninstall_semua ;;
        4) tambah_domain ;;
        5) exit 0 ;;
        *) echo "Pilihan tidak valid. Silakan coba lagi." ; kembali_ke_menu_utama ;;
    esac
}

# Fungsi untuk instalasi WordPress
function install_wordpress() {
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

    kembali_ke_menu_utama
}

# Fungsi untuk instalasi manual software
function instalasi_manual() {
    echo "Fungsi untuk instalasi manual software belum diimplementasikan."
    kembali_ke_menu_utama
}

# Fungsi untuk uninstall semua skrip
function uninstall_semua() {
    echo "Fungsi untuk uninstall semua skrip belum diimplementasikan."
    kembali_ke_menu_utama
}

# Fungsi untuk menambahkan domain lain di web
function tambah_domain() {
    echo "Fungsi untuk menambahkan domain lain di web belum diimplementasikan."
    kembali_ke_menu_utama
}

# Memanggil menu utama untuk pertama kali
menu_utama
