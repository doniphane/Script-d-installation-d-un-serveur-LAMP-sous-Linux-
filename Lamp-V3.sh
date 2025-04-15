#!/bin/bash

# Vérification des droits root
if [[ $EUID -ne 0 ]]; then
   echo "❌ Ce script doit être exécuté avec les privilèges root (sudo)" 
   exit 1
fi

echo "--------------------------------------------"
echo "🚀 Installation d'un environnement complet pour développeur web sous Kali Linux"
echo " LAMP + Outils développeur (VSCode, Node.js, Git, Docker, etc.)"
echo "--------------------------------------------"

# Mise à jour
apt update && apt upgrade -y

# Apache
echo "🧱 Installation d'Apache..."
apt install apache2 -y
systemctl enable apache2
systemctl start apache2

# MariaDB
echo "🗃️  Installation de MariaDB..."
apt install mariadb-server mariadb-client -y
systemctl enable mariadb
systemctl start mariadb

# Sécurisation de MariaDB
echo "🔐 Configuration de MariaDB..."
mysql -e "UPDATE mysql.user SET Password=PASSWORD('root') WHERE User='root';"
mysql -e "DELETE FROM mysql.user WHERE User='';"
mysql -e "DROP DATABASE IF EXISTS test;"
mysql -e "FLUSH PRIVILEGES;"

mysql -u root -proot <<EOF
CREATE USER IF NOT EXISTS 'noelson'@'localhost' IDENTIFIED BY 'noelson';
GRANT ALL PRIVILEGES ON *.* TO 'noelson'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF

# PHP
echo "🧩 Installation de PHP et modules..."
apt install php libapache2-mod-php php-mysql php-cli php-mbstring php-zip php-gd php-json php-curl php-xml php-bcmath -y

# phpMyAdmin
echo "📦 Installation de phpMyAdmin..."
echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/admin-user string root" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/admin-pass password root" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/app-pass password root" | debconf-set-selections
echo "phpmyadmin phpmyadmin/app-password-confirm password root" | debconf-set-selections

apt install phpmyadmin -y

if [ ! -e /etc/apache2/conf-enabled/phpmyadmin.conf ]; then
    ln -s /etc/phpmyadmin/apache.conf /etc/apache2/conf-enabled/phpmyadmin.conf
fi

systemctl restart apache2

# Page test PHP
echo "<?php phpinfo(); ?>" > /var/www/html/info.php

# Installation des outils développeur
echo "💻 Installation des outils de développement..."

mkdir -p /tmp/installers
cd /tmp/installers

# VSCode
echo "🔧 Installation de Visual Studio Code..."
wget -qO vscode.deb "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64"
apt install ./vscode.deb -y

# Google Chrome
echo "🌐 Installation de Google Chrome..."
wget -qO chrome.deb "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
apt install ./chrome.deb -y

# Discord
echo "🎧 Installation de Discord..."
wget -qO discord.deb "https://discord.com/api/download?platform=linux&format=deb"
apt install ./discord.deb -y

# VLC
echo "🎬 Installation de VLC..."
apt install vlc -y

# Git
echo "🗃️  Installation de Git..."
apt install git -y

# Node.js & npm (via NodeSource pour la dernière version LTS)
echo "🟩 Installation de Node.js + npm..."
curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
apt install nodejs -y

# Yarn
echo "📦 Installation de Yarn..."
npm install -g yarn

# Postman (via Snap si disponible, sinon AppImage)
echo "📨 Installation de Postman..."
if command -v snap &> /dev/null; then
    snap install postman
else
    wget https://dl.pstmn.io/download/latest/linux64 -O postman.tar.gz
    tar -xzf postman.tar.gz -C /opt
    ln -s /opt/Postman/Postman /usr/bin/postman
    echo "[Desktop Entry]
Name=Postman
Exec=/opt/Postman/Postman
Icon=/opt/Postman/app/resources/app/assets/icon.png
Type=Application
Categories=Development;" > /usr/share/applications/postman.desktop
fi

# Docker & Docker Compose
echo "🐳 Installation de Docker et Docker Compose..."
apt install ca-certificates curl gnupg lsb-release -y
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt update
apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

usermod -aG docker $SUDO_USER

# Terminal Gnome (si environnement graphique léger)
echo "🖥️ Installation de Gnome Terminal (optionnel)..."
apt install gnome-terminal -y

# Extensions VSCode (utilise code CLI)
echo "🧩 Installation d’extensions VSCode..."
code --install-extension ms-vscode.vscode-typescript-next
code --install-extension esbenp.prettier-vscode
code --install-extension dbaeumer.vscode-eslint
code --install-extension eamodio.gitlens
code --install-extension formulahendry.auto-close-tag
code --install-extension ms-azuretools.vscode-docker

# Nettoyage
cd ~
rm -rf /tmp/installers

echo "--------------------------------------------"
echo "✅ Installation complète terminée !"
echo "🌐 phpMyAdmin : http://localhost/phpmyadmin"
echo "🧪 Test PHP : http://localhost/info.php"
echo "📦 Logiciels installés : VSCode, Node.js, Git, Chrome, Discord, VLC, Docker, Postman"
echo "🔧 Extensions VSCode installées : TypeScript, Prettier, ESLint, GitLens, Docker, etc."
echo "🛠️  Tu peux maintenant commencer à coder comme un.e pro !"
echo "--------------------------------------------"
