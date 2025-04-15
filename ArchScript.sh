#!/bin/bash

# Vérification des droits root
if [[ $EUID -ne 0 ]]; then
   echo "❌ Ce script doit être exécuté avec les privilèges root (sudo)" 
   exit 1
fi

echo "--------------------------------------------"
echo " 🚀 Installation serveur LAMP sur Arch Linux"
echo " Apache + MariaDB + PHP + phpMyAdmin"
echo "--------------------------------------------"

# Mise à jour
pacman -Syu --noconfirm

# Apache
echo "🧱 Installation d'Apache..."
pacman -S --noconfirm apache
systemctl enable httpd
systemctl start httpd

# MariaDB (MySQL compatible)
echo "🗃️  Installation de MariaDB..."
pacman -S --noconfirm mariadb
systemctl enable mariadb
systemctl start mariadb

# Initialisation de MariaDB
echo "🔐 Initialisation de MariaDB..."
mysql_install_db --user=mysql --basedir=/usr --datadir=/var/lib/mysql

# Sécurisation de MariaDB et configuration de l'utilisateur noelson
echo "🔐 Configuration de MariaDB..."
mysql_secure_installation

mysql -u root -p <<EOF
CREATE USER IF NOT EXISTS 'noelson'@'localhost' IDENTIFIED BY 'noelson';
GRANT ALL PRIVILEGES ON *.* TO 'noelson'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF

# PHP
echo "🧩 Installation de PHP et modules..."
pacman -S --noconfirm php php-apache php-mysqli php-gd php-mbstring php-zip php-json php-curl

# Configuration d'Apache pour PHP
echo "Configurons Apache pour PHP..."
echo "LoadModule php_module modules/libphp.so" >> /etc/httpd/conf/httpd.conf
echo "Include conf/extra/php_module.conf" >> /etc/httpd/conf/httpd.conf
echo "AddHandler php-script .php" >> /etc/httpd/conf/httpd.conf
echo "AddType text/html .php" >> /etc/httpd/conf/httpd.conf

# phpMyAdmin
echo "📦 Installation de phpMyAdmin..."
pacman -S --noconfirm phpmyadmin

# Lier phpMyAdmin à Apache
echo "Include /etc/phpmyadmin/apache.conf" >> /etc/httpd/conf/httpd.conf

# Redémarrage d’Apache
echo "🔁 Redémarrage du serveur Apache..."
systemctl restart httpd

# Page test PHP
echo "<?php phpinfo(); ?>" > /srv/http/info.php

echo "--------------------------------------------"
echo "✅ Installation terminée !"
echo "🌐 phpMyAdmin : http://localhost/phpmyadmin"
echo "👤 Utilisateur MySQL/MariaDB : noelson"
echo "🔑 Mot de passe : noelson"
echo "🧪 Test PHP : http://localhost/info.php"
echo "--------------------------------------------"
