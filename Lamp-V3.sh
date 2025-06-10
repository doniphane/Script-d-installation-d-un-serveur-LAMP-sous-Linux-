#!/bin/bash

# Vérification des droits root
if [[ $EUID -ne 0 ]]; then
   echo "❌ Ce script doit être exécuté avec les privilèges root (sudo)" 
   exit 1
fi

echo "--------------------------------------------"
echo "🚀 Installation d'un environnement complet pour développeur web sous Kali Linux"
echo " LAMP + Outils développeur (VSCode, Node.js, Git, Docker, Symfony, etc.)"
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
echo "🧩 Installation de PHP et modules requis pour Symfony..."
apt install php libapache2-mod-php php-mysql php-cli php-mbstring php-zip php-gd php-json php-curl php-xml php-bcmath php-intl php-xmlrpc php-soap php-ldap php-imap unzip -y

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

# Node.js & npm
echo "🟩 Installation de Node.js + npm..."
curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
apt install nodejs -y

# Yarn
echo "📦 Installation de Yarn..."
npm install -g yarn

# Installation des outils système supplémentaires
echo "🛠️  Installation de make, zip, unzip et curl..."
apt install make zip unzip curl -y

# Redis Server (optionnel mais utile pour Symfony)
echo "🔄 Installation de Redis Server (optionnel pour Symfony cache, sessions)..."
apt install redis-server -y
systemctl enable redis-server
systemctl start redis-server

# Postman
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

# Symfony CLI
echo "⚙️ Installation de Composer..."
EXPECTED_SIGNATURE="$(wget -q -O - https://composer.github.io/installer.sig)"
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
ACTUAL_SIGNATURE="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"
if [ "$EXPECTED_SIGNATURE" != "$ACTUAL_SIGNATURE" ]; then
    echo '❌ La signature de Composer est invalide.'
    rm composer-setup.php
    exit 1
fi
php composer-setup.php --install-dir=/usr/local/bin --filename=composer
rm composer-setup.php

echo "⚙️ Installation de Symfony CLI..."
wget https://get.symfony.com/cli/installer -O - | bash
mv /root/.symfony*/bin/symfony /usr/local/bin/symfony

# Ajout au .bashrc
echo "🔧 Configuration de l’environnement Symfony..."
BASHRC_PATH="/home/$SUDO_USER/.bashrc"
if ! grep -q "alias symfony=" "$BASHRC_PATH"; then
    echo "" >> "$BASHRC_PATH"
    echo "# Ajout alias Symfony CLI" >> "$BASHRC_PATH"
    echo "alias symfony='$(which symfony)'" >> "$BASHRC_PATH"
fi

# Mailhog (pour tester les emails en dev)
echo "📧 Installation de Mailhog (Docker)..."
docker pull mailhog/mailhog
docker run -d -p 8025:8025 -p 1025:1025 --name mailhog mailhog/mailhog
echo "📧 Mailhog est disponible sur : http://localhost:8025"
echo "👉 Configurez Symfony pour envoyer les mails à smtp://localhost:1025"

# VSCode Extensions
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
echo "📦 Logiciels installés : VSCode, Node.js, Git, Chrome, Discord, VLC, Docker, Postman, Symfony"
echo "🛠️  Outils système : make, zip, unzip, curl, redis-server"
echo "📧 Mailhog : http://localhost:8025"
echo "🔧 Symfony CLI configuré dans .bashrc (alias symfony)"
echo "🛠️  Tu peux maintenant développer en toute sérénité !"
echo "--------------------------------------------"

