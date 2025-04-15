#!/bin/bash

# Vérification des droits root
if [[ $EUID -ne 0 ]]; then
    echo "❌ Ce script doit être exécuté avec les privilèges root (sudo)"
    exit 1
fi

echo "--------------------------------------------"
echo "🚀 Installation d'un environnement complet pour développeur web sur Fedora"
echo " LAMP + outils de développement (VSCode, Node.js, Docker, etc.)"
echo "--------------------------------------------"

# Mise à jour
dnf upgrade -y

# Apache (httpd)
echo "🧱 Installation d'Apache..."
dnf install httpd -y
systemctl enable httpd
systemctl start httpd

# MariaDB
echo "🗃️  Installation de MariaDB..."
dnf install mariadb-server mariadb -y
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
echo "🧩 Installation de PHP et extensions..."
dnf install php php-mysqlnd php-cli php-common php-gd php-mbstring php-xml php-pdo php-curl php-bcmath -y
systemctl restart httpd

# phpMyAdmin
echo "📦 Installation de phpMyAdmin..."
dnf install phpMyAdmin -y

# Activer phpMyAdmin (accessible localement)
echo "➡️ Configuration de phpMyAdmin pour Apache..."
cp /etc/httpd/conf.d/phpMyAdmin.conf /etc/httpd/conf.d/phpMyAdmin.conf.bak
sed -i 's/Require ip 127.0.0.1/Require all granted/' /etc/httpd/conf.d/phpMyAdmin.conf
sed -i 's/Require ip ::1/Require all granted/' /etc/httpd/conf.d/phpMyAdmin.conf
systemctl restart httpd

# Page test PHP
echo "<?php phpinfo(); ?>" > /var/www/html/info.php

# Développement web : outils supplémentaires
echo "💻 Installation des outils de développement..."

# Git
dnf install git -y

# Node.js (LTS) + npm
echo "🟩 Installation de Node.js + npm..."
dnf module install nodejs:18/common -y

# Yarn
npm install -g yarn

# Docker
echo "🐳 Installation de Docker..."
dnf install dnf-plugins-core -y
dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

systemctl enable docker
systemctl start docker
usermod -aG docker $SUDO_USER

# Postman (via Flatpak)
echo "📨 Installation de Postman..."
flatpak install -y flathub com.getpostman.Postman

# VLC
dnf install vlc -y

# VSCode
echo "🔧 Installation de Visual Studio Code..."
rpm --import https://packages.microsoft.com/keys/microsoft.asc
sh -c 'echo -e "[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'

dnf check-update
dnf install code -y

# Google Chrome
echo "🌐 Installation de Google Chrome..."
dnf install fedora-workstation-repositories -y
dnf config-manager --set-enabled google-chrome
dnf install google-chrome-stable -y

# Discord
echo "🎧 Installation de Discord..."
dnf install https://rpm.findmysoft.com/fedora/discord.rpm -y || flatpak install -y flathub com.discordapp.Discord

# VSCode Extensions (si code CLI est dispo)
echo "🧩 Installation des extensions VSCode..."
if command -v code &> /dev/null; then
    code --install-extension ms-vscode.vscode-typescript-next
    code --install-extension esbenp.prettier-vscode
    code --install-extension dbaeumer.vscode-eslint
    code --install-extension eamodio.gitlens
    code --install-extension formulahendry.auto-close-tag
    code --install-extension ms-azuretools.vscode-docker
fi

echo "--------------------------------------------"
echo "✅ Installation terminée !"
echo "🌐 phpMyAdmin : http://localhost/phpmyadmin"
echo "🧪 Test PHP : http://localhost/info.php"
echo "📦 Logiciels : Git, Node.js, Docker, VSCode, Chrome, Discord, VLC, Postman"
echo "🧠 Extensions VSCode : TypeScript, ESLint, GitLens, Docker, etc."
echo "🔁 Redémarre ta session pour activer Docker sans sudo."
echo "--------------------------------------------"
