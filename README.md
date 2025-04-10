# 🚀 Script d'installation d'un serveur LAMP sous Linux (Kali)

Ce script bash permet d'installer automatiquement un **serveur LAMP** (Linux, Apache, MariaDB, PHP) sur une distribution basée sur Debian comme **Kali Linux**, incluant également **phpMyAdmin** pour l'administration de la base de données.

---

## 🧰 Contenu du script

Le script installe et configure automatiquement les composants suivants :

- **Apache2** : Serveur web
- **MariaDB** : Base de données compatible MySQL (utilisée car `mysql-server` est indisponible sous Kali)
- **PHP** : Langage serveur avec modules nécessaires
- **phpMyAdmin** : Interface web pour gérer la base de données

---

## 👤 Utilisateur base de données

Un **utilisateur administrateur non sécurisé** est créé automatiquement pour la base de données :

| Utilisateur | Mot de passe | Privilèges        |
|-------------|--------------|-------------------|
| `noelson`   | `noelson`    | Tous (GRANT ALL)  |

⚠️ **ATTENTION :** cet utilisateur a tous les privilèges sur toutes les bases de données **y compris la possibilité de créer d'autres utilisateurs**. Cette configuration est **non sécurisée** et **ne doit pas être utilisée en production**.

---

## 📌 Fonctionnalités du script

- Met à jour le système
- Installe Apache2 et le démarre
- Installe MariaDB, la sécurise légèrement
- Crée l’utilisateur `noelson` avec tous les droits
- Installe PHP avec ses modules les plus utilisés
- Installe phpMyAdmin et le configure automatiquement
- Crée une page `info.php` pour tester PHP

---

## 🧪 Accès après installation

- **Page test PHP** : [http://localhost/info.php](http://localhost/info.php)
- **phpMyAdmin** : [http://localhost/phpmyadmin](http://localhost/phpmyadmin)  
  ➤ Connexion avec : `noelson / noelson`

---

## ⚠️ Avertissement de sécurité

Ce script est destiné à **des environnements de test, de développement ou de formation**.  
**Ne jamais utiliser cette configuration en production** sans avoir :
- modifié les mots de passe par défaut
- restreint les droits d'accès
- appliqué une configuration sécurisée de MariaDB, Apache et PHP

---

## 📄 Exécution

```bash
chmod +x install_lamp.sh
sudo ./install_lamp.sh

