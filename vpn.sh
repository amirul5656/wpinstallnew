#!/bin/bash

# Fungsi untuk menampilkan header menu
show_header() {
    clear
    echo "==================================="
    echo "  AUTO INSTALL VPN SCRIPT FOR VPS  "
    echo "==================================="
    echo "Selamat datang di instalasi VPN!"
    echo "Silakan pilih opsi yang ingin Anda lakukan."
    echo "==================================="
}

# Fungsi untuk menampilkan menu utama
show_menu() {
    echo "Menu Utama:"
    echo "-----------"
    echo "1. Instalasi Trojan"
    echo "2. Instalasi V2Ray (VMess)"
    echo "3. Instalasi V2Ray (Vless)"
    echo "4. Konfigurasi Port 443 (Trojan, VMess, Vless)"
    echo "5. Buat Akun Trojan"
    echo "6. Buat Akun VMess"
    echo "7. Buat Akun Vless"
    echo "8. Keluar"
    echo "-----------"
}

# Fungsi untuk instalasi Trojan
install_trojan() {
    echo "Memulai instalasi Trojan..."
    # Install Trojan
    curl -O https://raw.githubusercontent.com/trojan-gfw/trojan/v1.16.0/scripts/install.sh
    chmod +x install.sh
    ./install.sh

    # Verifikasi instalasi Trojan
    if [ $? -eq 0 ]; then
        echo "Trojan berhasil diinstal."
    else
        echo "Gagal melakukan instalasi Trojan."
    fi
    read -n 1 -s -r -p "Tekan sembarang tombol untuk melanjutkan..."
}

# Fungsi untuk instalasi V2Ray (VMess)
install_v2ray_vmess() {
    echo "Memulai instalasi V2Ray (VMess)..."
    # Install V2Ray VMess
    bash <(curl -L -s https://install.direct/go.sh)

    # Verifikasi instalasi V2Ray VMess
    if [ $? -eq 0 ]; then
        echo "V2Ray (VMess) berhasil diinstal."
    else
        echo "Gagal melakukan instalasi V2Ray (VMess)."
    fi
    read -n 1 -s -r -p "Tekan sembarang tombol untuk melanjutkan..."
}

# Fungsi untuk instalasi V2Ray (Vless)
install_v2ray_vless() {
    echo "Memulai instalasi V2Ray (Vless)..."
    # Install V2Ray Vless
    bash <(curl -L -s https://install.direct/go.sh)

    # Verifikasi instalasi V2Ray Vless
    if [ $? -eq 0 ]; then
        echo "V2Ray (Vless) berhasil diinstal."
    else
        echo "Gagal melakukan instalasi V2Ray (Vless)."
    fi
    read -n 1 -s -r -p "Tekan sembarang tombol untuk melanjutkan..."
}

# Fungsi untuk konfigurasi port 443 (Trojan, VMess, Vless)
configure_port_443() {
    echo "Mengonfigurasi port 443 untuk Trojan, VMess, dan Vless..."

    # Konfigurasi Trojan
    sed -i 's/"local_port": 80/"local_port": 443/' /usr/local/etc/trojan/config.json

    # Konfigurasi V2Ray VMess
    sed -i 's/"port": 10086/"port": 443/' /etc/v2ray/config.json

    # Konfigurasi V2Ray Vless
    sed -i 's/"port": 10086/"port": 443/' /etc/v2ray/config.json

    echo "Konfigurasi port 443 berhasil."
    read -n 1 -s -r -p "Tekan sembarang tombol untuk melanjutkan..."
}

# Fungsi untuk membuat akun Trojan
create_trojan_account() {
    echo "Membuat akun Trojan baru..."

    read -p "Masukkan nama pengguna untuk akun: " username
    if [ -z "$username" ]; then
        echo "Nama pengguna tidak boleh kosong!"
        return
    fi

    read -p "Masukkan password untuk akun: " password
    if [ -z "$password" ]; then
        echo "Password tidak boleh kosong!"
        return
    fi

    # Buat file konfigurasi untuk akun pengguna
    echo "$password" > /usr/local/etc/trojan/$username.json

    echo ""
    echo "Akun Trojan untuk $username berhasil dibuat."
    echo "Informasi akun:"
    echo "Username: $username"
    echo "Password: $password"

    read -n 1 -s -r -p "Tekan sembarang tombol untuk melanjutkan..."
}

# Fungsi untuk membuat akun V2Ray VMess
create_v2ray_vmess_account() {
    echo "Membuat akun V2Ray VMess baru..."

    read -p "Masukkan ID pengguna untuk akun: " id
    if [ -z "$id" ]; then
        echo "ID pengguna tidak boleh kosong!"
        return
    fi

    # Generate UUID untuk akun pengguna
    uuid=$(cat /proc/sys/kernel/random/uuid)

    # Buat file konfigurasi untuk akun pengguna
    cat > "/etc/v2ray/clients/$id.json" <<EOF
{
  "id": "$uuid",
  "alterId": 64,
  "security": "auto"
}
EOF

    echo ""
    echo "Akun V2Ray VMess untuk ID $id berhasil dibuat."
    echo "Informasi akun:"
    echo "ID: $id"
    echo "UUID: $uuid"

    read -n 1 -s -r -p "Tekan sembarang tombol untuk melanjutkan..."
}

# Fungsi untuk membuat akun V2Ray Vless
create_v2ray_vless_account() {
    echo "Membuat akun V2Ray Vless baru..."

    read -p "Masukkan ID pengguna untuk akun: " id
    if [ -z "$id" ]; then
        echo "ID pengguna tidak boleh kosong!"
        return
    fi

    # Generate UUID untuk akun pengguna
    uuid=$(cat /proc/sys/kernel/random/uuid)

    # Buat file konfigurasi untuk akun pengguna
    cat > "/etc/v2ray/clients/$id.json" <<EOF
{
  "id": "$uuid",
  "flow": "xtls-rprx-origin",
  "encryption": "none"
}
EOF

    echo ""
    echo "Akun V2Ray Vless untuk ID $id berhasil dibuat."
    echo "Informasi akun:"
    echo "ID: $id"
    echo "UUID: $uuid"

    read -n 1 -s -r -p "Tekan sembarang tombol untuk melanjutkan..."
}

# Loop utama untuk menampilkan menu
while true
do
    show_header
    show_menu

    read -p "Pilih operasi [1-8]: " choice
    case $choice in
        1) install_trojan ;;
        2) install_v2ray_vmess ;;
        3) install_v2ray_vless ;;
        4) configure_port_443 ;;
        5) create_trojan_account ;;
        6) create_v2ray_vmess_account ;;
        7) create_v2ray_vless_account ;;
        8) echo "Terima kasih. Sampai jumpa!" && break ;;
        *) echo "Pilihan tidak valid. Silakan coba lagi." ;;
    esac
done
