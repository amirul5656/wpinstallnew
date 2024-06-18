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
    echo "1. Instalasi OpenSSH untuk WebSocket"
    echo "2. Instalasi V2Ray (VMESS)"
    echo "3. Instalasi V2Ray (VLESS)"
    echo "4. Instalasi WireGuard"
    echo "5. Buat Akun WireGuard"
    echo "6. Keluar"
    echo "-----------"
}

# Fungsi untuk instalasi OpenSSH untuk WebSocket
install_openssh() {
    echo "Memulai instalasi OpenSSH untuk WebSocket..."
    # Lakukan instalasi OpenSSH
    apt-get update
    apt-get install -y openssh-server

    # Konfigurasi OpenSSH untuk WebSocket
    # Isi konfigurasi sesuai dengan kebutuhan Anda
    echo "OpenSSH berhasil diinstal untuk WebSocket."
    read -n 1 -s -r -p "Tekan sembarang tombol untuk melanjutkan..."
}

# Fungsi untuk instalasi V2Ray (VMESS)
install_v2ray_vmess() {
    echo "Memulai instalasi V2Ray (VMESS)..."
    # Isi dengan langkah-langkah instalasi V2Ray VMESS
    bash <(curl -L -s https://install.direct/go.sh)
    
    # Konfigurasi V2Ray VMESS
    # Isi konfigurasi sesuai dengan kebutuhan Anda
    echo "V2Ray (VMESS) berhasil diinstal."
    read -n 1 -s -r -p "Tekan sembarang tombol untuk melanjutkan..."
}

# Fungsi untuk instalasi V2Ray (VLESS)
install_v2ray_vless() {
    echo "Memulai instalasi V2Ray (VLESS)..."
    # Isi dengan langkah-langkah instalasi V2Ray VLESS
    bash <(curl -L -s https://install.direct/go.sh)
    
    # Konfigurasi V2Ray VLESS
    # Isi konfigurasi sesuai dengan kebutuhan Anda
    echo "V2Ray (VLESS) berhasil diinstal."
    read -n 1 -s -r -p "Tekan sembarang tombol untuk melanjutkan..."
}

# Fungsi untuk instalasi WireGuard
install_wireguard() {
    echo "Memulai instalasi WireGuard..."
    # Isi dengan langkah-langkah instalasi WireGuard
    add-apt-repository -y ppa:wireguard/wireguard
    apt-get update
    apt-get install -y wireguard

    # Konfigurasi WireGuard
    # Isi konfigurasi sesuai dengan kebutuhan Anda
    echo "WireGuard berhasil diinstal."
    read -n 1 -s -r -p "Tekan sembarang tombol untuk melanjutkan..."
}

# Fungsi untuk membuat akun WireGuard
create_wireguard_account() {
    echo "Membuat akun WireGuard baru..."

    read -p "Masukkan nama pengguna untuk akun: " username
    if [ -z "$username" ]; then
        echo "Nama pengguna tidak boleh kosong!"
        return
    fi

    # Generate kunci privat dan publik untuk akun WireGuard
    wg genkey | tee privatekey | wg pubkey > publickey
    private_key=$(cat privatekey)
    public_key=$(cat publickey)

    # Buat file konfigurasi untuk akun pengguna
    mkdir -p /etc/wireguard/clients
    cat > "/etc/wireguard/clients/$username.conf" << EOF
    [Interface]
    PrivateKey = $private_key
    Address = 10.0.0.2/24
    DNS = 8.8.8.8

    [Peer]
    PublicKey = <server_public_key>
    Endpoint = <server_ip>:51820
    AllowedIPs = 0.0.0.0/0
    PersistentKeepalive = 25
    EOF

    echo ""
    echo "Akun WireGuard untuk $username berhasil dibuat."
    echo "Silakan unduh file konfigurasi dari /etc/wireguard/clients/$username.conf"
    echo "Catatan: Ganti <server_public_key> dan <server_ip> dengan informasi server WireGuard Anda."

    read -n 1 -s -r -p "Tekan sembarang tombol untuk melanjutkan..."
}

# Loop utama untuk menampilkan menu
while true
do
    show_header
    show_menu

    read -p "Pilih operasi [1-6]: " choice
    case $choice in
        1) install_openssh ;;
        2) install_v2ray_vmess ;;
        3) install_v2ray_vless ;;
        4) install_wireguard ;;
        5) create_wireguard_account ;;
        6) echo "Terima kasih. Sampai jumpa!" && break ;;
        *) echo "Pilihan tidak valid. Silakan coba lagi." ;;
    esac
done
