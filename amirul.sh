#!/bin/bash

# Script untuk instalasi WordPress dengan Nginx dan PHP 8.3 pada VPS Ubuntu

# Fungsi untuk menampilkan header
function tampilkan_header() {
    clear
    echo "==============================================="
    echo ="         Selamat Datang di autoinstall        "
    echo "==============================================="
    echo "          Oleh: Amirul Hendra Wicaksono        "
    echo "==============================================="
    echo
}

# Fungsi untuk menampilkan menu utama
function tampilkan_menu_utama() {
    echo "Silakan pilih tindakan yang ingin Anda lakukan:"
    echo "1. Install WordPress secara otomatis"
    echo "2. Install Nginx, PHP, dan MariaDB"
    echo "3. Uninstall semua skrip yang sudah dijalankan"
    echo "4. Menambahkan domain baru di web"
    echo "5. Keluar"
    echo
}

# Fungsi untuk memproses pilihan menu
function pilih_menu() {
    local pilihan
    read -p "Masukkan pilihan [1-5]: " pilihan
    case $pilihan in
        1) install_wordpress ;;
        2) install_nginx_php_mariadb ;;
        3) uninstall_semua_skrip ;;
        4) tambah_domain ;;
        5) exit ;;
        *) echo "Pilihan tidak valid. Masukkan angka 1-5." ;;
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

    #!/bin/bash

# Script untuk instalasi WordPress dengan Nginx dan PHP 8.3 pada VPS Ubuntu

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
        server_name $DOMAIN www.$DOMAIN;

        root $DOC_ROOT;
        index index.php index.html index.htm;

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
    index index.php index.html index.htm;

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

# Fungsi untuk instalasi Nginx, PHP, dan MariaDB
function install_nginx_php_mariadb() {
    echo "Silakan pilih software yang ingin Anda install:"
    echo "1. Nginx"
    echo "2. PHP 8.3"
    echo "3. MariaDB"
    echo "4. Kembali ke menu utama"
    echo

    local pilihan_software
    read -p "Masukkan pilihan [1-4]: " pilihan_software
    case $pilihan_software in
        1) install_nginx ;;
        2) install_php ;;
        3) install_mariadb ;;
        4) kembali_ke_menu_utama ;;
        *) echo "Pilihan tidak valid. Masukkan angka 1-4." ;;
    esac
}

# Fungsi untuk menghapus semua instalasi skrip
function uninstall_semua_skrip() {
    echo "Memulai proses uninstall..."
    
    # Hapus konfigurasi Nginx
    rm -f /etc/nginx/sites-enabled/*
    rm -f /etc/nginx/sites-available/*

    # Hapus instalasi MariaDB
    apt-get purge -y mariadb-server

    # Hapus PHP 8.3
    apt-get purge -y nginx php8.3-fpm php8.3-mysql php8.3-curl php8.3-gd php8.3-mbstring php8.3-xml php8.3-xmlrpc php8.3-soap php8.3-intl php8.3-zip

    # Hapus WordPress
    rm -rf /var/www/html/*

    echo "Uninstall semua skrip telah selesai."
    
    kembali_ke_menu_utama
}

# Fungsi untuk menambahkan domain baru
function tambah_domain() {
    read -p "Masukkan nama domain baru (contoh: example.com): " NEW_DOMAIN
    read -p "Masukkan path dokumen root untuk domain baru (contoh: /var/www/html/newdomain): " DOC_ROOT

    # Buat file konfigurasi Nginx baru untuk domain
    NGINX_CONF="/etc/nginx/sites-available/$NEW_DOMAIN"
    NGINX_LINK="/etc/nginx/sites-enabled/$NEW_DOMAIN"

    cat <<EOL > $NGINX_CONF
server {
        listen 80;
        root $DOC_ROOT;
        index index.php index.html index.htm index.nginx-debian.html;
        server_name $NEW_DOMAIN www.$NEW_DOMAIN;

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
   DOC_ROOTT="/var/www/html/$NEW_DOMAIN"

# Konfigurasi MariaDB
mysql -u root -p"$MARIADB_ROOT_PASSWORD" <<EOF
CREATE DATABASE IF NOT EXISTS $NEW_DOMAIN DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON $NEW_DOMAIN.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
EOF

# Membuat direktori dokumen root
mkdir -p $DOC_ROOTT
chown -R www-data:www-data $DOC_ROOTT
chmod -R 755 $DOC_ROOTT

# Membuat file konfigurasi Nginx
cat <<EOL > $NGINX_CONF
server {
    listen 80;
    root $DOC_ROOTT;
    index index.php index.html index.htm index.nginx-debian.html;
    server_name $NEW_DOMAIN www.$NEW_DOMAIN;

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
cp -r /tmp/wordpress/* $DOC_ROOTT/
rm /tmp/latest.tar.gz

# Konfigurasi WordPress
cp $DOC_ROOTT/wp-config-sample.php $DOC_ROOTT/wp-config.php
sed -i "s/database_name_here/$NEW_DOMAIN/" $DOC_ROOTT/wp-config.php
sed -i "s/username_here/$DB_USER/" $DOC_ROOTT/wp-config.php
sed -i "s/password_here/$DB_PASS/" $DOC_ROOTT/wp-config.php

# Setel hak akses
chown -R www-data:www-data $DOC_ROOTT
chmod -R 755 $DOC_ROOTT

# Reload Nginx untuk menerapkan perubahan
nginx -t && systemctl reload nginx

    
    kembali_ke_menu_utama
}

# Fungsi untuk kembali ke menu utama
function kembali_ke_menu_utama() {
    read -p "Tekan Enter untuk kembali ke menu utama..."
    tampilkan_menu_utama
    pilih_menu
}

# Fungsi untuk instalasi Nginx
function install_nginx() {
    echo "Memulai instalasi Nginx..."
    apt-get install -y nginx

    # Konfigurasi Nginx
    # (konfigurasi Nginx di sini, sesuai dengan kebutuhan)

    echo "Instalasi Nginx selesai."
    install_nginx_php_mariadb
}

# Fungsi untuk instalasi PHP 8.3
function install_php() {
    echo "Memulai instalasi PHP 8.3..."
    add-apt-repository -y ppa:ondrej/php
    apt-get update
    apt-get install -y php8.3-fpm php8.3-mysql php8.3-curl php8.3-gd php8.3-mbstring php8.3-xml php8.3-xmlrpc php8.3-soap php8.3-intl php8.3-zip

    # Konfigurasi PHP 8.3
    # (konfigurasi PHP di sini, sesuai dengan kebutuhan)

    echo "Instalasi PHP 8.3 selesai."
    install_nginx_php_mariadb
}

# Fungsi untuk instalasi MariaDB
function install_mariadb() {
    echo "Memulai instalasi MariaDB..."
    apt-get install -y mariadb-server

    # Konfigurasi MariaDB
    # (konfigurasi MariaDB di sini, sesuai dengan kebutuhan)

    echo "Instalasi MariaDB selesai."
    install_nginx_php_mariadb
}

# Mulai script dengan menampilkan header dan menu utama
tampilkan_header
tampilkan_menu_utama
pilih_menu
