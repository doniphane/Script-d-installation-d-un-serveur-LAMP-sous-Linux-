#!/bin/bash

# Vérification des droits root
if [[ $EUID -ne 0 ]]; then
   echo "❌ Ce script doit être exécuté avec les privilèges root (sudo)" 
   exit 1
fi

echo "--------------------------------------------"
echo " 🚀 Installation serveur LAMP sur Kali Linux"
echo " Apache + MariaDB + PHP + phpMyAdmin"
echo "--------------------------------------------"

# Mise à jour
apt update && apt upgrade -y

# Apache
echo "🧱 Installation d'Apache..."
apt install apache2 -y
systemctl enable apache2
systemctl start apache2

# MariaDB (MySQL compatible)
echo "🗃️  Installation de MariaDB..."
apt install mariadb-server mariadb-client -y
systemctl enable mariadb
systemctl start mariadb

# Sécurisation de MariaDB et configuration de l'utilisateur noelson
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
apt install php libapache2-mod-php php-mysql php-cli php-mbstring php-zip php-gd php-json php-curl -y

# phpMyAdmin
echo "📦 Installation de phpMyAdmin..."
# Pré-répondre aux questions de l'installation
echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/admin-user string root" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/admin-pass password root" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/app-pass password root" | debconf-set-selections
echo "phpmyadmin phpmyadmin/app-password-confirm password root" | debconf-set-selections

apt install phpmyadmin -y

# Lier phpMyAdmin à Apache si ce n’est pas automatique
if [ ! -e /etc/apache2/conf-enabled/phpmyadmin.conf ]; then
    ln -s /etc/phpmyadmin/apache.conf /etc/apache2/conf-enabled/phpmyadmin.conf
fi

# Redémarrage d’Apache
echo "🔁 Redémarrage du serveur Apache..."
systemctl restart apache2

# Page test PHP
echo "<?php phpinfo(); ?>" > /var/www/html/info.php

echo "--------------------------------------------"
echo "✅ Installation terminée !"
echo "🌐 phpMyAdmin : http://localhost/phpmyadmin"
echo "👤 Utilisateur MySQL/MariaDB : noelson"
echo "🔑 Mot de passe : noelson"
echo "🧪 Test PHP : http://localhost/info.php"
echo "--------------------------------------------"
